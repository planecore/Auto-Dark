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
    @IBOutlet weak var alwaysLightMenu: NSMenu!
    var timer: Timer?
    var date: DarkDate?
    
    override func awakeFromNib() {
        let icon = NSImage(named: "StatusIcon")
        icon?.isTemplate = true
        statusItem.button?.image = icon
        statusItem.menu = statusMenu
        setDarkManager()
        setAlwaysLightMenu()
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: OperationQueue.main) { notification in
            self.setAlwaysLightMenu()
        }
    }
    
    func setDarkManager() {
        timer?.invalidate()
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
    
    @discardableResult
    func getOpenedApps() -> [App] {
        let path = Bundle.main.path(forResource: "GetBundleIDs", ofType: "scpt")!
        var outstr = ""
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = [path]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            outstr = (output as String).replacingOccurrences(of: "\n", with: "")
        }
        task.waitUntilExit()
        var apps = [App]()
        for item in outstr.split(separator: " ").joined().split(separator: ",") {
            if item != "com.apple.Safari" && item != "com.apple.mail" {
                apps.append(App(bundle: String(item)))
            }
        }
        return apps
    }
    
    func setAlwaysLightMenu() {
        alwaysLightMenu.removeAllItems()
        let apps = getOpenedApps()
        for app in apps {
            let item = NSMenuItem(title: app.name, action: #selector(self.changeAlwaysLight), keyEquivalent: "")
            item.image = app.image
            item.isEnabled = true
            item.target = self
            item.toolTip = app.bundle
            if app.alwaysLightModeStatus() {
                item.state = .on
            } else {
                item.state = .off
            }
            alwaysLightMenu.addItem(item)
        }
    }
    
    @objc func changeAlwaysLight(_ sender: Any) {
        if let represented = sender as? NSMenuItem {
            print("selected \(represented.toolTip!)")
            let app = App(bundle: represented.toolTip!)
            if represented.state == .on {
                app.alwaysLightOff()
                represented.state = .off
            } else {
                app.alwaysLightOn()
                represented.state = .on
            }
            let msg = NSAlert()
            msg.addButton(withTitle: "OK")
            msg.messageText = "Please Reopen " + app.name
            msg.informativeText = "In order to change \(app.name) theme you must quit and reopen it."
            msg.runModal()
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
