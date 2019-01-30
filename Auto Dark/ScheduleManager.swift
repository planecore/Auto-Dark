//
//  ScheduleManager.swift
//  Auto Dark
//
//  Created by Matan Mashraki on 19/01/2019.
//  Copyright © 2019 Matan Mashraki. All rights reserved.
//

import Foundation

class ScheduleManager: NSObject, DarkManager {
    
    var delegate: ViewControllerDelegate?
    var next: DarkDate?
    var sunriseString = UserDefaults.standard.string(forKey: "sunrise")!
    var sunsetString = UserDefaults.standard.string(forKey: "sunset")!
    
    func calculateNextDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd yyyy H:mm"
        let sunrise = dateFormatter.date(from: currentDate() + " " + sunriseString)!
        let sunset = dateFormatter.date(from: currentDate() + " " + sunsetString)!
        let date = Date()
        var nextRun: Date?
        var dark = false
        if date > sunrise && date < sunset {
            dark = true
            nextRun = sunset
        } else if date < sunrise {
            nextRun = sunrise
        } else if date > sunset {
            nextRun = Calendar.current.date(byAdding: .day, value: 1, to: sunrise)!
        }
        next = DarkDate(date: nextRun, dark: dark)
        delegate?.updatedNextDate()
    }
    
    func currentDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd yyyy"
        return dateFormatter.string(from: Date())
    }
    
}
