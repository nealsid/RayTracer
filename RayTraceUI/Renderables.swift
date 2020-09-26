//
//  Renderables.swift
//  RayTraceUI
//
//  Created by Neal Sidhwaney on 9/24/20.
//  Copyright © 2020 Neal Sidhwaney. All rights reserved.
//

import Foundation
import simd

protocol RayIntersectable {
    func intersections(origin: v3d,
                       direction: v3d,
                       intersections : inout [Intersection])
}

struct PointLight : RayIntersectable {
    let location : v3d

    init (_ location : v3d) {
        self.location = location
    }

    func intersections(origin: v3d,
                       direction: v3d,
                       intersections : inout [Intersection]) {
        // origin + t*direction = location at what t
        let t = (location - origin) / direction

        if (eq3(t.x, t.y, t.z)) {
            intersections.append(Intersection(atPoint: origin + t.x * direction,
                                              parameter: t.x,
                                              object: self))
        }
    }

    func eq3<T : FloatingPoint>(_ a : T, _ b : T, _ c : T) -> Bool {
        return !a.isInfinite && a == b && b == c
    }
}

struct Sphere : RayIntersectable {
    let center : v3d
    let radius : Double
    let radiusSquared : Double

    init(_ sphereCenter : v3d, _ sphereRadius : Double) {
        self.center = sphereCenter
        self.radius = sphereRadius
        self.radiusSquared = pow(self.radius, 2)
    }

    func intersections(origin : v3d,
                       direction : v3d,
                       intersections : inout [Intersection]) {
        let centerToEye = origin - center
        let a = -simd_dot(direction, centerToEye)
        let delta = pow(a, 2) - (simd_length_squared(centerToEye) - radiusSquared)

        if delta < 0 { // No intersections.
            return
        }

        let sqrtdelta = sqrt(delta)
        var d : [Double] = []

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
            let p : v3d = origin + $0 * direction
            let normalAtPoint = simd_normalize(p - center)
            intersections.append(Intersection(atPoint: p,
                                              withNormal: normalAtPoint,
                                              parameter: $0,
                                              object : self))
        }
    }
}
