//
//  VideoCapture.swift
//
//  Created by Shuichi Tsutsumi on 4/3/16.
//  Copyright © 2016 Shuichi Tsutsumi. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class VideoCaptureDevice: NSObject, VideoCapture, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession!
    private var videoDevice: AVCaptureDevice!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var audioDataOutput: AVCaptureAudioDataOutput!
    private var videoConnection: AVCaptureConnection!
    
    private var assetWriter: AVAssetWriter!
    private var assetWriterInputVideo: AVAssetWriterInput!
    private var assetWriterInputAudio: AVAssetWriterInput!
    private var startSessionTime: CMTime?
    
    private var overlayImage: CGImage?
    private var overlayBuffer: CVPixelBuffer?
    
    var isRecording: Bool {
        get {
            return assetWriter?.status == .writing
        }
    }
    var videoDimensions: CGSize? {
        get {
            if let videoDevice = videoDevice {
                return videoDevice.dimensions()
            } else {
                return nil
            }
        }
    }
    var isBackCamera: Bool? {
        get {
            switch videoDevice.position {
            case .unspecified:
                return nil
            case .back:
                return true
            case .front:
                return false
            }
        }
    }
    var imageData: VideoCaptureImageData?
    var imageOrientation: CGImagePropertyOrientation = .up
    
    func setup(cameraType: CameraType, preferredSpec: VideoCaptureSpecs?) {
        // initialize session
        captureSession = AVCaptureSession()
        
        // setup video device input
        setupVideoDeviceInput(cameraType: cameraType, preferredSpec: preferredSpec)
        
        // setup audio device input
        do {
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                fatalError("Error finding audioDevice")
            }
            do {
                let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
                guard captureSession.canAddInput(audioDeviceInput) else {
                    fatalError("Error adding audioDeviceInput")
                }
                captureSession.addInput(audioDeviceInput)
            } catch let error {
                fatalError("Could not create AVCaptureDeviceInput instance with error: \(error).")
            }
        }
        
        // setup video output
        do {
            let queue = DispatchQueue(label: "videoDataOutputSampleQueue")
            videoDataOutput = AVCaptureVideoDataOutput()
            // TODO: Ckeck for performance for others formats
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
            // videoDataOutput.availableVideoPixelFormatTypes
            //        875704438  kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            //        875704422  kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            //        1111970369 kCVPixelFormatType_32BGRA
            
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: queue)
            guard captureSession.canAddOutput(videoDataOutput) else {
                fatalError("Error adding videoDataOutput")
            }
            captureSession.addOutput(videoDataOutput)
            videoConnection = videoDataOutput.connection(with: .video)
        }
        
        // setup audio output
        do {
            let queue = DispatchQueue(label: "audioDataOutputSampleQueue")
            audioDataOutput = AVCaptureAudioDataOutput()
            audioDataOutput.setSampleBufferDelegate(self, queue: queue)
            guard captureSession.canAddOutput(audioDataOutput) else {
                fatalError("Error adding audioDataOutput")
            }
            captureSession.addOutput(audioDataOutput)
        }
    }
    
    func setupVideoDeviceInput(cameraType: CameraType, preferredSpec: VideoCaptureSpecs?) {
        if captureSession == nil {
            assertionFailure("Call setup first")
        }
        
        // Input device
        videoDevice = cameraType.captureDevice()
        
        // setup video format
        do {
            if let preferredSpec = preferredSpec {
                captureSession.sessionPreset = AVCaptureSession.Preset.inputPriority
                videoDevice.updateFormatWithPreferredVideoSpec(preferredSpec: preferredSpec)
            } else {
                captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
            }
        }
        
        // setup video device input
        do {
            do {
                guard let videoDevice = videoDevice else {
                    fatalError("Error adding videoDeviceInput")
                }
                
                // Remove video inputs
                captureSession.inputs.forEach { (captureInput) in
                    if let captInp = captureInput as? AVCaptureDeviceInput, captInp.device.hasMediaType(.video) {
                        captureSession.removeInput(captureInput)
                    }
                }
                
                // Add input
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                guard captureSession.canAddInput(videoDeviceInput) else {
                    fatalError("Error adding videoDeviceInput")
                }
                captureSession.addInput(videoDeviceInput)
            } catch let error {
                fatalError("Could not create AVCaptureDeviceInput instance with error: \(error).")
            }
        }
    }
    
    private func createWriter(fileUrl: URL) {
        // setup asset writer
        do {
            assetWriter = try AVAssetWriter(outputURL: fileUrl, fileType: AVFileType.mov)
            
            let videoOutputSettings = videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: AVFileType.mov)
            
            assetWriterInputVideo = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
            assetWriterInputVideo.expectsMediaDataInRealTime = true
            assetWriter.add(assetWriterInputVideo)
            
            let audioOutputSettings = audioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: AVFileType.mov) as! [String : Any]
            
            assetWriterInputAudio = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
            assetWriterInputAudio.expectsMediaDataInRealTime = true
            assetWriter.add(assetWriterInputAudio)
        } catch let error {
            assertionFailure(error.localizedDescription)
        }
    }
    
    // MARK: - Controls
    
    func startSession() {
        if captureSession.isRunning {
            assertionFailure("Already running")
        }
        
        captureSession.startRunning()
    }
    
    func stopSession() {
        if !captureSession.isRunning {
            assertionFailure("Already stopped")
        }
        
        captureSession.stopRunning()
    }
    
    func startRecording(fileUrl: URL, completion: @escaping (() -> Void), error: @escaping ((Error?) -> Void)) {
        createWriter(fileUrl: fileUrl)
        
        if assetWriter.startWriting() {
            completion()
        } else {
            error(assetWriter.error)
        }
    }
    
    func stopRecording(completion: @escaping (() -> Void), error: @escaping ((Error?) -> Void)) {
        assetWriterInputVideo.markAsFinished()
        assetWriterInputAudio.markAsFinished()
        
        assetWriter.finishWriting { [unowned self] in
            switch self.assetWriter.status {
            case .unknown:
                assertionFailure("unknown?!?")
            case .writing:
                assertionFailure("writing?!?")
            case .completed:
                completion()
            case .failed:
                error(self.assetWriter.error)
            case .cancelled:
                assertionFailure("cancelled?!?")
            }
            
            // Cleanup
            self.startSessionTime = nil
            self.assetWriter = nil
        }
    }
    
    func setOverlay(image: UIImage) {
        self.overlayImage = image.cgImage
        
        // TODO: Check drawing to overlayBuffer
//        self.overlayBuffer = ImageProcessor.pixelBuffer(fromImage: image.cgImage!)
    }
    
    // MARK: - Video orientation
    
    func deviceOrientationDidChange(orientation: UIDeviceOrientation) {
        guard videoConnection.isVideoOrientationSupported else {
            assertionFailure("VideoOrientation not Supported")
            return
        }
        
        guard let isBackCamera = isBackCamera else {
            assertionFailure("Camera missing")
            return
        }
        
        switch orientation {
        case .landscapeLeft:
            videoConnection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            imageOrientation = .right
        case .landscapeRight:
            videoConnection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            imageOrientation = .left
        case .portraitUpsideDown:
            videoConnection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            imageOrientation = .down
        default:
            videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
            imageOrientation = .up
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print("didDrop sampleBuffer")
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Get timestamp
        let sessionTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        let assetWriterWriting: Bool = assetWriter?.status == .writing
        
        // Start session if needed
        if assetWriterWriting, startSessionTime == nil {
            startSessionTime = sessionTime
            assetWriter.startSession(atSourceTime: startSessionTime!)
        }
        
        if assetWriter != nil, assetWriter.status == .failed {
            print("Error occured status = \(assetWriter.status.rawValue), \(assetWriter.error!.localizedDescription)")
            return
        }
        
        // Check sample
        guard CMSampleBufferDataIsReady(sampleBuffer) else {
            print("CMSampleBufferDataIsReady not")
            return
        }
        
        // Append sample
        if output == videoDataOutput {
            // Get PixelBuffer
            let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            
            // Draw overlay
            if overlayImage != nil {
                ImageProcessor.draw(image: overlayImage!, toBuffer: pixelBuffer)
            } else if overlayBuffer != nil {
                ImageProcessor.draw(buffer: overlayBuffer!, toBuffer: pixelBuffer)
            }
            
            // Check assetWriter
            if assetWriterWriting {
                // Append video sample
                if assetWriterInputVideo.isReadyForMoreMediaData {
                    if assetWriterInputVideo.append(sampleBuffer) == false {
                        print("!!!!!AVAssetWriter error \(assetWriter.error!) \(assetWriter.status.rawValue)")
                    }
                } else {
                    print("NOT ReadyForMoreMediaData video")
                }
            }
            
            // Get timestamp
            let sessionTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            
            // Display Pixel Buffer
            let image = CIImage(cvPixelBuffer: pixelBuffer).oriented(imageOrientation)
            let timestamp = sessionTime - (startSessionTime ?? sessionTime)
            let time: TimeInterval = CMTimeGetSeconds(timestamp)
            self.imageData = VideoCaptureImageData(image: image, time: time)
        } else if output == audioDataOutput {
            // Check assetWriter
            if assetWriterWriting {
                // Append audio sample
                if assetWriterInputAudio.isReadyForMoreMediaData {
                    if assetWriterInputAudio.append(sampleBuffer) == false {
                        print("!!!!!AVAssetWriter error \(assetWriter.error!) \(assetWriter.status.rawValue)")
                    }
                } else {
                    print("NOT ReadyForMoreMediaData audio")
                }
            }
        }
    }
}
