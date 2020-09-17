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
    let point : simd_float3
    let normal : simd_float3
    
    init(atPoint : simd_float3, withNormal: simd_float3) {
        self.point = atPoint
        self.normal = withNormal
    }
}

protocol Renderable {
    func intersections(origin: simd_float3,
                       direction: simd_float3,
                       intersections : inout [Intersection])
}

struct Sphere : Renderable {
    let center : simd_float3
    let radius : Float
    let radiusSquared : Float
    
    init(_ sphereCenter : simd_float3, _ sphereRadius : Float) {
        self.center = sphereCenter
        self.radius = sphereRadius
        self.radiusSquared = pow(self.radius, 2)
    }
    
    func intersections(origin : simd_float3,
                       direction : simd_float3,
                       intersections : inout [Intersection]) {
        intersections.removeAll()
        
        let centerToEye = origin - center
        let a = -simd_dot(direction, centerToEye)
        let delta = pow(a, 2) - (simd_length_squared(centerToEye) - radiusSquared)

        if delta < 0 { // No intersections.
            return
        }
        
        let sqrtdelta = sqrt(delta)
        var d : [Float] = []

        if delta == 0 {
            d = [a]
        } else {
            let t1 = a + sqrtdelta
            let t2 = a - sqrtdelta
            if t1 < t2 {
                d = [t1, t2]
            } else {
                d = [t2, t1]
            }
        }
        
        d.forEach() {
            let p : simd_float3 = origin + $0 * direction
            let normalAtPoint = simd_normalize(p - center)
            intersections.append(Intersection(atPoint: p,
                                              withNormal: normalAtPoint))
        }
    }
}


func raytraceWorld(camera : simd_float3,
                   focalLength : Float,
                   pointLight : simd_float3,
                   imageWidth : Int,
                   imageHeight : Int,
                   objects : [Renderable],
                   outputBitmap : inout [UInt8]) {
    let ambientLight : UInt8 = 100
    
    for i in 0..<imageWidth {
        for j in 0..<imageHeight {
            let cameraToPixelVector = simd_float3(Float(i - imageWidth / 2), Float(imageHeight / 2 - j), camera.z - focalLength) - camera
            let c2punit = simd_normalize(cameraToPixelVector)

            let firstByte = j * imageWidth * 4 + i * 4
            var intersections : [Intersection] = []
            for o in objects {
                o.intersections(origin: camera, direction: c2punit, intersections: &intersections)
                if intersections.isEmpty {
                    outputBitmap[firstByte] = 0
                    outputBitmap[firstByte + 1] = 0
                    outputBitmap[firstByte + 2] = 0
                    outputBitmap[firstByte + 3] = 255
                    continue
                }
                // Take closest intersection
                let i1 = intersections[0]
                let n = i1.normal
                let i1ToPl = pointLight - i1.point
                let pl = simd_normalize(i1ToPl)
                var intensityMultiplier = simd_dot(pl, n)
                if intensityMultiplier < 0 {
                    intensityMultiplier = 0.01
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
}
