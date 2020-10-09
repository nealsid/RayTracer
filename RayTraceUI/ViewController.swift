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

class ViewController: NSViewController {
    var outputBitmap : [UInt8] = ([UInt8])(repeating: 0, count: 4 * imageWidth * imageHeight)
    let group = DispatchGroup()
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
    var t : [RayIntersectable]!
    var rayTraceCGImage : CGImage!
    let viewUpdateTimer = DispatchSource.makeTimerSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        rtView.layer!.borderWidth = 1
        rtView.layer!.borderColor = CGColor.black
        rayTraceImageLayer.frame = rtView.bounds
        rtView.layer!.addSublayer(rayTraceImageLayer)
        rayTraceImageLayer.opacity = 1.0
    }

    @IBAction func loadObjFile(_ sender: Any) {
        let openPanel = NSOpenPanel();
        openPanel.allowsMultipleSelection = false;
        openPanel.canChooseDirectories = false;
        openPanel.canCreateDirectories = false;
        openPanel.canChooseFiles = true;
        openPanel.runModal();
        let objFile = readObjFile(String(openPanel.url!.path))
        let triangles = createTriangleList(objFile)
        t = [Sphere(boundingObjects: triangles)]

    }

    func createTriangleList(_ o : ObjFile) -> [Triangle] {
        var t : [Triangle] = []
        for f in o.faces {
            let face1Vertex = f.0 - 1
            let face2Vertex = f.1 - 1
            let face3Vertex = f.2 - 1
            t.append(Triangle([v3d(o.vertices[face1Vertex].x, o.vertices[face1Vertex].y, o.vertices[face1Vertex].z),
                              v3d(o.vertices[face2Vertex].x, o.vertices[face2Vertex].y, o.vertices[face2Vertex].z),
                              v3d(o.vertices[face3Vertex].x, o.vertices[face3Vertex].y, o.vertices[face3Vertex].z)]))

        }
        return t
    }

    func updateBitmap() {
        rayTraceImageLayer.contents = self.rayTraceCGImage
        rtView.setNeedsDisplay(self.rtView.visibleRect)
    }

    func initStopwatchTimer() {
        stopwatchDisplayTimer = Timer(timeInterval: 0.01, repeats: true) {_ in
            self.rtRenderingTime.stringValue = String(format:"%.3f seconds", Date().timeIntervalSince(self.rtStart))
            self.pixelCounterLabel.stringValue = String(format:"%d", self.pixelCounter)
            self.updateBitmap()
        }
        RunLoop.main.add(self.stopwatchDisplayTimer, forMode: RunLoop.Mode.default)

    }

    @IBAction func startRT(_ sender: Any) {
        pixelCounter = 0
        totalPixelsLabel.stringValue = String(format: "%d pixels", numberOfPixels)
        rtStart = Date()
        initStopwatchTimer()
        DispatchQueue.global().async(group: group) { () in
            raytraceWorld(camera: v3d(0, 0, 150),
                          cameraDirection: v3d(0, 0, -1),
                          focalLength: 10,
                          imageWidth: imageWidth - 1,
                          imageHeight: imageHeight - 1,
                          lights: [PointLight(v3d(-500, -500, 25)),
                                   PointLight(v3d(500, -500, 25)),
                                   PointLight(v3d(-500, 500, 25))],
                          objects: [Sphere(v3d(0, 0, 0), 50)],
//                 Sphere(v3d(0, 1000, 0), 500)],
/*                [Triangle([v3d(-500, -500, 0), v3d(500, -500, 0), v3d(-500, 500, 0)]),
                 Triangle([v3d(-500, 500, 0), v3d(500, -500, 0), v3d(500, 500, 0)]),
                Triangle([v3d(-500, -250, 0), v3d(500, -250, 0), v3d(-500, 0, -500)]),
                Triangle([v3d(-500, 0, -500), v3d(500, -250, 0), v3d(500, 0, -500)]),
                Triangle([v3d(-500, -500, 0), v3d(500, -500, 0), v3d(-500, -250, 0)]),
                Triangle([v3d(-500, -250, 0), v3d(500, -500, 0), v3d(500, -250, 0)])],*/
                          outputBitmap: &self.outputBitmap,
                          pixelDone: {
                            self.pixelCounter += 1
            })
        }


        viewUpdateTimer.setEventHandler() {
            self.createCGImageFromBitmapInBuffer()
        }
        viewUpdateTimer.schedule(deadline: DispatchTime.now(), repeating: 1.0)
        viewUpdateTimer.activate()

        self.group.notify(queue: DispatchQueue.main) {
            self.stopwatchDisplayTimer.invalidate()
            self.viewUpdateTimer.cancel()
            self.createCGImageFromBitmapInBuffer()
            self.updateBitmap()
        }
    }

    func createCGImageFromBitmapInBuffer() {
        self.outputBitmap.withUnsafeBytes() { (buffer : UnsafeRawBufferPointer) in
            self.rayTraceCGImage = CGImage(width: imageWidth,
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
}

