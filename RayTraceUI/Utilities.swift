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

extension Array where Element == RGBA {
    func average() -> Element {
        var cumulative : RGBA = RGBA(0, 0, 0, 0)
        for rgba in self {
            cumulative = cumulative + rgba
        }

        let doubleCount = Double(self.count)
        return RGBA(cumulative.red / doubleCount,
                    cumulative.green / doubleCount,
                    cumulative.blue / doubleCount,
                    cumulative.alpha / doubleCount)
    }
}

struct RGBA {
    var red : Double
    var green : Double
    var blue : Double
    var alpha : Double

    init(_ r : Double, _ g : Double, _ b : Double, _ a : Double) {
        self.red = r
        self.green = g
        self.blue = b
        self.alpha = a
        assertComponentsBetweenZeroAndOne()
    }


    init(_ r : Double, _ g : Double, _ b : Double) {
        self.init(r, g, b, 1.0)
    }

    static func zero() -> RGBA {
        return RGBA(0, 0, 0, 0)
    }

    static func *(left : RGBA, right : RGBA) -> RGBA {
        return RGBA(left.red * right.red,
                    left.green * right.green,
                    left.blue * right.blue,
                    left.alpha * right.alpha)
    }

    static func *(left : Double, right : RGBA) -> RGBA {
        return RGBA(right.red * left,
                    right.green * left,
                    right.blue * left,
                    right.alpha)
    }

    static func *(left : RGBA, right : Double) -> RGBA {
        return right * left
    }

    static func +(left : Double, right : RGBA) -> RGBA {
        return RGBA(right.red + left,
                    right.green + left,
                    right.blue + left,
                    right.alpha)
    }

    static func +(left : RGBA, right : Double) -> RGBA {
        return right + left
    }

    static func +(left : RGBA, right : RGBA) -> RGBA {
        return RGBA(left.red + right.red,
                    left.green + right.green,
                    left.blue + right.blue,
                    left.alpha + right.alpha)
    }

    func assertComponentsBetweenZeroAndOne() {
        assert(self.red >= 0 && self.red <= 1.0)
        assert(self.green >= 0 && self.green <= 1.0)
        assert(self.blue >= 0 && self.blue <= 1.0)
        assert(self.alpha >= 0 && self.alpha <= 1.0)
    }
    static var black : RGBA = RGBA(0, 0, 0, 1.0)
}
