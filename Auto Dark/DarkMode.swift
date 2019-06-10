//
//  DarkMode.swift
//  Auto Dark
//
//  Created by Matan Mashraki on 10/06/2019.
//  Copyright © 2019 Matan Mashraki. All rights reserved.
//

import Foundation

struct DarkMode {
    private static let prefix = "tell application \"System Events\" to tell appearance preferences to"
    
    static var isEnabled: Bool {
        get {
            return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        }
        set {
            toggle(force: newValue)
        }
    }
    
    static func toggle(force: Bool? = nil) {
        let value = force.map(String.init) ?? "not dark mode"
        let command = "\(prefix) set dark mode to \(value)"
        runAppleScript(command)
    }
}

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
