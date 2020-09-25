//
//  RayTracingFunctions.swift
//  RayTraceUI
//
//  Created by Neal Sidhwaney on 9/16/20.
//  Copyright © 2020 Neal Sidhwaney. All rights reserved.
//

import Foundation
import simd

struct Intersection {
    let point : simd_double3
    let normal : simd_double3?
    let parameter : Double
    let object : Renderable

    init(atPoint : simd_double3, parameter: Double, object: Renderable) {
        self.point = atPoint
        self.normal = nil
        self.parameter = parameter
        self.object = object
    }

    init(atPoint : simd_double3, withNormal: simd_double3?, parameter: Double, object: Renderable) {
        self.point = atPoint
        self.normal = withNormal
        self.parameter = parameter
        self.object = object
    }
}

func traceRay(origin: simd_double3,
              direction: simd_double3,
              objects: [Renderable],
              intersections : inout [Intersection]) {
    for o in objects {
        o.intersections(origin: origin, direction: direction, intersections: &intersections)
    }
}

func raytraceWorld(camera : simd_double3,
                   cameraDirection : simd_double3,
                   focalLength : Double,
                   imageWidth : Int,
                   imageHeight : Int,
                   lights : [Renderable],
                   objects : [Renderable],
                   outputBitmap : inout [UInt8]) {
    let ambientLight : UInt8 = 100
    let imageCenterCoordinate = camera + focalLength * cameraDirection
    let planeNormal = simd_normalize(-cameraDirection)
    let cameraUp = simd_double3(0, 1, 0)

    // calculate horizontal & vertical focal plane vectors
    let u = simd_normalize(simd_cross(cameraUp, planeNormal))
    let v = simd_cross(planeNormal, u)

    let hpc = u * (Double(imageWidth) / 2.0)
    let vpc = v * (Double(imageHeight) / 2.0)

    let ul : simd_double3 = imageCenterCoordinate - hpc + vpc

    func pixLocation(_ i : Int, _ j : Int) -> simd_double3 {
        let horizOffset = u * Double(i)
        let vertOffset = v * Double(j)
        return ul + horizOffset - vertOffset
    }
    
    let columnMultiplier = imageWidth * 4

    for i in 0..<imageWidth {
        let rowOffset = i * 4
        for j in 0..<imageHeight {
            let cameraToPixelVector = pixLocation(i, j) - camera
            let c2punit = simd_normalize(cameraToPixelVector)

            let firstByte = j * columnMultiplier + rowOffset
            var intersections : [Intersection] = []
            for o in objects {
                o.intersections(origin: camera, direction: c2punit, intersections: &intersections)
            }

            if intersections.isEmpty {
                outputBitmap[firstByte] = 0
                outputBitmap[firstByte + 1] = 0
                outputBitmap[firstByte + 2] = 0
                outputBitmap[firstByte + 3] = 255
                continue
            }

            intersections.sort() { $0.parameter <= $1.parameter }

            // Take closest intersection
            let i1 = intersections[0]
            let i1ToPl = pointLight - i1.point
            let pl = simd_normalize(i1ToPl)
            var intensityMultiplier = 1.0

            if let n = i1.normal {
                intensityMultiplier = simd_dot(pl, n)
                if intensityMultiplier < 0 {
                    intensityMultiplier = 0.01
                }
            }

            var rgbValue = UInt8(255 * intensityMultiplier)

            let (val, of) = rgbValue.addingReportingOverflow(ambientLight)

            if of {
                rgbValue = 255
            } else {
                rgbValue = val
            }

            outputBitmap[firstByte] = rgbValue
            outputBitmap[firstByte + 1] = rgbValue
            outputBitmap[firstByte + 2] = rgbValue
            outputBitmap[firstByte + 3] = 255
        }
    }
}
