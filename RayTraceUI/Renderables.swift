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

        if (t.x >= 0.0000001 && eq3(t.x, t.y, t.z)) {
            intersections.append(Intersection(atPoint: origin + t.x * direction,
                                              parameter: t.x,
                                              object: self))
        }
    }

    func eq3<T : FloatingPoint>(_ a : T, _ b : T, _ c : T) -> Bool {
        return !a.isInfinite && a == b && b == c
    }
}

struct Triangle : RayIntersectable {
    let vertices : [v3d]

    init(_ points : [v3d]) {
        self.vertices = points
        assert(points.count == 3)
    }

     func intersections(origin: v3d, direction: v3d, intersections: inout [Intersection]) {
        let v0v1 = vertices[1] - vertices[0]
        let v0v2 = vertices[2] - vertices[0]
        let v1v2 = vertices[2] - vertices[1]
        let v2v0 = -v0v2

        let normal = simd_normalize(simd_cross(v0v1, v0v2))
        let planeConstant = simd_dot(normal, vertices[0])
        let nddot = simd_dot(normal, -direction)

        if nddot <= 0 {  // back side of triangle or the ray is parallel to the triangle.
            return
        }

        let intersectionParameter = (planeConstant - simd_dot(normal, origin)) / -nddot // TODO fix negative sign (should be on origin?)

        if (intersectionParameter > 0) {
            let point : v3d = origin + intersectionParameter * direction
            let v0p = point - vertices[0]
            let v1p = point - vertices[1]
            let v2p = point - vertices[2]

            let a = simd_cross(v0v1, v0p)
            let b = simd_cross(v1v2, v1p)
            let c = simd_cross(v2v0, v2p)
            if simd_dot(a, normal) >= 0 &&
                simd_dot(b, normal) >= 0 &&
                simd_dot(c, normal) >= 0 {
//                print("normal: \(normal)")
//                print("pointnormal: \(n)")
                print("intersection: \(point)")
                intersections.append(Intersection(atPoint: point, withNormal: normal, parameter: intersectionParameter, object: self))
            }
        }
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

        d.filter({ $0 >= 0.0000001 }).forEach() {
            let p : v3d = origin + $0 * direction
            let normalAtPoint = simd_normalize(p - center)
            intersections.append(Intersection(atPoint: p,
                                              withNormal: normalAtPoint,
                                              parameter: $0,
                                              object : self))
        }
    }
}
