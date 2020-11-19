//
//  RayTracingFunctions.swift
//  RayTraceUI
//
//  Created by Neal Sidhwaney on 9/16/20.
//  Copyright © 2020 Neal Sidhwaney. All rights reserved.
//

import Foundation
import simd
import CoreGraphics

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
    let up = normalize(v3d(0, 1, -1))

    // calculate horizontal & vertical focal plane vectors
    let u = normalize(cross(up, planeNormal))
    let v = cross(planeNormal, u)

    return (u,v)
}

func raytracePixels(worldCoordinates : WorldCoordinateSequence,
                    camera : v3d,
                    ambientLighting: CGColor,
                    lights : [PointLight],
                    objects : [RayIntersectable],
                    materialDictionary : [String : Material],
                    outputBitmap : inout [UInt8],
                    pixelDone : (() -> Void)?) {
    let bytesPerRow = (worldCoordinates.endXPixel - worldCoordinates.startXPixel + 1) * 4

    for w in worldCoordinates {
        var pixelValues : [CGColor] = []

        for focalPlanePoint in w.p {
            let c2punit = normalize(focalPlanePoint - camera)
            var intersections : [Intersection] = []

            traceRay(origin: camera, direction: c2punit, objects: objects, intersections: &intersections)

            guard !intersections.isEmpty else {
                pixelValues.append(CGColor.black)
                continue
            }
            
            var i1 = intersections[0]

            if i1.object.isBounding {
                let boundedShapes = i1.object.getBoundedIntersectables()
                var boundedShapeIntersections : [Intersection] = []
                traceRay(origin: camera, direction: c2punit, objects: boundedShapes, intersections: &boundedShapeIntersections)
                guard !boundedShapeIntersections.isEmpty else {
                    pixelValues.append(CGColor.zero())
                    continue
                }
                i1 = boundedShapeIntersections[0]
            }

            let intensityMultiplier = calculateLighting(atIntersection: i1,
                                                        ambientLight: ambientLighting,
                                                        fromLights: lights,
                                                        worldObjects: objects,
                                                        materialDictionary: materialDictionary)

            pixelValues.append(intensityMultiplier)
        }

        var pixelValueSum : CGColor = pixelValues.reduce(CGColor.rgb([0, 0, 0, 1.0]), +)
        pixelValueSum = pixelValueSum / CGFloat.NativeType(pixelValues.count)
        let horizontalOffset = w.xPixel * 4
        let firstByte = bytesPerRow * w.yPixel + horizontalOffset
        outputBitmap[firstByte] = UInt8(255 * pixelValueSum.components![0])
        outputBitmap[firstByte + 1] = UInt8(255 * pixelValueSum.components![1])
        outputBitmap[firstByte + 2] = UInt8(255 * pixelValueSum.components![2])
        outputBitmap[firstByte + 3] = UInt8(255 * (pixelValueSum.components?[3] ?? 1.0))
        pixelDone?()
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
                   imageWidthPixels : Int,
                   imageHeightPixels : Int,
                   ambientLight: CGColor,
                   lights : [PointLight],
                   objects : [RayIntersectable],
                   materialDictionary : [String : Material],
                   outputBitmap : inout [UInt8],
                   pixelDone :  (() -> Void)?) {
    let imageCenterCoordinate = camera + focalLength * cameraDirection
    let (u, v) : (v3d, v3d) = getPlaneVectors(origin: camera,
                                              direction: cameraDirection,
                                              focalLength: focalLength)
    let worldHorizontalRange = 10.0
    let worldVerticalRange = 10.0
    let hpc = u * (Double(worldHorizontalRange) / 2.0)
    let vpc = v * (Double(worldVerticalRange) / 2.0)

    let ul : v3d = imageCenterCoordinate - hpc + vpc
    let ur : v3d = imageCenterCoordinate + hpc + vpc
    let ll : v3d = imageCenterCoordinate - hpc - vpc
    let lr : v3d = imageCenterCoordinate + hpc - vpc

    let w = WorldCoordinateSequence(ul: ul, ur: ur, ll: ll, lr: lr, u: u, v: v, startXPixel: 0, startYPixel: 0, endXPixel: imageWidth - 1, endYPixel: imageHeight - 1, pixelSubdivision: 1)

    raytracePixels(worldCoordinates: w,
                   camera: camera,
                   ambientLighting: ambientLight,
                   lights: lights,
                   objects: objects,
                   materialDictionary: materialDictionary,
                   outputBitmap: &outputBitmap,
                   pixelDone: pixelDone)
}

func calculateLighting(atIntersection isect : Intersection,
                       ambientLight : CGColor,
                       fromLights lights: [PointLight],
                       worldObjects objects : [RayIntersectable],
                       materialDictionary : [String : Material]) -> CGColor {

    let surfacePoint = isect.point
    let m = materialDictionary[isect.object.materialName]!

    var intensityMultiplier : CGColor = CGColor(red: (ambientLight.components?[0])! * CGFloat(m.ka.x),
                                                green: (ambientLight.components?[1])! * CGFloat(m.ka.y),
                                                blue: (ambientLight.components?[2])! * CGFloat(m.ka.z),
                                                alpha: ambientLight.alpha)
    // if there's no normal, skip lighting calculations.

    guard let normal = isect.normal else {
        // TODO make this the ambient light instead of 0
        return intensityMultiplier
    }

    for light in lights {
        let pointToLightUnit = normalize(light.location - surfacePoint)
        // if the face normal points away from light, continue to next light source.
        let normalLightVectorDp = dp(pointToLightUnit, normal)
        if normalLightVectorDp <= 0 {
            continue
        }

        // Now trace another ray to find objects in between current point and light.
        var objLightIntersections : [Intersection] = []
        traceRay(origin: surfacePoint, direction: pointToLightUnit, objects: objects, intersections: &objLightIntersections)

        // If the list of nonbounding shapes is non-empty, light does not reach
        // this point from this light source, so continue to the next one.
        // TODO seems like I'm forgetting to intersect with shapes inside the bounding shape.
        if objLightIntersections.countMatching(pred: { !$0.object.isBounding }) > 0 {
            continue
        }
        intensityMultiplier = (normalLightVectorDp * light.k_a) + intensityMultiplier

    }
    return intensityMultiplier
}
