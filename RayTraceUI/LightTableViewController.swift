//
//  LightTableViewController.swift
//  RayTraceUI
//
//  Created by Neal Sidhwaney on 11/24/20.
//  Copyright © 2020 Neal Sidhwaney. All rights reserved.
//

import Foundation
import Cocoa

class LightViewController : NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    @objc dynamic var lights : [PointLight] = []
    let columnToProperty : [Int : String] = [:]
    
    @IBOutlet var lightsArrayController: NSArrayController!
    @IBOutlet weak var lightTableView: NSTableView!
}
