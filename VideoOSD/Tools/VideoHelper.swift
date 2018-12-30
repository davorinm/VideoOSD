//
//  PeripheralsAuthorization.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 30/12/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation
import AVFoundation

class VideoHelper {
    class func checkAuthorization(authorized: @escaping (() -> Void), denied: @escaping (() -> Void)) {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .notDetermined:
            VideoHelper.requestAuthorization(authorized: authorized, denied: denied)
        case .restricted:
            denied()
        case .denied:
            denied()
        case .authorized:
            authorized()
        }
    }
    
    class func requestAuthorization(authorized: @escaping (() -> Void), denied: @escaping (() -> Void)) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted) in
            if granted {
                authorized()
            } else {
                denied()
            }
        }
    }
}
