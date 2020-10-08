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
    let planeNormal = normalize(-direction)
    let up = v3d(0, 1, 0)

    // calculate horizontal & vertical focal plane vectors
    let u = normalize(cross(up, planeNormal))
    let v = cross(planeNormal, u)

    return (u,v)
}

func raytracePixels(ul : v3d,
                    u : v3d,
                    v : v3d,
                    camera : v3d,
                    startX : Double,
                    startY : Double,
                    endX : Double,
                    endY : Double,
                    imageWidth : Int,
                    imageHeight : Int,
                    lights : [PointLight],
                    objects : [RayIntersectable],
                    outputBitmap : inout [UInt8],
                    pixelDone : (() -> Void)?) {
    func pixLocation(_ i : Double, _ j : Double) -> v3d {
        let horizOffset = u * i
        let vertOffset = v * j
        return ul + horizOffset - vertOffset
    }

    let uDirectionStep = (endX - startX) / Double(imageWidth)
    let vDirectionStep = (endY - startY) / Double(imageHeight)

    let rowBytesToSkip = imageWidth * 4
    let subdivision : Double = 0.25
    for i in stride(from: startX, to: endX, by: uDirectionStep) {
        let horizontalOffset = i * 4
        for j in stride(from: startY, to: endY, by: vDirectionStep) {
            var pixelValues : [Double] = []
            let firstByte = 0//rowBytesToSkip * j + horizontalOffset

            for x in stride(from: Double(i), to: Double(i+uDirectionStep), by: subdivision) {
                for y in stride(from: Double(j), to: Double(j+vDirectionStep), by: subdivision) {

                    let cameraToPixelVector = pixLocation(x, y) - camera
                    let c2punit = normalize(cameraToPixelVector)
                    var intersections : [Intersection] = []

                    traceRay(origin: camera, direction: c2punit, objects: objects, intersections: &intersections)

                    guard !intersections.isEmpty else {
                        pixelValues.append(0)
                        continue
                    }

                    var i1 = intersections[0]

                    if i1.object.isBounding {
                        let boundedShapes = i1.object.getBoundedIntersectables()
                        var boundedShapeIntersections : [Intersection] = []
                        traceRay(origin: camera, direction: c2punit, objects: boundedShapes, intersections: &boundedShapeIntersections)
                        guard !boundedShapeIntersections.isEmpty else {
                            pixelValues.append(0)
                            continue
                        }
                        i1 = boundedShapeIntersections[0]
                    }

                    let intensityMultiplier = calculateLighting(atIntersection: i1,
                                                                fromLights: lights,
                                                                worldObjects: objects)

                    pixelValues.append(255 * intensityMultiplier)
                }
            }
            var pixelValueSum : Double = pixelValues.reduce(0, +)

            pixelValueSum = pixelValueSum / Double(pixelValues.count)
            let avg : UInt8 = UInt8(pixelValueSum)
            outputBitmap[firstByte] = avg
            outputBitmap[firstByte + 1] = avg
            outputBitmap[firstByte + 2] = avg
            outputBitmap[firstByte + 3] = 255
            pixelDone?()
        }
    }
}

func getBounds(_ objects : [RayIntersectable]) -> [ BoundsDictKey : Double ] {
    var minX, maxX, minY, maxY, minZ, maxZ : Double
    minX = Double.infinity
    minY = Double.infinity
    minZ = Double.infinity
    maxX = -Double.infinity
    maxY = -Double.infinity
    maxZ = -Double.infinity

    for o in objects {
        let boundsDict = o.getBounds()
        setOnCondition(A: &minX, toB: boundsDict[.MINX]!, ifTrue: >)
        setOnCondition(A: &minY, toB: boundsDict[.MINY]!, ifTrue: >)
        setOnCondition(A: &minZ, toB: boundsDict[.MINZ]!, ifTrue: >)
        setOnCondition(A: &maxX, toB: boundsDict[.MAXX]!, ifTrue: <)
        setOnCondition(A: &maxY, toB: boundsDict[.MAXY]!, ifTrue: <)
        setOnCondition(A: &maxZ, toB: boundsDict[.MAXZ]!, ifTrue: <)
    }
    
    return [
        .MINX : minX,
        .MAXX : maxX,
        .MINY : minY,
        .MAXY : maxY,
        .MINZ : minZ,
        .MAXZ : maxZ
    ]
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
    let (u, v) : (v3d, v3d) = getPlaneVectors(origin: camera, direction: cameraDirection, focalLength: focalLength)
    let worldBounds = getBounds(objects)
    print(worldBounds)
    print(imageCenterCoordinate)
    let worldHorizontalRange = 500
    let worldVerticalRange = 500
    let hpc = u * (Double(worldHorizontalRange) / 2.0)
    let vpc = v * (Double(worldVerticalRange) / 2.0)

    let ul : v3d = imageCenterCoordinate - hpc + vpc


//    raytracePixels(ul: ul, u: u, v: v, camera: camera, startX: 0, startY: 0, endX: imageWidth, endY: imageHeight, lights: lights, objects: objects, outputBitmap: &outputBitmap, pixelDone: pixelDone)
}

func calculateLighting(atIntersection isect : Intersection,
                       fromLights lights: [PointLight],
                       worldObjects objects : [RayIntersectable]) -> Double {
    guard let normal = isect.normal else {
        return 0.0
    }

    let point = isect.point
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

        if !objLightIntersections.filter({ (i : Intersection) in
            !i.object.isBounding
        }).isEmpty {
            continue
        }

        intensityMultiplier += intensity

        if intensityMultiplier >= 1.0 {
            intensityMultiplier = 1.0
            break
        }
    }
    return intensityMultiplier
}
