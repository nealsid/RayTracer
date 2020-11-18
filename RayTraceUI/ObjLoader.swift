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

struct Material {
    var specularExponent : Double = 0.0
    var dissolution : Double = 0.0
    var illumination : Int = 1
    var kd : v3d = v3d(0, 0, 0)
    var ka : v3d = v3d(0, 0, 0)
    var ks : v3d = v3d(0, 0, 0)
}

func parseNumbers<T> (_ line : String.SubSequence) -> [T] where T : LosslessStringConvertible, T : Numeric {
    return line.split(separator: " ").dropFirst().map() { (T(String($0))!) }
}

func readMtlFile(_ mtlFile : String) -> [String : Material] {
    var ret : [String : Material] = [:]
    let objFileData = try! String(contentsOfFile: mtlFile)
    let lines = objFileData.split(separator: "\n")

    for var i in 0..<lines.count {

        let x = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
        if x.starts(with: "#") || x.isEmpty {
            continue
        }

        if (x.starts(with: "newmtl")) {
            let materialName = String(x.split(separator: " ")[1])
            var m = Material()
            for j in i + 1..<lines.count {
                let mtlLine = lines[j]
                if mtlLine.starts(with:"Ns ") {
                    m.specularExponent = parseNumbers(mtlLine)[0]
                    continue
                }
                if mtlLine.starts(with:"d ") {
                    m.dissolution = parseNumbers(mtlLine)[0]
                    continue
                }
                if mtlLine.starts(with:"illum ") {
                    m.illumination = parseNumbers(mtlLine)[0]
                    continue
                }
                if mtlLine.starts(with:"Kd ") {
                    m.kd = v3d(parseNumbers(mtlLine))
                    continue
                }
                if mtlLine.starts(with:"Ka ") {
                    m.ka = v3d(parseNumbers(mtlLine))
                    continue
                }
                if mtlLine.starts(with:"Ks ") {
                    m.ks = v3d(parseNumbers(mtlLine))
                    continue
                }

                if mtlLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ret[materialName] = m
                    i = j
                    break
                }

                if mtlLine.starts(with: "newmtl") {
                    ret[materialName] = m
                    i = j
                    break
                }
            }

        }
    }
    return ret
}

func readObjFile(_ objFile : String) -> ObjFile {
    let objFileData = try! String(contentsOfFile: objFile)
    let lines = objFileData.split(separator: "\n")

    var o = ObjFile()

    for x in lines {
        if x.starts(with: "#") {
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
            o.faces.append((vertexIndices[0], vertexIndices[1], vertexIndices[2]))
            continue
        }
    }

    return o
}
