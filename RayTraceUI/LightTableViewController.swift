//
//  LightTableViewController.swift
//  RayTraceUI
//
//  Created by Neal Sidhwaney on 11/24/20.
//  Copyright © 2020 Neal Sidhwaney. All rights reserved.
//

import Foundation
import Cocoa

class LightViewController : NSViewController, NSTextFieldDelegate, NSTableViewDelegate {
    @objc dynamic var lights : [PointLight] = []
    let columnToProperty : [Int : String] = [:]
    var selectedLightNumber : Int!
    @IBOutlet var lightsArrayController: NSArrayController!
    @IBOutlet weak var lightTableView: NSTableView!

    let specularColId = "SPECULAR_COLUMN"
    let diffuseColId = "DIFFUSE_COLUMN"
    
    @IBAction func lightSelected(_ sender: Any) {
        selectedLightNumber = lightTableView.selectedRow
        let selectedLight = lights[lightTableView.selectedRow]
        lightXBox.stringValue = String(selectedLight.location.x)
        lightYBox.stringValue = String(selectedLight.location.y)
        lightZBox.stringValue = String(selectedLight.location.z)
        specularR.stringValue = String(selectedLight.specular.red)
        specularG.stringValue = String(selectedLight.specular.green)
        specularB.stringValue = String(selectedLight.specular.blue)
        diffuseR.stringValue = String(selectedLight.diffuse.red)
        diffuseG.stringValue = String(selectedLight.diffuse.green)
        diffuseB.stringValue = String(selectedLight.diffuse.blue)
    }
    

    @IBOutlet weak var lightXBox: NSTextField!
    @IBOutlet weak var lightYBox: NSTextField!
    @IBOutlet weak var lightZBox: NSTextField!
    
    @IBOutlet weak var specularR: NSTextField!
    @IBOutlet weak var specularG: NSTextField!
    @IBOutlet weak var specularB: NSTextField!

    @IBOutlet weak var diffuseR: NSTextField!
    @IBOutlet weak var diffuseG: NSTextField!
    @IBOutlet weak var diffuseB: NSTextField!
    
    func controlTextDidEndEditing(_ obj: Notification) {
        print("end editing")
        updateLightFromTextBox()
    }

    func updateLightFromTextBox() {
        if self.selectedLightNumber == nil || self.selectedLightNumber == -1 {
            return
        }
        let newLight = PointLight(atLocation: v3d(lightXBox.doubleValue,
                                                  lightYBox.doubleValue,
                                                  lightZBox.doubleValue),
                                  specular: RGB(specularR.doubleValue,
                                                specularG.doubleValue,
                                                specularB.doubleValue),
                                  diffuse: RGB(diffuseR.doubleValue,
                                               diffuseG.doubleValue,
                                               diffuseB.doubleValue))
        lights[self.selectedLightNumber] = newLight
        lightTableView.reloadData()
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tc = tableColumn else {
            return nil
        }
        let view = tableView.makeView(withIdentifier: tc.identifier, owner: lightTableView)!

        if view.layer == nil {
            view.layer = view.makeBackingLayer()
        }
        
        if tc.identifier.rawValue == specularColId || tc.identifier.rawValue == diffuseColId {
            var rgb : RGB!
            let light = self.lights[row]
            if tc.identifier.rawValue == specularColId {
                rgb = light.specular
            } else {
                rgb = light.diffuse
            }
            
            view.layer?.backgroundColor = CGColor.init(red: CGFloat(rgb.red), green: CGFloat(rgb.green), blue: CGFloat(rgb.blue), alpha: 1.0)
            view.layer?.cornerRadius = 5
        }

        return view
    }
}
