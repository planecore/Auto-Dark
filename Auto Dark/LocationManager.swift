//
//  LocationManager.swift
//  Auto Dark
//
//  Created by Matan Mashraki on 18/01/2019.
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
                self.delegate?.setInformationLabel(string: "Authorize Auto Dark to detect your location in System Preferences.")
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
                    self.presentError(error: error as? CLError)
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
                self.delegate?.setLocationLabel(string: "Auto Dark")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if currentLocation == nil {
            presentError(error: error as? CLError)
        }
    }
    
    func presentError(error: CLError?) {
        if let err = error {
            var message = ""
            switch err.code.rawValue {
            case 0, 2: message = "There's no internet connection."
            case 1: message = "Authorize Auto Dark to detect your location in System Preferences."
            default: message = "Auto Dark can't detect your location"
            }
            self.delegate?.setLocationLabel(string: "Auto Dark")
            self.delegate?.setInformationLabel(string: message)
        }
    }
    
}
