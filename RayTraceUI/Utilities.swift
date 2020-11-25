//
//  Utilities.swift
//  RayTraceUI
//
//  Created by Neal Sidhwaney on 10/8/20.
//  Copyright © 2020 Neal Sidhwaney. All rights reserved.
//

import Foundation

extension Optional {
    func ifPresent<U>(transform : (Wrapped) -> U) -> U? {
        return self.map(transform)
    }
}

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

extension Array where Element == RGB {
    func average() -> Element {
        var cumulative : RGB = RGB(0, 0, 0)
        for rgb in self {
            cumulative.add(rgb)
        }

        let doubleCount = Double(self.count)
        cumulative.scale(1 / doubleCount)
        cumulative.checkForNan()
        return cumulative
    }
}

func clampFunction<T : Comparable>(_ lower : T, _ upper : T) -> ((T) -> T) {
    return { (val : T) in
        if val < lower {
            return lower
        }

        if val > upper {
            return upper
        }
        return val
    }
}

struct RGB {
    typealias ArrayLiteralElement = Double

    var red : Double
    var green : Double
    var blue : Double
    var clamper = clampFunction(0.0, 1.0)

    init(_ r : Double, _ g : Double, _ b : Double) {
        self.red = clamper(r)
        self.green = clamper(g)
        self.blue = clamper(b)
        assertComponentsBetweenZeroAndOne()
    }

    init?(_ elements: [Double]) {
        if elements.count == 3 {
            self.init(elements[0], elements[1], elements[2])
            return
        }
        return nil
    }

    mutating func clamp() {
        self.red = clamper(self.red)
        self.green = clamper(self.green)
        self.blue = clamper(self.blue)
    }

    // Add without clamping
    mutating func add(_ other : RGB) {
        self.red = self.red + other.red
        self.green = self.green + other.green
        self.blue = self.blue + other.blue
        checkForNan()
    }

    mutating func scale(_ factor : Double) {
        self.red = factor * self.red
        self.green = factor * self.green
        self.blue = factor * self.blue
        checkForNan()
    }

    mutating func scale(_ factor : RGB) {
        self.red = factor.red * self.red
        self.green = factor.green * self.green
        self.blue = factor.blue * self.blue
        checkForNan()
    }

    static func zero() -> RGB {
        return RGB(0, 0, 0)
    }

    func assertComponentsBetweenZeroAndOne() {
        assert(self.red >= 0 && self.red <= 1.0)
        assert(self.green >= 0 && self.green <= 1.0)
        assert(self.blue >= 0 && self.blue <= 1.0)
    }

    func checkForNan() {
        assert(!self.red.isNaN)
        assert(!self.green.isNaN)
        assert(!self.blue.isNaN)
    }
    
    static var black : RGB = RGB(0, 0, 0)
}

func eq3<T : FloatingPoint>(_ a : T, _ b : T, _ c : T) -> Bool {
    return !a.isInfinite && a == b && b == c
}
