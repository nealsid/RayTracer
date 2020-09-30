//
//  RayTracingFunctions.swift
//  RayTraceUI
//
//  Created by Neal Sidhwaney on 9/16/20.
//  Copyright © 2020 Neal Sidhwaney. All rights reserved.
//

import Foundation
import simd

typealias v3 = SIMD3
typealias v3d = v3<Double>

struct Intersection {
    let point : v3d
    let normal : v3d?
    let parameter : Double
    let object : RayIntersectable

    init(atPoint : v3d, parameter: Double, object: RayIntersectable) {
        self.init(atPoint: atPoint,
                  withNormal: nil,
                  parameter: parameter,
                  object: object)
    }

    init(atPoint : v3d, withNormal: v3d?, parameter: Double, object: RayIntersectable) {
        self.point = atPoint
        self.normal = withNormal
        self.parameter = parameter
        self.object = object
    }
}

func traceRay(origin: v3d,
              direction: v3d,
              objects: [RayIntersectable],
              intersections : inout [Intersection]) {
    for o in objects {
        o.intersections(origin: origin, direction: direction, intersections: &intersections)
    }
}

func getPlaneVectors(origin : v3d,
                     direction : v3d,
                     focalLength : Double) -> (v3d, v3d) {
    let planeNormal = simd_normalize(-direction)
    let up = v3d(0, 1, 0)

    // calculate horizontal & vertical focal plane vectors
    let u = simd_normalize(simd_cross(up, planeNormal))
    let v = simd_cross(planeNormal, u)

    return (u,v)
}

func raytraceWorld(camera : v3d,
                   cameraDirection : v3d,
                   focalLength : Double,
                   imageWidth : Int,
                   imageHeight : Int,
                   lights : [PointLight],
                   objects : [RayIntersectable],
                   outputBitmap : inout [UInt8]) {
    let imageCenterCoordinate = camera + focalLength * cameraDirection

    let (u, v) : (v3d, v3d) = getPlaneVectors(origin: camera, direction: cameraDirection, focalLength: focalLength)

    let hpc = u * (Double(imageWidth) / 2.0)
    let vpc = v * (Double(imageHeight) / 2.0)

    let ul : v3d = imageCenterCoordinate - hpc + vpc

    func pixLocation(_ i : Double, _ j : Double) -> v3d {
        let horizOffset = u * i
        let vertOffset = v * j
        return ul + horizOffset - vertOffset
    }
    
    let columnMultiplier = imageWidth * 4
    let subdivision : Double = 0.25

    for i in 0..<imageWidth {
        let rowOffset = i * 4
        for j in 0..<imageHeight {
            let firstByte = j * columnMultiplier + rowOffset
            var pixelValues : [Double] = []

            for x in stride(from: Double(i), to: Double(i+1), by: subdivision) {
                for y in stride(from: Double(j), to: Double(j+1), by: subdivision) {

                    let cameraToPixelVector = pixLocation(x, y) - camera
                    let c2punit = simd_normalize(cameraToPixelVector)
                    var intersections : [Intersection] = []
                    traceRay(origin: camera, direction: c2punit, objects: objects, intersections: &intersections)

                    guard !intersections.isEmpty else {
                        pixelValues.append(0)
                        continue
                    }

                    intersections.sort() { $0.parameter <= $1.parameter }

                    // Take closest intersection
                    let i1 = intersections[0]

                    guard let normalAtIntersection = i1.normal else {
                        continue
                    }

                    let intensityMultiplier = calculateLighting(atPoint: i1.point, fromLights: lights, withNormal: normalAtIntersection, worldObjects: objects)

                    pixelValues.append(255 * intensityMultiplier)
                }
            }
            var averageValue : Double = pixelValues.reduce(0, +)

            averageValue = averageValue / Double(pixelValues.count)
            let avg : UInt8 = UInt8(averageValue)
            outputBitmap[firstByte] = avg
            outputBitmap[firstByte + 1] = avg
            outputBitmap[firstByte + 2] = avg
            outputBitmap[firstByte + 3] = 255
        }
    }
}

func calculateLighting(atPoint point : v3d,
                       fromLights lights : [PointLight],
                       withNormal normal : v3d,
                       worldObjects objects : [RayIntersectable]) -> Double {
    var intensityMultiplier : Double = 0.0

    for l in lights {
        let i1ToPl = l.location - point
        let pl = simd_normalize(i1ToPl)
        let intensity = simd_dot(pl, normal)

        if intensity <= 0 {
            continue
        }

        // Now trace another ray to find objects in between current point and light.
        var objLightIntersections : [Intersection] = []
        traceRay(origin: point, direction: pl, objects: objects, intersections: &objLightIntersections)
        if objLightIntersections.count > 0 {
            print("point->light intersection parameter: \(objLightIntersections[0].parameter)")
            continue
        }
        if intensity > 0 {
            intensityMultiplier += intensity
            if intensityMultiplier >= 1.0 {
                intensityMultiplier = 1.0
                break
            }
        }
    }
    return intensityMultiplier
}
