//
//  VideoCaptureViewModel.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 02/12/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import Photos

class VideoCaptureViewModel {
    var isCapturing: Bool {
        get {
            return videoCapture.isRecording
        }
    }
    private let locationProvider: LocationProvider = LocationProviderImpl()
    
    private var filePath: URL!
    private let videoCapture: VideoCapture = VideoCapture()
    
    private var overlayView: OverlayView!
    
    var displayImage: ((_ image: CIImage, _ time: TimeInterval) -> Void)?
    var didStartCapturing: (() -> Void)?
    var didStopCapturing: (() -> Void)?
    var continueNewPreviewVideo: (() -> Void)?
    
    // MARK: - Public
    
    init() {
        // Create OverlayView
        overlayView = OverlayView.createFromNib()
        
        locationProvider.providerReponse.subscribe(self) { (response) in
            if let location = response.location {
                self.updateLocation(location: location)
            } else {
                assertionFailure("Location error \(response.error!)")
            }
        }
        
        videoCapture.imageHandler = { [unowned self] (image, time) in
            self.displayImage?(image, time)
        }
    }
    
    func load() {
        filePath = createFilePath()
        
        if checkIfExists() {
            continueNewPreviewVideo?()
            
            return
        }
        
        let spec = VideoSpec(fps: nil, size: CGSize(width: 1280, height: 720))
        videoCapture.setup(cameraType: CameraType.back, preferredSpec: spec, fileUrl: filePath)
    }
    
    func start() {
        videoCapture.startSession()
        locationProvider.startUpdatingLocation()
    }
    
    func stop() {
        videoCapture.stopSession()
        locationProvider.stopUpdatingLocation()
    }
    
    func startCapturing() {
        videoCapture.startRecording()
        didStartCapturing?()
    }
    
    func stopCapturing() {
        videoCapture.stopRecording { [unowned self] in
            PhotoLibrary.moveToPhotos(url: self.filePath) { [unowned self] (saved, asset, error) in
                self.removeFile()
                self.didStopCapturing?()
            }
        }
    }
    
    // MARK: - Location
    
    private func updateLocation(location: CLLocation) {
        var overlayViewFrame = self.overlayView.frame
        overlayViewFrame.size = CGSize(width: 1280, height: 720)
        self.overlayView.frame = overlayViewFrame
        
        overlayView.update("\(location.speed)", "\(location.course)")
        
        videoCapture.overlayImage = self.overlayView.image()
    }
    
    // MARK: - Helpers
    
    private func createFilePath() -> URL {
        // Path for output file
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("output.mov")
        
        return fileUrl
    }
    
    private func checkIfExists() -> Bool {
        // Check if file exists
        return FileManager.default.fileExists(atPath: self.filePath)
    }
    
    private func removeFile() {
        // Remove filr at path
        try? FileManager.default.removeItem(at: self.filePath)
    }
}
