//
//  App.swift
//  Auto Dark
//
//  Created by Matan Mashraki on 10/06/2019.
//  Copyright © 2019 Matan Mashraki. All rights reserved.
//

import Cocoa

class App {
    let bundle: String
    let name: String
    let image: NSImage
    
    init(bundle: String) {
        self.bundle = bundle
        let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: bundle)
        self.name = String(URL(fileURLWithPath: path!).lastPathComponent.split(separator: ".").first!)
        self.image = NSWorkspace.shared.icon(forFile: path!)
    }
    
    func alwaysLightModeStatus() -> Bool {
        return getStatusFromDefaults() == "1\n"
    }
    
    @discardableResult
    private func getStatusFromDefaults() -> String {
        var outstr = ""
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", bundle, "NSRequiresAquaSystemAppearance"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            outstr = output as String
        }
        task.waitUntilExit()
        return outstr
    }
    
    func alwaysLightOn() {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["write", bundle, "NSRequiresAquaSystemAppearance", "-bool", "YES"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
    }
    
    func alwaysLightOff() {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["delete", bundle, "NSRequiresAquaSystemAppearance"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
    }
}
