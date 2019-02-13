//
//  VideoCaptureDevice.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 13/02/2019.
//  Copyright © 2019 Davorin Madaric. All rights reserved.
//

import UIKit

struct VideoCaptureImageData {
    let image: CIImage
    let time: TimeInterval
}

protocol VideoCapture {
    // TODO: Cleanup
    var isRecording: Bool { get }
    var isBackCamera: Bool? { get }
    
    var imageData: VideoCaptureImageData? { get }
    
    var videoDimensions: CGSize? { get }
    
    func startSession()
    func stopSession()
    func startRecording(fileUrl: URL, completion: @escaping (() -> Void), error: @escaping ((Error?) -> Void))
    func stopRecording(completion: @escaping (() -> Void), error: @escaping ((Error?) -> Void))
    func setupVideoDeviceInput(cameraType: CameraType, preferredSpec: VideoCaptureSpecs?)
    func deviceOrientationDidChange(orientation: UIDeviceOrientation)
    func setup(cameraType: CameraType, preferredSpec: VideoCaptureSpecs?)
    func setOverlay(image: UIImage)
}
