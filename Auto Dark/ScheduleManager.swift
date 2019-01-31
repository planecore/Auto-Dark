//
//  ScheduleManager.swift
//  Auto Dark
//
//  Created by Matan Mashraki on 19/01/2019.
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
