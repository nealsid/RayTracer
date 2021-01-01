//
//  LightTableViewController.swift
//  RayTraceUI
//
//  Created by Neal Sidhwaney on 11/24/20.
//  Copyright © 2020 Neal Sidhwaney. All rights reserved.
//

import Foundation
import Cocoa

class LightViewController : NSViewController {
    @objc dynamic var lights : [PointLight] = []
    let columnToProperty : [Int : String] = [:]
    
    @IBOutlet var lightsArrayController: NSArrayController!
    @IBOutlet weak var lightTableView: NSTableView!

    @objc func doubleClickAction(_ tableView : NSTableView) {
        print(lights[tableView.selectedRow])
    }
}
