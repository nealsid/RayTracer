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

    var isBounding : Bool { get }
    func getBoundedIntersectables() -> [RayIntersectable]
    func getXBounds() -> (Double, Double)
    func getYBounds() -> (Double, Double)
    func getZBounds() -> (Double, Double)
}

struct PointLight : RayIntersectable {
    let location : v3d
    var isBounding : Bool { get {
        return false
        }
    }

    func getBoundedIntersectables() -> [RayIntersectable] {
        return []
    }

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

    func getXBounds() -> (Double, Double) { (0, 0) }
    func getYBounds() -> (Double, Double) { (0, 0) }
    func getZBounds() -> (Double, Double) { (0, 0) }
}

struct Triangle : RayIntersectable {
    let vertices : [v3d]

    init(_ points : [v3d]) {
        self.vertices = points
        assert(points.count == 3)
    }

    var isBounding : Bool { get {
        return false
        }
    }

    func getBoundedIntersectables() -> [RayIntersectable] {
        return []
    }


    func intersections(origin: v3d, direction: v3d, intersections: inout [Intersection]) {
        let v0v1 = vertices[1] - vertices[0]
        let v0v2 = vertices[2] - vertices[0]
        let v1v2 = vertices[2] - vertices[1]
        let v2v0 = -v0v2

        let normal = normalize(cross(v0v1, v0v2))
        let planeConstant = dp(normal, vertices[0])
        let nddot = dp(normal, -direction)

        if nddot <= 0 {  // back side of triangle or the ray is parallel to the triangle.
            return
        }

        let intersectionParameter = (planeConstant - dp(normal, origin)) / -nddot // TODO fix negative sign (should be on origin?)

        if (intersectionParameter > 0) {
            let point : v3d = origin + intersectionParameter * direction
            let v0p = point - vertices[0]
            let v1p = point - vertices[1]
            let v2p = point - vertices[2]

            let a = cross(v0v1, v0p)
            let b = cross(v1v2, v1p)
            let c = cross(v2v0, v2p)
            if dp(a, normal) >= 0 &&
                dp(b, normal) >= 0 &&
                dp(c, normal) >= 0 {
                print("intersection")
                intersections.append(Intersection(atPoint: point, withNormal: normal, parameter: intersectionParameter, object: self))
            }
        }
    }

    func getXBounds() -> (Double, Double) {
        let minX = vertices.min() { (a, b) in
            a.x < b.x
            }!.x
        let maxX = vertices.max() { (a, b) in
            a.x > b.x
            }!.x
        return (minX, maxX)
    }

    func getYBounds() -> (Double, Double) {
        let minY = vertices.min() { (a, b) in
            a.y < b.y
            }!.y
        let maxY = vertices.max() { (a, b) in
            a.y > b.y
            }!.y
        return (minY, maxY)
    }

    func getZBounds() -> (Double, Double) {
        let minZ = vertices.min() { (a, b) in
            a.z < b.z
            }!.z
        let maxZ = vertices.min() { (a, b) in
            a.z > b.z
            }!.z
        return (minZ, maxZ)
    }
}

struct Sphere : RayIntersectable {
    let center : v3d
    let radius : Double
    let radiusSquared : Double
    let bounding : Bool
    let boundedShapes : [RayIntersectable]

    init(_ sphereCenter : v3d, _ sphereRadius : Double) {
        self.center = sphereCenter
        self.radius = sphereRadius
        self.radiusSquared = pow(self.radius, 2)
        self.bounding = false
        self.boundedShapes = []
    }

    init(boundingObjects : [RayIntersectable]) {
        var minX, maxX, minY, maxY, minZ, maxZ : Double
        minX = Double.infinity
        minY = Double.infinity
        minZ = Double.infinity
        maxX = -Double.infinity
        maxY = -Double.infinity
        maxZ = -Double.infinity

        for intersectable in boundingObjects {
            let xBounds = intersectable.getXBounds()
            let yBounds = intersectable.getYBounds()
            let zBounds = intersectable.getZBounds()
            if minX > xBounds.0 {
                minX = xBounds.0
            }
            if maxX < xBounds.1 {
                maxX = xBounds.1
            }
            if minY > yBounds.0 {
                minY = yBounds.0
            }
            if maxY < yBounds.1 {
                maxY = yBounds.1
            }
            if minZ > zBounds.0 {
                minZ = zBounds.0
            }
            if maxZ < zBounds.1 {
                maxZ = zBounds.1
            }
        }

        let xDistance = maxX - minX
        let yDistance = maxY - minY
        let zDistance = maxZ - minZ
        self.radius = [xDistance, yDistance, zDistance].max()!
        self.center = v3d(maxX - (xDistance / 2),
                          maxY - (yDistance / 2),
                          maxZ - (zDistance / 2))

        self.radiusSquared = pow(self.radius, 2)
        self.boundedShapes = boundingObjects
        self.bounding = true
    }

    func intersections(origin : v3d,
                       direction : v3d,
                       intersections : inout [Intersection]) {
        let centerToEye = origin - center
        let a = -dp(direction, centerToEye)
        let delta = pow(a, 2) - (lenSquared(centerToEye) - radiusSquared)

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
            let normalAtPoint = normalize(p - center)
            intersections.append(Intersection(atPoint: p,
                                              withNormal: normalAtPoint,
                                              parameter: $0,
                                              object : self))
        }
    }

    func getXBounds() -> (Double, Double) { (0, 0) }
    func getYBounds() -> (Double, Double) { (0, 0) }
    func getZBounds() -> (Double, Double) { (0, 0) }

    func getBoundedIntersectables() -> [RayIntersectable] {
        return boundedShapes
    }

    var isBounding : Bool {
        get {
            return bounding
        }
    }
}
