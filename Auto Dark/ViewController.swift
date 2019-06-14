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

/**
 - `.location` for automatic location detection
 - `.manual` to type location manually
 - `.time` to set sunrise and sunset times manually
*/
enum ScheduleMode: String {
    case location = "Location", manual = "Manual", time = "Time"
}

/// Contains the next toggle date and the mode to toggle to.
struct DarkDate {
    var date: Date?
    var dark: Bool
}

protocol DarkManager {
    /// The `ViewController` delegate.
    var delegate: ViewControllerDelegate? {get set}
    /// The next date to toggle dark mode on/off.
    var next: DarkDate? {get}
    /// Tells the `DarkManager` to calculate the next date for dark mode.
    func calculateNextDate()
}

protocol ViewControllerDelegate {
    /// Updates the date to toggle dark mode at when the manager sent toggle time.
    func updatedNextDate()
    /**
     Updates the location label in Auto Dark menu bar.
     
     - Parameters:
        - string: The text to write to the label.
    */
    func setLocationLabel(string: String)
    /**
     Updates the informaion label in Auto Dark menu bar.
     
     - Parameters:
     - string: The text to write to the label.
     */
    func setInformationLabel(string: String)
    /// Removes the old manager if needed and creates a new manager to toggle dark mode.
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
        Logger.log(Logger.getVersion(), withTime: false)
        Logger.log("System at start dark mode enabled: \(DarkMode.isEnabled)")
        setDarkManager()
        setAlwaysLightMenu()
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: OperationQueue.main) { notification in
            self.setAlwaysLightMenu()
        }
    }
    
    /// Removes the old manager if needed and creates a new manager to toggle dark mode.
    func setDarkManager() {
        timer?.invalidate()
        if let manager = darkManager as? LocationManager, manager.locationManager != nil {
            manager.locationManager.delegate = nil
        }
        if let stringMode = UserDefaults.standard.string(forKey: "mode") {
            mode = ScheduleMode(rawValue: stringMode)!
        }
        Logger.log("Setting up dark manager with mode \(mode)")
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
    
    /// Updates the date to toggle dark mode at when the manager sent toggle time.
    func updatedNextDate() {
        Logger.log("Dark manager sent next toggle time")
        if let date = darkManager?.next {
            if first {
                first = false
                DarkMode.toggle(force: !date.dark)
            }
            self.date = date
            Logger.log("Recieved next toggle: to \(self.date!.dark) at \(self.date!.date!)")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "H:mm"
            self.informationLabel.title = (self.date!.dark ? "Sunset: " : "Sunrise: ") + dateFormatter.string(from: date.date!)
        } else {
            Logger.log("Can't calculate toggle times")
            self.informationLabel.title = "Can't calculate Dark Mode for your location."
        }
    }
    
    /**
     Get all the visible opened apps.
     
     - Returns: Array of `App` with all the visible opened apps.
    */
    func getOpenedApps() -> [App] {
        let running = NSWorkspace.shared.runningApplications.filter({$0.activationPolicy == .regular})
        var apps = [App]()
        for item in running {
            if let bundle = item.bundleIdentifier {
                // It's not possible to set Safari and Mail to be always light.
                if bundle != "com.apple.Safari" && bundle != "com.apple.mail" {
                    apps.append(App(bundle: bundle))
                }
            }
        }
        return apps
    }
    
    /// Shows all open apps in the Auto Dark menu with their always light status.
    func setAlwaysLightMenu() {
        let apps = getOpenedApps()
        var items = [NSMenuItem]()
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
            items.append(item)
        }
        alwaysLightMenu.items = items
    }
    
    /**
     Updates always light status for an app.
     
     - Parameters:
        - sender: The `NSMenuItem` that represents the app to update.
    */
    @objc func changeAlwaysLight(_ sender: Any) {
        if let represented = sender as? NSMenuItem {
            Logger.log("changed always light mode for \(represented.toolTip!)")
            let app = App(bundle: represented.toolTip!)
            if represented.state == .on {
                app.setAlwaysLightMode(to: false)
                represented.state = .off
            } else {
                app.setAlwaysLightMode(to: true)
                represented.state = .on
            }
            if NSWorkspace.shared.runningApplications.contains(where: { nsapp -> Bool in
                nsapp.bundleIdentifier == app.bundle
            }) {
                let msg = NSAlert()
                msg.addButton(withTitle: "OK")
                msg.messageText = "Relaunch " + app.name + " In Order To Take Effects"
                msg.informativeText = "In order to change \(app.name) appearance you must quit and reopen it."
                msg.runModal()
            }
        }
    }
    
    /**
     Updates the location label in Auto Dark menu bar.
     
     - Parameters:
     - string: The text to write to the label.
     */
    func setLocationLabel(string: String) {
        locationLabel.title = string
    }
    
    /**
     Updates the information label in Auto Dark menu bar.
     
     - Parameters:
     - string: The text to write to the label.
     */
    func setInformationLabel(string: String) {
        informationLabel.title = string
    }
    
    /// Open Auto Dark preferences.
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
