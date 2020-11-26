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
    var lights : [PointLight] = []
    let columnToProperty : [Int : String] = [:]

    @IBOutlet weak var lightTableView: NSTableView!

    func numberOfRows(in tableView: NSTableView) -> Int {
        return lights.count
    }

    func valueForColumnNumber(row : Int, column : NSTableColumn) -> String {
        switch(column) {
        case lightTableView.tableColumns[0]:
            return String(lights[row].location.x)
        case lightTableView.tableColumns[1]:
            return String(lights[row].location.y)
        case lightTableView.tableColumns[2]:
            return String(lights[row].location.z)
        case lightTableView.tableColumns[3]:
            return lights[row].specular.description
        case lightTableView.tableColumns[4]:
            return lights[row].diffuse.description
        default:
            return ""
        }
    }

    func tableView(_ tableView: NSTableView, viewFor: NSTableColumn?, row: Int) -> NSView? {
        let cellView = self.lightTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cellView"), owner: self) as! NSTableCellView
        if let tableColumn = viewFor {
            cellView.textField?.stringValue = valueForColumnNumber(row: row, column: tableColumn)
        }
        return cellView
    }
}
