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
    enum VideoCaptureViewModelError: Error {
        case video
        case photosDenied
    }
    
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
    private var displayLink: CADisplayLink!
    private var overlayView: OverlayView!
    
    var didLoad: (() -> Void)!
    var displayImage: ((_ image: CIImage, _ time: TimeInterval) -> Void)!
    var didStartCapturing: ((_ error: Error?) -> Void)!
    var didEndCapturing: ((_ asset: PHAsset?, _ error: Error?) -> Void)!
    var previousVideoExists: (() -> Void)?
    var showVideoPermissionsError: (() -> Void)!
    
    // MARK: - Public
    
    init() {
        // Create OverlayView
        overlayView = OverlayView.createFromNib()
        
        // Display link for refreshing video screen
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidRefresh))
        displayLink.add(to: .main, forMode: .common)
        
        // Provider response
        locationProvider.providerReponse.subscribe(self) { (response) in
            if let location = response.location {
                self.updateLocation(location: location)
            } else {
                assertionFailure("Location error \(response.error!)")
            }
        }
    }
    
    func load() {
        createFilePath()
        
        if checkIfExists() {
            previousVideoExists?()
            removeFile()
        }
        
        VideoHelper.checkAuthorization(authorized: { [unowned self] in
            self.setupCamera()
            self.didLoad()
        }, denied: { [unowned self] in
            self.showVideoPermissionsError()
        })
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
            self.didStartCapturing(nil)
        }) { (error) in
            self.didStartCapturing(error)
        }
    }
    
    func endRecording() {
        videoCapture.stopRecording(completion: { [unowned self] in
            self.moveToPhotos(finish: { [unowned self] (asset, error) in
                self.didEndCapturing(asset, error)
            })
            
        }) { (error) in
            self.didEndCapturing(nil, error)
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
    
    // MARK: - Camera
    
    private func setupCamera() {
        // TODO: Select format
//        let spec = VideoSpec(fps: nil, size: CGSize(width: 1280, height: 720))
        let spec = VideoSpec(fps: nil, size: nil)
        // TODO: With defined VideoSpec saving is erroneous
        videoCapture.setup(cameraType: CameraType.back, preferredSpec: nil)
        
        // Initial orientation
//        videoCapture.changeOrientation(orientation: UIDevice.current.orientation)
        
        // Set frame for overlay view
        if let size = videoCapture.videoDimensions {
            print("videoDimensions \(size)")
            
            let ratio = size.width / size.height
            let cS = CGSize(width: 512, height: 512 / ratio)
            
            var overlayViewFrame = self.overlayView.frame
            overlayViewFrame.size = cS
            self.overlayView.frame = overlayViewFrame
        } else {
            assertionFailure("Size is a must!!")
        }
    }
    
    // MARK: - Location
    
    private func updateLocation(location: CLLocation) {
        overlayView.update("\(location.speed)", "\(location.course)")        
        
        if let image = self.overlayView.image() {
            videoCapture.setOverlay(image: image)
        } else {
            assertionFailure("Image not created")
        }
    }
    
    // MARK: - DisplayLink
    
    @objc private func displayLinkDidRefresh() {
        if let imageData = self.videoCapture.imageData {
            let image = imageData.image
            let time = imageData.time
            
            self.displayImage(image, time)
        }
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
    
    private func moveToPhotos(finish: @escaping ((_ asset: PHAsset?, _ error: Error?) -> Void)) {
        PhotosHelper.checkAuthorization(authorized: { [unowned self] in
            PhotosHelper.moveToPhotos(url: self.filePath) { [unowned self] (saved, asset, error) in
                DispatchQueue.main.async {
                    if saved {
                        self.removeFile()
                    }
                    
                    finish(asset, error)
                }
            }
        }, denied: {
            finish(nil, VideoCaptureViewModelError.photosDenied)
        })
    }
}
