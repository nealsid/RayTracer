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

let imageWidth : Int = 1000
let imageHeight : Int = 1000

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

class ViewController: NSViewController {
    var outputBitmap : [UInt8] = ([UInt8])(repeating: 0, count: 4 * imageWidth * imageHeight)
    let group = DispatchGroup()
    var snowGenerator : SnowyImageRenderer!
    var stopwatchDisplayTimer : Timer!
    let camXCoord : Float = 0

    @IBOutlet weak var camZ: NSTextField!
    @IBOutlet weak var camY: NSTextField!
    @IBOutlet weak var camX: NSTextField!
    // Subview that will contain raytrace image
    @IBOutlet weak var rtView: NSView!

    @IBOutlet weak var rtRenderingTime: NSTextField!
    var rtStart : Date!
    var rtEnd : Date!

    @IBOutlet weak var totalPixelsLabel: NSTextField!
    @IBOutlet weak var pixelCounterLabel: NSTextField!

    var pixelCounter : Int = 0
    let numberOfPixels : Int = imageWidth * imageHeight

    // The layer that contains the raytraced image
    let rayTraceImageLayer : CALayer = CALayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        snowGenerator = SnowyImageRenderer(rtView.layer!)
        rtView.layer!.borderWidth = 1
        rtView.layer!.borderColor = CGColor.black
        rayTraceImageLayer.frame = rtView.bounds
        rtView.layer!.addSublayer(rayTraceImageLayer)

        Timer.scheduledTimer(withTimeInterval: 0.50, repeats: false) { _ in
            self.snowGenerator.stop()
            self.rayTraceImageLayer.removeAllAnimations()
        }
    }

    func initStopwatchTimer() {
        stopwatchDisplayTimer = Timer(timeInterval: 0.01, repeats: true) {_ in
            self.rtRenderingTime.stringValue = String(format:"%.3f seconds", Date().timeIntervalSince(self.rtStart))
            self.pixelCounterLabel.stringValue = String(format:"%d", self.pixelCounter)
        }
        RunLoop.main.add(self.stopwatchDisplayTimer, forMode: RunLoop.Mode.default)
    }

    @IBAction func startRT(_ sender: Any) {
        snowGenerator.start()
        rayTraceImageLayer.opacity = 0.0

        var rayTraceCGImage : CGImage!
        pixelCounter = 0
        totalPixelsLabel.stringValue = String(format: "%d pixels", numberOfPixels)
        rtStart = Date()
        initStopwatchTimer()
        DispatchQueue.global().async(group: group) { () in
            raytraceWorld(camera: v3d(0, 0, 1000),
                          cameraDirection: v3d(0, 0, -1),
                          focalLength: 400,
                          imageWidth: imageWidth - 1,
                          imageHeight: imageHeight - 1,
                          lights: [PointLight(v3d(-500, -500, 25)),
                                   PointLight(v3d(500, -500, 25)),
                                   PointLight(v3d(-500, 500, 25))],
                          objects: /*[Sphere(v3d(0, 0, 0), 500),
                 Sphere(v3d(0, 1000, 0), 500)],*/
                [/*Triangle([v3d(-500, -500, 0), v3d(500, -500, 0), v3d(-500, 500, 0)]),
                 Triangle([v3d(-500, 500, 0), v3d(500, -500, 0), v3d(500, 500, 0)]),*/
                Triangle([v3d(-500, -250, 0), v3d(500, -250, 0), v3d(-500, 0, -500)]),
                Triangle([v3d(-500, 0, -500), v3d(500, -250, 0), v3d(500, 0, -500)]),
                Triangle([v3d(-500, -500, 0), v3d(500, -500, 0), v3d(-500, -250, 0)]),
                Triangle([v3d(-500, -250, 0), v3d(500, -500, 0), v3d(500, -250, 0)])],
                          outputBitmap: &self.outputBitmap,
                          pixelDone: {
                            self.pixelCounter += 1
            })

            self.stopwatchDisplayTimer.fire()
            self.stopwatchDisplayTimer.invalidate()
            
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
            
            self.group.notify(queue: DispatchQueue.main) {
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
}

