//
//  SnowyImages.swift
//  RayTraceUI
//
//  Created by Neal Sidhwaney on 9/16/20.
//  Copyright © 2020 Neal Sidhwaney. All rights reserved.
//

import Foundation
import Cocoa
import CoreGraphics

struct SnowyImageData {
    var outputBitmap : [UInt8] = ([UInt8])(repeating: 0, count: 4 * imageWidth * imageHeight)
    var snowyCGImage : CGImage!

    init() {
        for i in 0..<imageWidth {
            for j in 0..<imageHeight {
                let pixVal = UInt8.random(in: 0...255)
                let firstByte = j * imageWidth * 4 + i * 4
                outputBitmap[firstByte] = pixVal
                outputBitmap[firstByte + 1] = pixVal
                outputBitmap[firstByte + 2] = pixVal
                outputBitmap[firstByte + 3] = 255
            }
        }

        outputBitmap.withUnsafeBytes() { (buffer : UnsafeRawBufferPointer) in
            let dataProvider = CGDataProvider(dataInfo: nil,
                                              data: buffer.baseAddress!,
                                              size: outputBitmap.count,
                                              releaseData: {
                                                (_, _, _) -> Void in
            })!

            self.snowyCGImage = CGImage(width: imageWidth,
                                 height: imageHeight,
                                 bitsPerComponent: 8,
                                 bitsPerPixel: 32,
                                 bytesPerRow: 4 * imageWidth,
                                 space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                 bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue + CGImageAlphaInfo.last.rawValue),
                                 provider: dataProvider,
                                 decode: nil,
                                 shouldInterpolate: false,
                                 intent: CGColorRenderingIntent.defaultIntent)!
        }
    }
}

class SnowyImageRenderer {
    let viewLayer : CALayer
    var snowyImages : [SnowyImageData] = []
    var snowyImageLayers : [CALayer] = []

    init(_ layer : CALayer) {
        self.viewLayer = layer
        for _ in 0..<2 {
            snowyImages.append(SnowyImageData())
            let snowLayer = CALayer()
            snowLayer.frame = viewLayer.bounds
            snowLayer.opacity = 0.0
            snowLayer.contents = snowyImages.last!.snowyCGImage
            viewLayer.addSublayer(snowLayer)
            snowyImageLayers.append(snowLayer)
        }
    }

    func start() {
        let fromTo : [(Float, Float)] = [(0.4, 1.0), (1.0, 0.4)]
        zip(snowyImageLayers, fromTo).forEach { (layer : CALayer, f : (Float, Float)) in
            layer.opacity = f.0
            layer.add(createOpacityAnimation(from: f.0, to: f.1, duration: 2.5), forKey: "animation")
            layer.opacity = f.1
        }
    }

    func stop() {
        snowyImageLayers.forEach { $0.opacity = 0 }
        snowyImageLayers.forEach { $0.removeAllAnimations() }
    }
}
