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

func dp<T : FloatingPoint>(_ a : v3<T>, _ b : v3<T>) -> T {
    return a.x * b.x + a.y * b.y + a.z * b.z
}

func normalize<T : FloatingPoint>(_ a : v3<T>) -> v3<T> {
    let length = sqrt(dp(a, a))
    return v3<T>(a.x / length, a.y / length, a.z / length)
}

func cross<T : FloatingPoint>(_ a: v3<T>, _ b : v3<T>) -> v3<T> {
    return v3<T>(a.y * b.z - a.z * b.y,
                 a.z * b.x - a.x * b.z,
                 a.x * b.y - a.y * b.x)
}

func lenSquared<T : FloatingPoint>(_ a : v3<T>) -> T {
    return a.x * a.x + a.y * a.y + a.z * a.z
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
    let planeNormal = normalize(-direction)
    let up = v3d(0, 1, 0)

    // calculate horizontal & vertical focal plane vectors
    let u = normalize(cross(up, planeNormal))
    let v = cross(planeNormal, u)

    return (u,v)
}

func raytraceWorld(camera : v3d,
                   cameraDirection : v3d,
                   focalLength : Double,
                   imageWidth : Int,
                   imageHeight : Int,
                   lights : [PointLight],
                   objects : [RayIntersectable],
                   outputBitmap : inout [UInt8],
                   pixelDone :  (() -> Void)?) {
    let imageCenterCoordinate = camera + focalLength * cameraDirection
    var output = outputBitmap

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
    let group = DispatchGroup()
    for i in 0..<imageWidth {
        let rowOffset = i * 4
        for j in 0..<imageHeight {
            let firstByte = j * columnMultiplier + rowOffset
//            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async(group: group) {
                var pixelValues : [Double] = []
                for x in stride(from: Double(i), to: Double(i+1), by: subdivision) {
                    for y in stride(from: Double(j), to: Double(j+1), by: subdivision) {

                        let cameraToPixelVector = pixLocation(x, y) - camera
                        let c2punit = normalize(cameraToPixelVector)
                        var intersections : [Intersection] = []
                        traceRay(origin: camera, direction: c2punit, objects: objects, intersections: &intersections)

                        guard !intersections.isEmpty else {
                            pixelValues.append(0)
                            continue
                        }

//                        intersections.sort() { $0.parameter <= $1.parameter }

                        // Take closest intersection
                        let i1 = intersections[0]

                        guard let normalAtIntersection = i1.normal else {
                            continue
                        }

                        let intensityMultiplier = calculateLighting(atPoint: i1.point, fromLights: lights, withNormal: normalAtIntersection, worldObjects: objects)

                        pixelValues.append(255 * intensityMultiplier)
                    }
                }
                var pixelValueSum : Double = pixelValues.reduce(0, +)

                pixelValueSum = pixelValueSum / Double(pixelValues.count)
                let avg : UInt8 = UInt8(pixelValueSum)
                output[firstByte] = avg
                output[firstByte + 1] = avg
                output[firstByte + 2] = avg
                output[firstByte + 3] = 255
                pixelDone?()
            }
        }
//    }
//    group.wait()
    outputBitmap = output
}

func calculateLighting(atPoint point : v3d,
                       fromLights lights : [PointLight],
                       withNormal normal : v3d,
                       worldObjects objects : [RayIntersectable]) -> Double {
    var intensityMultiplier : Double = 0.0

    for l in lights {
        let i1ToPl = l.location - point
        let pl = normalize(i1ToPl)
        let intensity = dp(pl, normal)

        if intensity <= 0 {
            continue
        }

        // Now trace another ray to find objects in between current point and light.
        var objLightIntersections : [Intersection] = []
        traceRay(origin: point, direction: pl, objects: objects, intersections: &objLightIntersections)
        if objLightIntersections.count > 0 {
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
