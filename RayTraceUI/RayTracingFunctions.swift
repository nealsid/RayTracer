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
    let up = v3d(0, 1, 0)

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
                pixelValues.append(CGColor.zero())
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
                                                        worldObjects: objects)

            pixelValues.append(255 * intensityMultiplier)
        }

//        let pixelValueSum : Double = pixelValues.reduce(0, +) / Double(pixelValues.count)
        let pixelValueSum : CGColor = pixelValues.reduce(CGColor(red: 0, green: 0, blue: 0, alpha: 1.0), +)

        let horizontalOffset = w.xPixel * 4
        let firstByte = bytesPerRow * w.yPixel + horizontalOffset
        outputBitmap[firstByte] = UInt8(pixelValueSum.components![0] * 255)
        outputBitmap[firstByte + 1] = UInt8(pixelValueSum.components![1] * 255)
        outputBitmap[firstByte + 2] = UInt8(pixelValueSum.components![2] * 255)
        outputBitmap[firstByte + 3] = UInt8(pixelValueSum.components![3] * 255)
        print("""
            \(w.xPixel)/\(w.yPixel): r: \(outputBitmap[firstByte]), b: \(outputBitmap[firstByte + 1]), \
                g: \(outputBitmap[firstByte + 2]), a: \(outputBitmap[firstByte + 3])
            """)
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

extension CGColor {

    func mapComponents(_ a : CGFloat.NativeType, op: ((_ a : CGFloat.NativeType, _ b : CGFloat.NativeType) -> CGFloat.NativeType)) -> CGColor {
        let newComponents : [CGFloat] = self.components!.map() { CGFloat(op(a, CGFloat.NativeType($0))) }
        return newComponents.withUnsafeBytes() {
            CGColor(colorSpace: self.colorSpace!, components: $0.baseAddress!.bindMemory(to: CGFloat.self, capacity: newComponents.count))!
        }
    }

    static func *(left : CGFloat.NativeType, right : CGColor) -> CGColor {
        return right.mapComponents(left, op: *)
    }

    static func +(left : CGFloat.NativeType, right : CGColor) -> CGColor {
        return right.mapComponents(left, op: +)
    }

    static func +(left: CGColor, right: CGColor) -> CGColor {
        return zip(left.components!, right.components!).map(+).withUnsafeBytes {
            CGColor(colorSpace: left.colorSpace!, components: $0.baseAddress!.bindMemory(to: CGFloat.self, capacity: left.components!.count))!
        }
    }
    static func /(left : CGColor, right : CGFloat.NativeType) -> CGColor {
        return left.mapComponents(right, op: /)
    }

    static func zero() -> CGColor {
        return CGColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    }
}

extension Array {
    func countMatching(pred : ((_ el : Element) -> Bool)) -> Int {
        var match : Int = 0
        self.forEach() {
            if pred($0) {
                match += 1
            }
        }
        return match
    }
}

func raytraceWorld(camera : v3d,
                   cameraDirection : v3d,
                   focalLength : Double,
                   imageWidthPixels : Int,
                   imageHeightPixels : Int,
                   ambientLight: CGColor,
                   lights : [PointLight],
                   objects : [RayIntersectable],
                   outputBitmap : inout [UInt8],
                   pixelDone :  (() -> Void)?) {
    let imageCenterCoordinate = camera + focalLength * cameraDirection
    let (u, v) : (v3d, v3d) = getPlaneVectors(origin: camera,
                                              direction: cameraDirection,
                                              focalLength: focalLength)
    let worldBounds = getBounds(objects)
    print(worldBounds)
    print(imageCenterCoordinate)

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
                   outputBitmap: &outputBitmap,
                   pixelDone: pixelDone)
}

func calculateLighting(atIntersection isect : Intersection,
                       ambientLight: CGColor,
                       fromLights lights: [PointLight],
                       worldObjects objects : [RayIntersectable]) -> CGColor {
    var intensityMultiplier : CGColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    // if there's no normal, skip lighting calculations.
    guard let normal = isect.normal else {
        // TODO make this the ambient light instead of 0
        return intensityMultiplier
    }

    let surfacePoint = isect.point
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

        //
        intensityMultiplier = intensityMultiplier + (light.k_d * intensityMultiplier)

    }
    return intensityMultiplier
}
