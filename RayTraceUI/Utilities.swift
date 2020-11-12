//
//  Utilities.swift
//  RayTraceUI
//
//  Created by Neal Sidhwaney on 10/8/20.
//  Copyright © 2020 Neal Sidhwaney. All rights reserved.
//

import Foundation

func setOnCondition<T>(A : inout T, toB : T, ifTrue : (T, T) -> Bool) {
    if ifTrue(A, toB) {
        A = toB
    }
}

func dp<T : FloatingPoint>(_ a : v3<T>, _ b : v3<T>) -> T {
    return a.x * b.x + a.y * b.y + a.z * b.z
}

func normalize<T : FloatingPoint>(_ a : v3<T>) -> v3<T> {
    let length = sqrt(dp(a, a))
    return v3<T>(a.x / length, a.y / length, a.z / length)
}

func cross<T : FloatingPoint>(_ a: v3<T>, _ b : v3<T>) -> v3<T> {
    return v3<T>(a.y * b.z - a.z * b.y,
                 a.z * b.x - a.x * b.z,
                 a.x * b.y - a.y * b.x)
}

func lenSquared<T : FloatingPoint>(_ a : v3<T>) -> T {
    return a.x * a.x + a.y * a.y + a.z * a.z
}

extension Array {
    func countMatching(pred : ((_ el : Element) -> Bool)) -> Int {
        var match : Int = 0
        self.forEach() {
            if pred($0) {
                match += 1
            }
        }
        return match
    }
}

extension CGColor {
    static func rgb(_ components : [CGFloat.NativeType]) -> CGColor {
        return CGColor(red: CGFloat(components[0]), green: CGFloat(components[1]), blue: CGFloat(components[2]), alpha: CGFloat(components[3]))
    }
    func mapComponents(_ a : CGFloat.NativeType, op: ((_ a : CGFloat.NativeType, _ b : CGFloat.NativeType) -> CGFloat.NativeType)) -> CGColor {
        let newComponents : [CGFloat] = self.components!.map() { CGFloat(op(CGFloat.NativeType($0), a)) }
        return newComponents.withUnsafeBytes() {
            CGColor(colorSpace: self.colorSpace!, components: $0.baseAddress!.bindMemory(to: CGFloat.self, capacity: newComponents.count))!
        }
    }

    static func *(left : CGFloat.NativeType, right : CGColor) -> CGColor {
        return right.mapComponents(left, op: *)
    }

    static func +(left : CGFloat.NativeType, right : CGColor) -> CGColor {
        return right.mapComponents(left, op: +)
    }

    static func +(left: CGColor, right: CGColor) -> CGColor {
        return zip(left.components!, right.components!).map(+).withUnsafeBytes {
            CGColor(colorSpace: left.colorSpace!, components: $0.baseAddress!.bindMemory(to: CGFloat.self, capacity: left.components!.count))!
        }
    }
    static func /(left : CGColor, right : CGFloat.NativeType) -> CGColor {
        return left.mapComponents(right, op: /)
    }

    static func zero() -> CGColor {
        return CGColor.rgb([0, 0, 0, 1.0])
    }
}
