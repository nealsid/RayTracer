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

