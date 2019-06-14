//
//  DarkMode.swift
//  Auto Dark
//
//  Created by Sindre Sorhus.
//  Copyright © 2018 Sindre Sorhus. All rights reserved.
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

import Foundation

/// Handles Dark Mode toggling.
struct DarkMode {
    
    private static let prefix = "tell application \"System Events\" to tell appearance preferences to"
    
    /// Checks if Dark Mode is enabled.
    static var isEnabled: Bool {
        get {
            return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        }
        set {
            toggle(force: newValue)
        }
    }
    
    /**
     Toggles Dark Mode.
     
     - Parameters:
        - force: Force Dark Mode to be on or off.
    */
    static func toggle(force: Bool? = nil) {
        let value = force.map(String.init) ?? "not dark mode"
        let command = "\(prefix) set dark mode to \(value)"
        runAppleScript(command)
    }
    
}

/**
 Runs Apple Script.
 
 - Parameters:
    - sorce: The code to run.
 
 - Returns: The output of the script.
*/
@discardableResult
func runAppleScript(_ source: String) -> String {
    var outstr = ""
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", "osascript -e '\(source)'"]
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
