//
//  ViewController.swift
//  RayTraceUI
//
//  Created by Neal Sidhwaney on 9/11/20.
//  Copyright © 2020 Neal Sidhwaney. All rights reserved.
//

import Cocoa
import CoreGraphics
import simd

let imageWidth = 999
let imageHeight = 999

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

func createOpacityAnimation(from : Float, to : Float, duration : Double, fadeInOut : Bool = true, repeatCount : Float = 100) -> CAAnimation {
    let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")

    if (fadeInOut) {
        opacityAnimation.values = [from, to, from]
        opacityAnimation.keyTimes = [0, 0.5, 1]
    } else {
        opacityAnimation.values = [from, to]
        opacityAnimation.keyTimes = [0, 1]
    }

    opacityAnimation.duration = duration
    opacityAnimation.repeatCount = repeatCount
    opacityAnimation.fillMode = CAMediaTimingFillMode.forwards
    return opacityAnimation
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
class ViewController: NSViewController {
    var imageData : Data? = nil
    var unsafeArrayBytes : UnsafeRawPointer? = nil
    var outputBitmap : [UInt8] = ([UInt8])(repeating: 0, count: 4 * imageWidth * imageHeight)
    let group = DispatchGroup()
    var snowGenerator : SnowyImageRenderer!

    let camXCoord : Float = 0

    @IBOutlet weak var camZ: NSTextField!
    @IBOutlet weak var camY: NSTextField!
    @IBOutlet weak var camX: NSTextField!
    // Subview that will contain raytrace image
    @IBOutlet weak var rtView: NSView!

    // The layer that contains the raytraced image
    let rayTraceImageLayer : CALayer = CALayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        snowGenerator = SnowyImageRenderer(rtView.layer!)
        rtView.layer!.borderWidth = 1
        rtView.layer!.borderColor = CGColor.black
        rayTraceImageLayer.frame = rtView.bounds
        rtView.layer!.addSublayer(rayTraceImageLayer)
    }

    @IBAction func startRT(_ sender: Any) {
        snowGenerator.start()
        rayTraceImageLayer.opacity = 0.0

        var rayTraceCGImage : CGImage!
        DispatchQueue.global().async(group: group) { () in

            rayTraceSphere(camera: simd_float3(0, 0, 2500),
                           focalLength: 2000,
                           radius: 400,
                           circleCenter: simd_float3(0, 0, 0),
                           pointLight: simd_float3(0, 500, 300),
                           imageWidth: imageWidth,
                           imageHeight: imageHeight,
                           outputBitmap: &self.outputBitmap)

            self.outputBitmap.withUnsafeBytes() { (buffer : UnsafeRawBufferPointer) in
                rayTraceCGImage = CGImage(width: imageWidth,
                                          height: imageHeight,
                                          bitsPerComponent: 8,
                                          bitsPerPixel: 32,
                                          bytesPerRow: 4 * imageWidth,
                                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue + CGImageAlphaInfo.last.rawValue),
                                          provider: CGDataProvider(dataInfo: nil,
                                                                   data: buffer.baseAddress!,
                                                                   size: self.outputBitmap.count,
                                                                   releaseData: { (_, _, _) in

                                          })!,
                                          decode: nil,
                                          shouldInterpolate: false,
                                          intent: CGColorRenderingIntent.defaultIntent)!
            }
        }

        DispatchQueue.main.async {
            self.group.wait()
            self.rayTraceImageLayer.contents = rayTraceCGImage
            let opacityAnimation = createOpacityAnimation(from: 0.0, to: 1.0, duration: 0.50, fadeInOut: false, repeatCount: 1)
            self.rayTraceImageLayer.add(opacityAnimation, forKey: "opacity")
            self.rayTraceImageLayer.opacity = 1.0
            Timer.scheduledTimer(withTimeInterval: 0.50, repeats: false) { _ in
                self.snowGenerator.stop()
                self.rayTraceImageLayer.removeAllAnimations()
            }
        }
    }
}

func rayTraceSphere(camera : simd_float3,
                    focalLength : Float,
                    radius : Float,
                    circleCenter: simd_float3,
                    pointLight : simd_float3,
                    imageWidth : Int,
                    imageHeight : Int,
                    outputBitmap : inout [UInt8]) {
    let radiusSquared : Float = pow(radius, 2)
    let ambientLight : UInt8 = 100
    
    for i in 0..<imageWidth {
        for j in 0..<imageHeight {
            let cameraToPixelVector = simd_float3(Float(i - imageWidth / 2), Float(imageHeight / 2 - j), camera.z - focalLength) - camera
            let c2punit = simd_normalize(cameraToPixelVector)

            let eyeCenterDiff = camera - circleCenter
            let a = -simd_dot(c2punit, eyeCenterDiff)
            let delta = pow(a, 2) - (simd_dot(eyeCenterDiff, eyeCenterDiff) - radiusSquared)

            let firstByte = j * imageWidth * 4 + i * 4
            if delta < 0 {
                outputBitmap[firstByte] = 0
                outputBitmap[firstByte + 1] = 0
                outputBitmap[firstByte + 2] = 0
                outputBitmap[firstByte + 3] = 255
                continue
            }

            let sqrtdelta = sqrt(delta)

            let d = (a + sqrtdelta, a - sqrtdelta)
            print("intersection parameter values for (\(i), \(j))")
            print("\(d.0) / \(d.1)")
            let p : simd_float3 = camera + d.0 * c2punit
            let q : simd_float3 = camera + d.1 * c2punit
            print("Point of intersection: (\(String(p.x)), \(String(p.y)), \(String(p.z)))")
            print("Point of intersection: (\(String(q.x)), \(String(q.y)), \(String(q.z)))")
            let cam2P = p - camera
            let cam2Q = q - camera
            let pdist = simd_length(cam2P)
            let qdist = simd_length(cam2Q)

            var spherePoint : simd_float3

            if pdist < qdist {
                spherePoint = p
            } else {
                spherePoint = q
            }

            var normalAtIntersection : simd_float3 = spherePoint - circleCenter
            let pointLightVector = simd_normalize(pointLight - spherePoint)
            print("pointlight vector: (\(String(pointLightVector.x)), \(String(pointLightVector.y)), \(String(pointLightVector.z)))")
            print("normal at intersection: (\(String(normalAtIntersection.x)), \(String(normalAtIntersection.y)), \(String(normalAtIntersection.z)))")
            normalAtIntersection = simd_normalize(normalAtIntersection)
            var intensityMultiplier = simd_dot(pointLightVector, normalAtIntersection)
            print("Intensity Multiplier: \(intensityMultiplier)")
            if intensityMultiplier <= 0 {
                intensityMultiplier = 0.01 // implies normal is in opposite direction of point light vector and shouldn't be illuminated
            } else {
                intensityMultiplier /= simd_dot(pointLightVector, pointLightVector) // distance correction for square of distance
            }
            
            var rgbValue = UInt8(255 * intensityMultiplier)
            
            let (val, of) = rgbValue.addingReportingOverflow(ambientLight)
            
            if of {
                rgbValue = 255
            } else {
                rgbValue = val
            }
            
            outputBitmap[firstByte] = rgbValue
            outputBitmap[firstByte + 1] = rgbValue
            outputBitmap[firstByte + 2] = rgbValue
            outputBitmap[firstByte + 3] = 255
        }
    }
}
