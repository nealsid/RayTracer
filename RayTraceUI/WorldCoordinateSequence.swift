//
//  WorldCoordinateSequence.swift
//  RayTraceUI
//
//  Created by Neal Sidhwaney on 10/23/20.
//  Copyright © 2020 Neal Sidhwaney. All rights reserved.
//

import Foundation

struct WorldCoordinate {
    let p : [v3d]
    let xPixel : Int
    let yPixel : Int
}
// A struct that lets you iterate over a plane in 3D space taking into account
// pixel to world coordinate transformations.  Pixel 0,0 is assumed to map to the
// upper left. u points from ul to ur, and v points from ll to ul.
struct WorldCoordinateSequence : Sequence, IteratorProtocol {
    let ul : v3d
    let u : v3d
    let v : v3d
    let startXPixel : Int
    let startYPixel: Int
    let endXPixel : Int
    let endYPixel : Int
    let pixelSubdivision : Double

    var currentXPixel : Int
    var currentYPixel : Int

    let pixelsPerWorldHorizontal : Double
    let pixelsPerWorldVertical : Double

    init(ul: v3d,
         ur: v3d,
         ll: v3d,
         lr: v3d,
         u : v3d,
         v : v3d,
         startXPixel : Int,
         startYPixel: Int,
         endXPixel : Int,
         endYPixel : Int,
         pixelSubdivision : Double) {
        self.ul = ul
        self.u = u
        self.v = v
        self.startXPixel = startXPixel
        self.startYPixel = startYPixel
        self.endXPixel = endXPixel
        self.endYPixel = endYPixel
        self.pixelSubdivision = pixelSubdivision

        self.currentXPixel = startXPixel
        self.currentYPixel = startYPixel

        self.pixelsPerWorldHorizontal = Double(endXPixel - startXPixel) / sqrt(lenSquared(ur - ul))
        self.pixelsPerWorldVertical = Double(endYPixel - startYPixel) / sqrt(lenSquared(ll - ul))
    }

    func pixelToWorldCoordinate(_ i : Double, _ j : Double) -> v3d {
        let uComponent = ((u * i) / pixelsPerWorldHorizontal)
        let vComponent = ((v * j) / pixelsPerWorldVertical)
        return ul + uComponent - vComponent
    }

    mutating func next() -> WorldCoordinate? {
        if (currentXPixel == endXPixel + 1) {
            return nil
        }
        var points : [v3d] = []
        
        for x in stride(from: Double(currentXPixel), to: Double(currentXPixel+1), by: pixelSubdivision) {
            for y in stride(from: Double(currentYPixel), to: Double(currentYPixel+1), by: pixelSubdivision) {
                points.append(pixelToWorldCoordinate(x, y))
            }
        }

        currentYPixel += 1

        if (currentYPixel > endYPixel) {
            currentXPixel += 1
            currentYPixel = startYPixel
        }
        return WorldCoordinate(p: points, xPixel: currentXPixel, yPixel: currentYPixel)
    }
}
