//
//  Renderables.swift
//  RayTraceUI
//
//  Created by Neal Sidhwaney on 9/24/20.
//  Copyright © 2020 Neal Sidhwaney. All rights reserved.
//

import Foundation
import simd

enum BoundsDictKey {
    case MINX
    case MAXX
    case MINY
    case MAXY
    case MINZ
    case MAXZ
}

protocol WorldObject {
    func intersections(origin: v3d,
                       direction: v3d,
                       intersections : inout [Intersection])

    var isBounding : Bool { get }
    func getBoundedIntersectables() -> [WorldObject]
    func getBounds() -> [BoundsDictKey : Double]
}

protocol Renderable : WorldObject {
    var material : Material? {
        get
    }
}

protocol LightSource {
    var specular : RGB {
        get
    }

    var diffuse : RGB {
        get
    }
}

struct PointLight : LightSource, WorldObject {

    let location : v3d
    let specular : RGB // specular intensity
    let diffuse : RGB // diffuse intensity

    init (_ location : v3d) {
        self.location = location
        specular = RGB(0.2, 0.2, 0.2)
        diffuse = RGB(1.0, 1.0, 1.0)
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

    var isBounding : Bool {
        get {
            return false
        }
    }

    func getBoundedIntersectables() -> [WorldObject] {
        return []
    }

    func getBounds() -> [BoundsDictKey : Double] {
        return [
            .MINX : location.x,
            .MAXX : location.x,
            .MINY : location.y,
            .MAXY : location.y,
            .MINZ : location.z,
            .MAXZ : location.z
        ]
    }
}

struct Triangle : Renderable {
    var material : Material?

    let vertices : [v3d]

    init(_ points : [v3d], material : Material?) {
        self.vertices = points
        self.material = material
        assert(points.count == 3)
    }

    var isBounding : Bool { get {
        return false
        }
    }
    
    func getBoundedIntersectables() -> [WorldObject] {
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
                intersections.append(Intersection(atPoint: point, withNormal: normal, parameter: intersectionParameter, object: self))
            }
        }
    }

    func getBounds() -> [BoundsDictKey : Double] {
        var minX, maxX, minY, maxY, minZ, maxZ : Double
        minX = Double.infinity
        minY = Double.infinity
        minZ = Double.infinity
        maxX = -Double.infinity
        maxY = -Double.infinity
        maxZ = -Double.infinity

        vertices.forEach { (vertex : v3d) in
            setOnCondition(A : &minX, toB : vertex.x, ifTrue : >)
            setOnCondition(A : &minY, toB : vertex.y, ifTrue : >)
            setOnCondition(A : &minZ, toB : vertex.z, ifTrue : >)
            setOnCondition(A : &maxX, toB : vertex.x, ifTrue : <)
            setOnCondition(A : &maxY, toB : vertex.y, ifTrue : <)
            setOnCondition(A : &maxZ, toB : vertex.z, ifTrue : <)
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
}

struct Sphere : WorldObject {
    var location: v3d

    let radius : Double
    let radiusSquared : Double
    let bounding : Bool
    let boundedShapes : [WorldObject]
    let materialName: String = "sphere"
    
    init(_ sphereCenter : v3d, _ sphereRadius : Double) {
        self.location = sphereCenter
        self.radius = sphereRadius
        self.radiusSquared = pow(self.radius, 2)
        self.bounding = false
        self.boundedShapes = []
    }

    init(boundingObjects : [WorldObject]) {
        var minX, maxX, minY, maxY, minZ, maxZ : Double
        minX = Double.infinity
        minY = Double.infinity
        minZ = Double.infinity
        maxX = -Double.infinity
        maxY = -Double.infinity
        maxZ = -Double.infinity

        for intersectable in boundingObjects {
            let boundsDict = intersectable.getBounds()

            setOnCondition(A: &minX, toB: boundsDict[.MINX]!, ifTrue: >)
            setOnCondition(A: &minY, toB: boundsDict[.MINY]!, ifTrue: >)
            setOnCondition(A: &minZ, toB: boundsDict[.MINZ]!, ifTrue: >)
            setOnCondition(A: &maxX, toB: boundsDict[.MAXX]!, ifTrue: <)
            setOnCondition(A: &maxY, toB: boundsDict[.MAXY]!, ifTrue: <)
            setOnCondition(A: &maxZ, toB: boundsDict[.MAXZ]!, ifTrue: <)
        }

        let xDistance = abs(maxX - minX)
        let yDistance = abs(maxY - minY)
        let zDistance = abs(maxZ - minZ)
        self.radius = [xDistance, yDistance, zDistance].max()! / 2
        self.location = v3d(maxX - (xDistance / 2),
                          maxY - (yDistance / 2),
                          maxZ - (zDistance / 2))

        self.radiusSquared = pow(self.radius, 2)
        self.boundedShapes = boundingObjects
        self.bounding = true
    }

    func intersections(origin : v3d,
                       direction : v3d,
                       intersections : inout [Intersection]) {
        let centerToEye = origin - location
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
            let normalAtPoint = normalize(p - location)
            intersections.append(Intersection(atPoint: p,
                                              withNormal: normalAtPoint,
                                              parameter: $0,
                                              object : self))
        }
    }

    func getBounds() -> [BoundsDictKey : Double] {
        return [
            .MINX : location.x - radius,
            .MAXX : location.x + radius,
            .MINY : location.y - radius,
            .MAXY : location.y + radius,
            .MINZ : location.z - radius,
            .MAXZ : location.z + radius
        ]
    }

    func getBoundedIntersectables() -> [WorldObject] {
        return boundedShapes
    }

    var isBounding : Bool {
        get {
            return bounding
        }
    }
}
