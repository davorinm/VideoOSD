//
//  CancelableTimer.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 27/08/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation

final class CancelableTimer {
    private var timer: Timer?
    
    public init(timeInterval: TimeInterval, callback: @escaping (() -> Void)) {
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { (timer) in
            callback()
        }
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
}
