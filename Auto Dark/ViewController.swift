//
//  ViewController.swift
//  Auto Dark
//
//  Created by Matan Mashraki on 18/11/2018.
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

enum ScheduleMode: String {
    case location = "Location", manual = "Manual", time = "Time"
}

struct DarkDate {
    var date: Date?
    var dark: Bool
}

protocol DarkManager {
    var delegate: ViewControllerDelegate? {get set}
    var next: DarkDate? {get}
    func calculateNextDate()
}

protocol ViewControllerDelegate {
    func updatedNextDate()
    func setLocationLabel(string: String)
    func setInformationLabel(string: String)
    func setDarkManager()
}

class ViewController: NSObject, ViewControllerDelegate {
    
    var darkManager: DarkManager?
    var first = true
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var locationLabel: NSMenuItem!
    @IBOutlet weak var informationLabel: NSMenuItem!
    @IBOutlet weak var preferences: NSMenuItem!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var timer: Timer?
    var date: DarkDate?
    
    override func awakeFromNib() {
        let icon = NSImage(named: "StatusIcon")
        icon?.isTemplate = true
        statusItem.button?.image = icon
        statusItem.menu = statusMenu
        setDarkManager()
    }
    
    func setDarkManager() {
        timer?.invalidate()
        if let manager = darkManager as? LocationManager, manager.locationManager != nil {
            manager.locationManager.stopMonitoringSignificantLocationChanges()
        }
        if let stringMode = UserDefaults.standard.string(forKey: "mode") {
            mode = ScheduleMode(rawValue: stringMode)!
        }
        first = true
        informationLabel.title = "Calculating..."
        locationLabel.title = "Auto Dark"
        if mode == .time {
            darkManager = ScheduleManager()
            darkManager?.delegate = self
            darkManager?.calculateNextDate()
        } else {
            darkManager = LocationManager(pref: mode)
            darkManager?.delegate = self
        }
        timer = Timer(fire: Date().addingTimeInterval(10), interval: 60, repeats: true) { t in
            if let date = self.date?.date, Date() > date {
                DarkMode.toggle(force: self.date!.dark)
                self.darkManager?.calculateNextDate()
            } else if self.date?.dark == DarkMode.isEnabled {
                DarkMode.toggle(force: !self.date!.dark)
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func updatedNextDate() {
        if let date = darkManager?.next {
            if first {
                first = false
                DarkMode.toggle(force: !date.dark)
            }
            self.date = date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "H:mm"
            self.informationLabel.title = (self.date!.dark ? "Sunset: " : "Sunrise: ") + dateFormatter.string(from: date.date!)
        } else {
            self.informationLabel.title = "Can't calculate Dark Mode for your location."
        }
    }
    
    func setLocationLabel(string: String) {
        locationLabel.title = string
    }
    
    func setInformationLabel(string: String) {
        informationLabel.title = string
    }
    
    @IBAction func openPreferences(sender: NSMenuItem) {
        if !NSApplication.shared.windows.contains { (window) -> Bool in
            window.title == "Auto Dark"
            } {
            let storyboard = NSStoryboard(name: "Preferences", bundle: nil)
            let windowController = storyboard.instantiateController(withIdentifier: "pref-window") as! NSWindowController
            let vc = windowController.contentViewController as! PreferencesController
            vc.delegate = self
            windowController.window?.level = .floating
            windowController.showWindow(self)
        }
    }
    
    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }

}
