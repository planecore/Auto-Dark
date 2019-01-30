//
//  LocationManager.swift
//  Auto Dark
//
//  Created by Matan Mashraki on 18/01/2019.
//  Copyright © 2019 Matan Mashraki. All rights reserved.
//

import Cocoa
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate, DarkManager {
    
    private var locationManager: CLLocationManager!
    var delegate: ViewControllerDelegate?
    var next: DarkDate?
    var pref: ScheduleMode
    var currentLocation: CLLocation?
    var stringLocation: String?
    
    init(pref: ScheduleMode) {
        self.pref = pref
        super.init()
        determineCurrentLocation()
    }
    
    func calculateNextDate() {
        if let loc = currentLocation {
            let solar = Solar(coordinate: loc.coordinate)!
            var nextRun: Date?
            var dark = false
            if solar.isDaytime {
                nextRun = solar.sunset
                dark = true
            } else {
                nextRun = Solar(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, coordinate: loc.coordinate)?.sunrise
            }
            next = DarkDate(date: nextRun, dark: dark)
            delegate?.updatedNextDate()
        }
    }
    
    func determineCurrentLocation() {
        if pref == .manual {
            setManualLocation()
        } else {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.requestLocation()
            if pref == .location, CLLocationManager.locationServicesEnabled() {
                locationManager.startUpdatingLocation()
            } else {
                let res = showAlert(title: "Location Services Aren't Available", subtitle: "Please turn on location services or set location manually.", button1: "I Enabled Location Services", button2: "Set Location Manually")
                if res == .alertFirstButtonReturn {
                    determineCurrentLocation()
                } else if res == .alertSecondButtonReturn {
                    pref = .manual
                    setManualLocation()
                } else {
                    NSApplication.shared.terminate(self)
                }
            }
        }
    }
    
    func setManualLocation() {
        if let location = UserDefaults.standard.string(forKey: "location") {
            stringLocation = location
            let geo = CLGeocoder()
            geo.geocodeAddressString(location) { (places, error) in
                if let place = places?.first?.location {
                    self.currentLocation = place
                    self.calculateNextDate()
                    self.delegate?.setLocationLabel(string: location)
                } else {
                    self.delegate?.setInformationLabel(string: "Can't calculate Dark Mode for your location.")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations[0]
        let geo = CLGeocoder()
        geo.reverseGeocodeLocation(currentLocation!) { (places, error) in
            if let place = places?.first {
                self.stringLocation = "\(place.locality!), \(place.country!)"
                self.delegate?.setLocationLabel(string: self.stringLocation!)
                self.calculateNextDate()
            } else {
                self.delegate?.setInformationLabel(string: "Can't calculate Dark Mode for your location.")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error Location: \(error)")
        self.delegate?.setInformationLabel(string: "Can't detect your location.")
    }
    
    func showAlert(title: String, subtitle: String, button1: String, button2: String?) -> NSApplication.ModalResponse {
        let msg = NSAlert()
        msg.addButton(withTitle: button1)
        if let b2 = button2 {
            msg.addButton(withTitle: b2)
        }
        msg.addButton(withTitle: "Cancel")
        msg.messageText = title
        msg.informativeText = subtitle
        return msg.runModal()
    }
    
}
