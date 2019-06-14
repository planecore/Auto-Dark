//
//  Logger.swift
//  Auto Dark
//
//  Created by Matan Mashraki on 14/06/2019.
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

/// Handles the logging of messages to the console and to the log file.
struct Logger {
    
    /**
     Gets a message, prints it and appends it to the log.
     
     - Parameters:
     - message: The message to save.
     - withTime: Includes the time of the message if true.
     */
    static func log(_ message: String, withTime: Bool = true) {
        let save = withTime ? getTime() + " " + message : message
        print(save)
        appendToFile(save)
    }
    
    /// Copy the log file to the user Downloads folder and reveal it in Finder.
    static func shareLog() {
        let fm = FileManager.default
        let at = fm.temporaryDirectory.appendingPathComponent("log.txt")
        let to = fm.homeDirectoryForCurrentUser.appendingPathComponent("Downloads/log.txt")
        try? fm.removeItem(at: to)
        do {
            try fm.copyItem(at: at, to: to)
            NSWorkspace.shared.activateFileViewerSelecting([to])
        } catch {
            Logger.log("Couldn't copy log to user download folder")
        }
    }
    
    /**
     Appends a string to the log file.
     
     - Parameters:
     - string: The text to append.
     */
    private static func appendToFile(_ string: String) {
        let text = string + "\n"
        let data = text.data(using: .utf8)
        let fm = FileManager.default
        let path = fm.temporaryDirectory.appendingPathComponent("log.txt")
        if fm.fileExists(atPath: path.path) {
            if let handler = try? FileHandle(forUpdating: path) {
                handler.seekToEndOfFile()
                handler.write(data!)
                handler.closeFile()
            }
        } else {
            fm.createFile(atPath: path.path, contents: data!, attributes: nil)
        }
    }
    
    /**
     Get's the current time.
     
     - Returns: The current time in the format `H:mm:ss`.
     */
    private static func getTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H:mm:ss"
        return dateFormatter.string(from: Date())
    }
    
    /**
     Get's the current app version.
     
     - Returns: The current version in the format Version `VersionNumber` (`BuildNumber`).
     */
    static func getVersion() -> String {
        let verNum = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let buildNum = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        return "Version " + verNum + " (" + buildNum + ")"
    }
    
}
