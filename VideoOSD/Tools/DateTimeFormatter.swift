//
//  DateTimeFormatter.swift
//  VideoOSD
//
//  Created by Davorin Mađarić on 10/12/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation

class DateTimeFormatter {
    
    class func formatTime(time: TimeInterval) -> String {
        let decomposedTime = self.decomposeTime(time: time)
        
        let hours = decomposedTime.hours
        let minutes = decomposedTime.minutes
        let seconds = decomposedTime.seconds
        
        var timeString = ""
        if hours != 0 {
            timeString += hours < 10 ? "0\(hours):" : "\(hours):"
        }
        
        timeString += minutes < 10 ? "0\(minutes):" : "\(minutes):"
        timeString += seconds < 10 ? "0\(seconds)" : "\(seconds)"
        return timeString
    }
    
    class func decomposeTime(time: TimeInterval) -> (hours: Int, minutes: Int, seconds: Int, miliseconds: Int) {
        let hours = time / 3600
        let minutes = time.truncatingRemainder(dividingBy: 3600) / 60
        let seconds = time.truncatingRemainder(dividingBy: 3600).truncatingRemainder(dividingBy: 60)
        let miliseconds = time.truncatingRemainder(dividingBy: 3600).truncatingRemainder(dividingBy: 60).truncatingRemainder(dividingBy: 100)
        
        return (Int(hours), Int(minutes), Int(seconds), Int(miliseconds))
    }
}
