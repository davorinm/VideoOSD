//
//  VideoCaptureViewModel.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 02/12/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation

class VideoCaptureViewModel {
    private(set) var isCapturing: Bool = false
    private let locationProvider: LocationProvider = LocationProviderImpl()
    private let videoCapture: VideoCapture = VideoCapture(
    
    var startCapturing: ((_ fileUrl: URL) -> Void)?
    var stopCapturing: (() -> Void)?
    
    // MARK: - Public
    
    init() {
        locationProvider.providerReponse.subscribe(self) { (response) in
            
            
            
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
        startCapturing?(filePath())
        locationProvider.startUpdatingLocation()
        
        isCapturing = true
    }
    
    private func stop() {
        stopCapturing?()
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
