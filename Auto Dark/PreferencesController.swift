//
//  PreferencesController.swift
//  Auto Dark
//
//  Created by Matan Mashraki on 18/01/2019.
//  Copyright © 2019 Matan Mashraki. All rights reserved.
//

import Cocoa
import CoreLocation

protocol TypeLocationDelegate {
    func updateLocation(location: String)
}

class PreferencesController: NSViewController, TypeLocationDelegate {

    var delegate: ViewControllerDelegate?
    @IBOutlet weak var location: NSButton!
    @IBOutlet weak var autoLocation: NSButton!
    @IBOutlet weak var manualLocation: NSButton!
    @IBOutlet weak var typeLocation: NSButton!
    @IBOutlet weak var schedule: NSButton!
    @IBOutlet weak var sunrise: NSDatePicker!
    @IBOutlet weak var sunset: NSDatePicker!
    @IBOutlet weak var version: NSTextField!
    var sunrisePrev: Date?
    var sunsetPrev: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switch mode {
            case .location: location.setState(state: true); autoLocation.setState(state: true)
            case .manual: location.setState(state: true); manualLocation.setState(state: true)
            case .time: schedule.setState(state: true); autoLocation.setState(state: true)
        }
        if let location = UserDefaults.standard.string(forKey: "location") {
            typeLocation.title = location
        }
        typeLocation.sizeToFit()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H:mm"
        sunrise.dateValue = dateFormatter.date(from: UserDefaults.standard.string(forKey: "sunrise")!)!
        sunset.dateValue = dateFormatter.date(from: UserDefaults.standard.string(forKey: "sunset")!)!
        version.stringValue = "Version \(Bundle.main.infoDictionary!["CFBundleShortVersionString"]!) (\(Bundle.main.infoDictionary!["CFBundleVersion"]!))"
        sunrisePrev = sunrise.dateValue
        sunsetPrev = sunset.dateValue
        states()
    }
    
    func states() {
        autoLocation.isEnabled = location.state()
        manualLocation.isEnabled = location.state()
        typeLocation.isEnabled = manualLocation.state() && manualLocation.isEnabled
        sunrise.isEnabled = schedule.state()
        sunset.isEnabled = schedule.state()
        if location.state() {
            if autoLocation.state() { mode = .location }
            else if manualLocation.state() { mode = .manual }
        } else if schedule.state() { mode = .time }
        UserDefaults.standard.set(mode.rawValue, forKey: "mode")
        delegate?.setDarkManager()
    }
    
    @IBAction func locationCheck(_ sender: Any) {
        if location.state() {
            schedule.setState(state: !location.state())
        }
        states()
    }
    
    @IBAction func scheduleCheck(_ sender: Any) {
        if schedule.state() {
            location.setState(state: !schedule.state())
        }
        states()
    }
    
    @IBAction func autoCheck(_ sender: Any) {
        if autoLocation.state() {
            manualLocation.setState(state: !autoLocation.state())
        }
        states()
    }
    
    @IBAction func typeCheck(_ sender: Any) {
        if manualLocation.state() {
            autoLocation.setState(state: !manualLocation.state())
            if !UserDefaults.standard.contains(key: "location") {
                self.performSegue(withIdentifier: "typeLocation", sender: self)
            }
        }
        states()
    }
    
    @IBAction func sunriseCheck(_ sender: Any) {
        if sunrise.dateValue > sunset.dateValue {
            sunrise.dateValue = sunrisePrev!
            return
        }
        sunrisePrev = sunrise.dateValue
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H:mm"
        let str = dateFormatter.string(from: sunrise.dateValue)
        UserDefaults.standard.set(str, forKey: "sunrise")
        delegate?.setDarkManager()
    }
    
    @IBAction func sunsetCheck(_ sender: Any) {
        if sunrise.dateValue > sunset.dateValue {
            sunset.dateValue = sunsetPrev!
            return
        }
        sunsetPrev = sunset.dateValue
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H:mm"
        let str = dateFormatter.string(from: sunset.dateValue)
        UserDefaults.standard.set(str, forKey: "sunset")
        delegate?.setDarkManager()
    }
    
    @IBAction func websiteCheck(_ sender: Any) {
        let url = URL(string: "https://github.com/planecore/Auto-Dark")!
        NSWorkspace.shared.open(url)
    }
    
    func updateLocation(location: String) {
        UserDefaults.standard.set(location, forKey: "location")
        typeLocation.title = location
        typeLocation.sizeToFit()
        delegate?.setDarkManager()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "type-location" {
            let controller = segue.destinationController as! TypeLocationViewController
            controller.delegate = self
        }
        segue.perform()
    }
    
}

extension NSButton {
    func setState(state: Bool) {
        if state {
            self.state = .on
        } else {
            self.state = .off
        }
    }
    
    func state() -> Bool {
        return self.state == .on
    }
}

class TypeLocationViewController: NSViewController {
    
    var delegate: TypeLocationDelegate?
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var message: NSTextField!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var button: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let loc = UserDefaults.standard.string(forKey: "location") {
            textField.stringValue = loc
        }
    }
    
    @IBAction func done(_ sender: Any) {
        progress.startAnimation(self)
        let text = textField.stringValue
        let geo = CLGeocoder()
        geo.geocodeAddressString(text) { (places, error) in
            self.progress.stopAnimation(self)
            if error == nil {
                self.delegate?.updateLocation(location: text)
                self.dismiss(self)
            } else if error.debugDescription.contains("Domain=kCLErrorDomain Code=2") {
                self.message.stringValue = "No Internet"
            } else {
                self.message.stringValue = "Invalid Location"
            }
        }
    }
    
}
