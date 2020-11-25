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
    var lights : [LightSource] = []

    @IBOutlet weak var lightTableView: NSTableView!

    func numberOfRows(in tableView: NSTableView) -> Int {
        return 5//lights.count
    }

    func tableView(_ tableView: NSTableView, viewFor: NSTableColumn?, row: Int) -> NSView? {
        let cellView = self.lightTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cellView"), owner: self) as! NSTableCellView
        cellView.textField?.stringValue = "foo"
        return cellView
    }
}
