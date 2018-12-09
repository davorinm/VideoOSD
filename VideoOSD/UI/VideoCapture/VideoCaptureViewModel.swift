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
    
    var displayImage: ((_ image: CIImage) -> Void)?
    var didStopCapturing: ((_ fileUrl: URL) -> Void)?
    
    // MARK: - Public
    
    init() {
        locationProvider.providerReponse.subscribe(self) { (response) in
            
            
            
        }
        
        let spec = VideoSpec(fps: 3, size: CGSize(width: 1280, height: 720))
        videoCapture.setup(cameraType: .back,
                           preferredSpec: spec,
                           previewContainer: previewView.layer)
        
        videoCapture.imageBufferHandler = {
            
        }
    }
    
    func load() {
        
    }
    
    func toggleCapturing() {
        if isCapturing {
            stop()
        } else {
            start()
        }
    }
    
    // MARK: - Internal
    
    private func start() {
        locationProvider.startUpdatingLocation()
        isCapturing = true
    }
    
    private func stop() {
        locationProvider.stopUpdatingLocation()
        isCapturing = false
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
