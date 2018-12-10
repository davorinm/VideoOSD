//
//  VideoCaptureViewModel.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 02/12/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation
import UIKit

class VideoCaptureViewModel {
    private(set) var isCapturing: Bool = false
    private let locationProvider: LocationProvider = LocationProviderImpl()
    private let videoCapture: VideoCapture = VideoCapture()
    
    var displayImage: ((_ image: CIImage, _ time: TimeInterval) -> Void)?
    var didStopCapturing: ((_ fileUrl: URL) -> Void)?
    
    // MARK: - Public
    
    init() {
        locationProvider.providerReponse.subscribe(self) { (response) in
            
            
            
        }
        
        videoCapture.imageHandler = { [unowned self] (image, time) in
            self.displayImage?(image, time)
        }
    }
    
    func load() {
        let spec = VideoSpec(fps: 3, size: CGSize(width: 1280, height: 720))
        videoCapture.setup(cameraType: CameraType.back, preferredSpec: spec, fileUrl: filePath())
    }
    
    func start() {
        videoCapture.startSession()
        locationProvider.startUpdatingLocation()
    }
    
    func stop() {
        videoCapture.stopSession()
        locationProvider.stopUpdatingLocation()
    }
    
    func toggleCapturing() {
        if videoCapture.isRecording {
            videoCapture.stopRecording {
                print("stopped Recording")
            }
        } else {
            videoCapture.startRecording()
        }
    }
    
    // MARK: - Helpers
    
    private func filePath() -> URL {
        // Path for output file
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("output.mov")
        
        // Remove old file
        try? FileManager.default.removeItem(at: fileUrl)
        
        return fileUrl
    }
}
