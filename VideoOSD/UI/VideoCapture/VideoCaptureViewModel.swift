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
    var isRecording: Bool {
        get {
            return videoCapture.isRecording
        }
    }
    var isBackCamera: Bool? {
        get {
            return videoCapture.isBackCamera
        }
    }
    
    private let locationProvider: LocationProvider = LocationProviderImpl()
    
    private var filePath: URL!
    private let videoCapture: VideoCapture = VideoCapture()
    
    private var overlayView: OverlayView!
    
    var displayImage: ((_ image: CIImage, _ time: TimeInterval) -> Void)?
    var didStartCapturing: ((_ error: Error?) -> Void)?
    var didEndCapturing: ((_ asset: PHAsset?, _ error: Error?) -> Void)?
    var previousVideoExists: (() -> Void)?
    
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
        createFilePath()
        
        if checkIfExists() {
            previousVideoExists?()
            removeFile()
        }
        
        // Setup videoCapture
//        let spec = VideoSpec(fps: nil, size: CGSize(width: 1280, height: 720))
        let spec = VideoSpec(fps: nil, size: nil)
        videoCapture.setup(cameraType: CameraType.back, preferredSpec: spec)
        
        // Initial orientation        
        videoCapture.changeOrientation(orientation: UIDevice.current.orientation)
        
        // Set frame for overlay view
        if let size = videoCapture.videoDimensions {
            let ratio = size.width / size.height
            let cS = CGSize(width: 512, height: 512 / ratio)
            
            var overlayViewFrame = self.overlayView.frame
            overlayViewFrame.size = cS
            self.overlayView.frame = overlayViewFrame
        } else {
            assertionFailure("Size is a must!!")
        }
    }
    
    func start() {
        videoCapture.startSession()
        locationProvider.startUpdatingLocation()
    }
    
    func stop() {
        videoCapture.stopSession()
        locationProvider.stopUpdatingLocation()
    }
    
    func startRecording() {
        videoCapture.startRecording(fileUrl: filePath, completion: { [unowned self] in
            self.didStartCapturing?(nil)
        }) { (error) in
            self.didStartCapturing?(error)
        }
    }
    
    func endRecording() {
        videoCapture.stopRecording(completion: { [unowned self] in
            PhotoLibrary.moveToPhotos(url: self.filePath) { [unowned self] (saved, asset, error) in
                DispatchQueue.main.async {
                    self.removeFile()
                    self.didEndCapturing?(asset, nil)
                }
            }
        }) { (error) in
            self.didEndCapturing?(nil, error)
        }
    }
    
    func useFrontCamera() {
        videoCapture.setupVideoDeviceInput(cameraType: CameraType.front, preferredSpec: nil)
        
        // Initial orientation
        videoCapture.changeOrientation(orientation: UIDevice.current.orientation)
    }
    
    func useBackCamera() {
        videoCapture.setupVideoDeviceInput(cameraType: CameraType.back, preferredSpec: nil)
        
        // Initial orientation
        videoCapture.changeOrientation(orientation: UIDevice.current.orientation)
    }
    
    func changeOrientation(orientation: UIDeviceOrientation) {
        videoCapture.changeOrientation(orientation: orientation)
    }
    
    // MARK: - Location
    
    private func updateLocation(location: CLLocation) {
        overlayView.update("\(location.speed)", "\(location.course)")        
        
        let img = self.overlayView.image()
        videoCapture.overlayImage = img
    }
    
    // MARK: - Helpers
    
    private func createFilePath() {
        // Path for output file
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("output.mov")
        
        self.filePath = fileUrl
    }
    
    private func checkIfExists() -> Bool {
        // Check if file exists
        return FileManager.default.fileExists(atPath: self.filePath.path)
    }
    
    private func removeFile() {
        // Remove file at path
        try? FileManager.default.removeItem(at: self.filePath)
    }
}
