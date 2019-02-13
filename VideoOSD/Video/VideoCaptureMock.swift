//
//  VideoCaptureMock.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 13/02/2019.
//  Copyright © 2019 Davorin Madaric. All rights reserved.
//

import UIKit

class VideoCaptureMock: VideoCapture {
    // TODO: Implement, cleanup
    var isRecording: Bool = false
    
    var isBackCamera: Bool?
    
    var imageData: VideoCaptureImageData? {
        get {
            guard let image = UIImage(named: "camera") else {
                return nil
            }
            
            guard let ciImage = CIImage(image: image) else {
                return nil
            }
            
            return VideoCaptureImageData(image: ciImage, time: 8)
        }
    }
    
    var videoDimensions: CGSize? = CGSize(width: 100, height: 100)
    
    func startSession() {
        
    }
    
    func stopSession() {
        
    }
    
    func startRecording(fileUrl: URL, completion: @escaping (() -> Void), error: @escaping ((Error?) -> Void)) {
        
    }
    
    func stopRecording(completion: @escaping (() -> Void), error: @escaping ((Error?) -> Void)) {
        
    }
    
    func setupVideoDeviceInput(cameraType: CameraType, preferredSpec: VideoCaptureSpecs?) {
        
    }
    
    func deviceOrientationDidChange(orientation: UIDeviceOrientation) {
        
    }
    
    func setup(cameraType: CameraType, preferredSpec: VideoCaptureSpecs?) {
        
    }
    
    func setOverlay(image: UIImage) {
        // TODO: Implement
    }
    



}
