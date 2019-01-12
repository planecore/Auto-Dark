//
//  ViewController.swift
//  Auto Dark
//
//  Created by Matan Mashraki on 18/11/2018.
//  Copyright © 2018 Matan Mashraki. All rights reserved.
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
import CoreLocation

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


class ViewController: NSObject {
    
    @IBOutlet weak var statusMenu: NSMenu!
    var currentLocation = UserDefaults.standard.string(forKey: "location")
    @IBOutlet weak var locationLabel: NSMenuItem!
    @IBOutlet weak var informationLabel: NSMenuItem!
    @IBOutlet weak var button: NSMenuItem!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var timer: Timer?
    var date: Date?
    
    override func awakeFromNib() {
        let icon = NSImage(named: "StatusIcon")
        icon?.isTemplate = true
        statusItem.button?.image = icon
        statusItem.menu = statusMenu
        if let loc = currentLocation {
            locationLabel.title = loc
        }
        timer = Timer(fire: Date().addingTimeInterval(10), interval: 60, repeats: true) { (t) in
            if let date = self.date, Date() > date || self.button.title == "Try Again" {
                self.getSunTimes()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
        getSunTimes()
    }
    
    @objc func getSunTimes() {
        informationLabel.title = "Calculating..."
        guard let address = currentLocation else {
            let getLocation = textBoxAlert(title: "Change Location", question: "What's the address?", defaultValue: "")
            if let loc = getLocation {
                UserDefaults.standard.set(loc, forKey: "location")
                locationLabel.title = loc
                currentLocation = loc
            }
            getSunTimes()
            return
        }
        self.locationLabel.title = address
        let geo = CLGeocoder()
        geo.geocodeAddressString(address) { (place, error) in
            if let place = place {
                if let coord = place.first?.location?.coordinate {
                    self.button.title = "Change Location"
                    print("Calculating for \(address)")
                    let solar = Solar(coordinate: coord)!
                    var nextRun: Date?
                    if solar.isDaytime {
                        print("Dark mode off")
                        DarkMode.toggle(force: false)
                        nextRun = solar.sunset
                    } else {
                        print("Dark mode on")
                        DarkMode.toggle(force: true)
                        nextRun = Solar(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, coordinate: coord)?.sunrise
                    }
                    if let next = nextRun {
                        self.date = next
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "H:mm"
                        self.informationLabel.title = (solar.isDaytime ? "Sunset: " : "Sunrise: ") + dateFormatter.string(from: next)
                    } else {
                        self.date = nil
                        self.informationLabel.title = "Can't calculate auto dark mode at your location."
                    }
                }
            } else if error.debugDescription.contains("Domain=kCLErrorDomain Code=2") {
                self.informationLabel.title = "Please check your internet connection."
                self.button.title = "Try Again"
            } else {
                let getLocation = self.textBoxAlert(title: "Invalid Location", question: "What's the address?", defaultValue: "")
                if let loc = getLocation {
                    UserDefaults.standard.set(loc, forKey: "location")
                    self.locationLabel.title = loc
                    self.currentLocation = loc
                }
                self.getSunTimes()
            }
        }
    }
    
    @IBAction func changeLocation(sender: NSMenuItem) {
        if sender.title == "Try Again" {
            getSunTimes()
        } else {
            let getLocation = textBoxAlert(title: "Change Location", question: "What's the address?", defaultValue: "")
            if let loc = getLocation {
                UserDefaults.standard.set(loc, forKey: "location")
                locationLabel.title = loc
                currentLocation = loc
                getSunTimes()
            }
        }
    }
    
    func textBoxAlert(title: String, question: String, defaultValue: String) -> String? {
        let msg = NSAlert()
        msg.addButton(withTitle: "OK")
        msg.addButton(withTitle: "Cancel")
        msg.messageText = title
        msg.informativeText = question
        
        let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 294, height: 24))
        txt.stringValue = defaultValue
        msg.accessoryView = txt
        let response: NSApplication.ModalResponse = msg.runModal()
        
        if (response == .alertFirstButtonReturn) {
            return txt.stringValue
        } else {
            if currentLocation != nil {
                return nil
            } else {
                NSApplication.shared.terminate(self)
                return nil
            }
        }
    }
    
    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }

}
