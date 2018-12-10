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
    var didStopCapturing: ((_ fileUrl: URL) -> Void)?
    
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
    }
    
    func stopCapturing(completition: @escaping ((_ sucess: Bool, _ error: Error?) -> ())) {
        videoCapture.stopRecording { [unowned self] in
            PhotoLibrary.moveToPhotos(url: self.filePath) { (saved, error) in
                if saved {
                    completition(true, nil)
                } else {
                    completition(false, error)
                }
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
        
        // Remove old file
        try? FileManager.default.removeItem(at: fileUrl)
        
        return fileUrl
    }
}
