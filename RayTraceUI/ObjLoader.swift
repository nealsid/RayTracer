//
//  ObjLoader.swift
//  ObjLoader
//
//  Created by Neal Sidhwaney on 9/5/20.
//  Copyright © 2020 Neal Sidhwaney. All rights reserved.
//

import Foundation
import CoreImage
import AppKit

struct Vertex {
    let x, y, z : Double

    init (_ doubles : [Double]) {
        x = doubles[0]
        y = doubles[1]
        z = doubles[2]
    }
}

struct VertexTexture {
    let u, v : Double
    init (_ doubles : [Double]) {
        u = doubles[0]
        v = doubles[1]
    }
}

struct VertexNormal {
    let x, y, z : Double
    init (_ doubles : [Double]) {
        x = doubles[0]
        y = doubles[1]
        z = doubles[2]
    }
}

struct ObjFile {
    var vertices : [Vertex] = []
    var vertexTextures : [VertexTexture] = []
    var vertexNormals : [VertexNormal] = []
    var faces : [(Int, Int, Int)] = []
}

func readObjFile(_ objFile : String) -> ObjFile {
    let objFileData = try! String(contentsOfFile: objFile)
    let lines = objFileData.split(separator: "\n")

    var o = ObjFile()

    for x in lines {
        if x.starts(with: "#") {
            continue
        }

//        let parseFloats = { (line : String.SubSequence) -> [Float] in
//            return line.split(separator: " ").dropFirst().map() { Float($0)! }
//        }
//
//        let parseInts = { (line : String.SubSequence) -> [Int] in
//            return line.split(separator: " ").dropFirst().map() { Int($0)! }
//        }

        func parseNumbers<T> (_ line : String.SubSequence) -> [T] where T : LosslessStringConvertible, T : Numeric {
            return line.split(separator: " ").dropFirst().map() { (T(String($0))!) }
        }

        if x.starts(with: "v ") {
            o.vertices.append(Vertex(parseNumbers(x)))
        }

        if x.starts(with: "vt ") {
            o.vertexTextures.append(VertexTexture(parseNumbers(x)))
        }

        if x.starts(with: "vn ") {
            o.vertexNormals.append(VertexNormal(parseNumbers(x)))
        }

        if (x.starts(with: "f ")) {
            let vertexIndices : [Int] = parseNumbers(x)
            o.faces.append((vertexIndices[0], vertexIndices[1], vertexIndices[2]))
        }
    }

    return o
}
