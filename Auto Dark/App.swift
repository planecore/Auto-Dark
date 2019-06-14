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

/// `App` can check if an app is always light and it can also change its always light status.
class App {
    let bundle: String
    let name: String
    let image: NSImage
    
    /**
     Initializes `App` with an app bundle identifier.
     
     - Parameters:
        - bundle: The bundle identifier of the app.
    */
    init(bundle: String) {
        self.bundle = bundle
        let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: bundle)
        self.name = String(URL(fileURLWithPath: path!).lastPathComponent.split(separator: ".").first!)
        self.image = NSWorkspace.shared.icon(forFile: path!)
    }
    
    /**
     Checks the always light status of the `App`.
     
     - Returns: Returns `true` if always light mode is on.
    */
    func alwaysLightModeStatus() -> Bool {
        return getStatusFromDefaults() == "1\n"
    }
    
    /**
     Checks in the defaults the always light status of the `App`.
     
     - Returns:
        - `1\n` if it's always light
        - `0\n` if it's always dark
        - `The domain pair does not exist` if it's following the system appearance.
    */
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
    
    /**
     Sets the always light mode status for the `App`.
     
     - Parameters:
        - to: `true` to enable always light mode, `false` to disable.
    */
    func setAlwaysLightMode(to: Bool) {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = to ? ["write", bundle, "NSRequiresAquaSystemAppearance", "-bool", "YES"] : ["delete", bundle, "NSRequiresAquaSystemAppearance"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
    }

}
