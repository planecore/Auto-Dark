//
//  App.swift
//  Auto Dark
//
//  Created by Matan Mashraki on 10/06/2019.
//  Copyright © 2019 Matan Mashraki. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the “Software”), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
