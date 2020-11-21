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

struct Face {
    var vertexIndices : (Int, Int, Int)!
    var materialName : String = ""
}

struct ObjFile {
    var vertices : [Vertex] = []
    var vertexTextures : [VertexTexture] = []
    var vertexNormals : [VertexNormal] = []
    var faces : [Face] = []
}

struct Material {
    let specularExponent : Double
    let dissolution : Double
    let illumination : Int
    let kd : RGB
    let ka : RGB
    let ks : RGB
}

func parseNumbers<T : LosslessStringConvertible> (_ line : Substring) -> [T] {
    return line.split(separator: " ").dropFirst().map() { T(String($0))! }
}

extension Substring {
    // A replacement for String.trimmingCharacters that returns a Substring instead of a String to avoid making a copy.
    func trimToSubstring(in toTrim : CharacterSet) -> Substring {
        if (self.startIndex == self.endIndex) {
            return self
        }

        var startIndex = self.startIndex
        // Make endIndex inclusive of last element.
        var endIndex = self.index(self.endIndex, offsetBy: -1)

        // if we're passed a 1 element string that does not contain a character to be trimmed, we'll end up testing it twice
        // alternative is to handle it as a special case.

        while startIndex <= endIndex && toTrim.contains(self[startIndex].unicodeScalars.first!) {
            startIndex = self.index(startIndex, offsetBy: 1)
        }

        while endIndex > startIndex && toTrim.contains(self[endIndex].unicodeScalars.first!) {
            endIndex = self.index(endIndex, offsetBy: -1)
        }

        if startIndex > endIndex { // all characters in the string were trimmed characters
            return ""
        }

        return self[startIndex...endIndex]
    }
}

func readMtlFile(_ mtlFile : String) -> [String : Material] {
    var ret : [String : Material] = [:]
    let objFileData = try! String(contentsOfFile: mtlFile)
    let lines = objFileData.split(separator: "\n")

    for var i in 0..<lines.count {

        let x = lines[i].trimToSubstring(in: .whitespacesAndNewlines)
        if x.starts(with: "#") || x.isEmpty {
            continue
        }

        if (x.starts(with: "newmtl")) {
            let materialName = String(x.split(separator: " ")[1])
            var specularExponent : Double!
            var dissolution : Double!
            var illumination : Int!
            var kd : RGB!
            var ka : RGB!
            var ks : RGB!

            for j in i + 1..<lines.count {
                let mtlLine = lines[j]
                if mtlLine.starts(with:"Ns ") {
                    specularExponent = parseNumbers(mtlLine)[0]
                    continue
                }
                if mtlLine.starts(with:"d ") {
                    dissolution = parseNumbers(mtlLine)[0]
                    continue
                }
                if mtlLine.starts(with:"illum ") {
                    illumination = parseNumbers(mtlLine)[0]
                    continue
                }
                if mtlLine.starts(with:"Kd ") {
                    kd = RGB(parseNumbers(mtlLine))!
                    continue
                }
                if mtlLine.starts(with:"Ka ") {
                    ka = RGB(parseNumbers(mtlLine))!
                    continue
                }
                if mtlLine.starts(with:"Ks ") {
                    ks = RGB(parseNumbers(mtlLine))!
                    continue
                }

                if mtlLine.trimToSubstring(in: .whitespacesAndNewlines).isEmpty ||
                    mtlLine.starts(with: "newmtl") {
                    i = j
                    break
                }
            }
            ret[materialName] = Material(specularExponent: specularExponent,
                                         dissolution: dissolution,
                                         illumination: illumination,
                                         kd: kd,
                                         ka: ka,
                                         ks: ks)
        }
    }
    return ret
}

func readObjFile(_ objFile : String) -> ObjFile {
    let objFileData = try! String(contentsOfFile: objFile)
    let lines = objFileData.split(separator: "\n")

    var o = ObjFile()
    var materialName : Substring = ""

    for x in lines {
        if x.starts(with: "#") {
            continue
        }

        if x.starts(with: "usemtl ") {
            materialName = x.split(separator: " ").last!
            continue
        }

        if x.starts(with: "v ") {
            o.vertices.append(Vertex(parseNumbers(x)))
            continue
        }

        if x.starts(with: "vt ") {
            o.vertexTextures.append(VertexTexture(parseNumbers(x)))
            continue
        }

        if x.starts(with: "vn ") {
            o.vertexNormals.append(VertexNormal(parseNumbers(x)))
            continue
        }

        if (x.starts(with: "f ")) {
            let vertexIndices : [Int] = parseNumbers(x)
            o.faces.append(Face(vertexIndices: (vertexIndices[0], vertexIndices[1], vertexIndices[2]),
                                materialName: String(materialName)))
            continue
        }
    }

    return o
}
