//
//  Date+Extentions.swift
//  ChatExample
//
//  Created by Sargis Gevorgyan on 4/16/20.
//  Copyright © 2020 MessageKit. All rights reserved.
//

import UIKit

extension Date {
    var hourMinWithDateTimeIndicator: String {
        let formater = DateFormatter()
        formater.dateFormat = "HH:mm"
        let hour = formater.string(from: self)
        return hour
    }
    
    func getPastTime(checkMaxDate: ((Int)-> Bool) = { _ in return true}) -> String {
        var secondsAgo = Int(Date().timeIntervalSince(self))
        if secondsAgo < 0 {
            secondsAgo = secondsAgo * (-1)
        }
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        
        let shoudEnter = checkMaxDate(secondsAgo)
        if secondsAgo < minute && shoudEnter {
            if secondsAgo < 2{
                return "title_just_now".localize()
            }else{
                let str = "title_secs_ago".localize()
                return str.replacingOccurrences(of: "XXX", with: "\(secondsAgo)")
            }
        } else if secondsAgo < hour && shoudEnter {
            let min = secondsAgo/minute
            if min == 1{
                let str = "title_min_ago".localize()
                return str.replacingOccurrences(of: "XXX", with: "\(min)")
            } else {
                let str = "title_mins_ago".localize()
                return str.replacingOccurrences(of: "XXX", with: "\(min)")
            }
        } else if secondsAgo < day && shoudEnter {
            let hr = secondsAgo/hour
            if hr == 1{
                let str = "title_hour_ago".localize()
                return str.replacingOccurrences(of: "XXX", with: "\(hr)")
            } else {
                let str = "title_hours_ago".localize()
                return str.replacingOccurrences(of: "XXX", with: "\(hr)")
            }
        } else if secondsAgo < week && shoudEnter {
            let day = secondsAgo/day
            if day == 1{
                let str = "title_day_ago".localize()
                return str.replacingOccurrences(of: "XXX", with: "\(day)")
                
            }else{
                let str = "title_days_ago".localize()
                return str.replacingOccurrences(of: "XXX", with: "\(day)")
            }
        } else {
            
            return getRelativeDateTodayChecked()
            
//
//            let formatter = DateFormatter()
//            formatter.dateFormat = "MMMM dd, HH:MM"
//            formatter.locale = Locale(identifier: Bundle.currentLanguage().identifier)
//            let strDate: String = formatter.string(from: self)
//            return strDate.capitalized
        }
    }
    
    func getRelativeDateTodayChecked() -> String {
        
        var secondsAgo = Int(Date().timeIntervalSince(self))
        if secondsAgo < 0 {
            secondsAgo = secondsAgo * (-1)
        }
        if isToday() {
            let str = "Today".localize()
            return str
        }
        //Yesterday
        if subtractingDays(1).isToday() {
            let str = "Yesterday".localize()
            return str
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd"
        formatter.locale = Locale(identifier: Bundle.currentLanguage().identifier)
        let strDate: String = formatter.string(from: self)
        return strDate.capitalized
    }
}
