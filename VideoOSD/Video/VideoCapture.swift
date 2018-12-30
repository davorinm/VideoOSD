//
//  VideoCapture.swift
//
//  Created by Shuichi Tsutsumi on 4/3/16.
//  Copyright © 2016 Shuichi Tsutsumi. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

struct VideoSpec {
    var fps: Int32?
    var size: CGSize?
}

struct ImageData {
    let image: CIImage
    let time: TimeInterval
}

class VideoCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
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
    var imageData: ImageData?
    
    func setup(cameraType: CameraType, preferredSpec: VideoSpec?) {
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
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)]
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
    
    func setupVideoDeviceInput(cameraType: CameraType, preferredSpec: VideoSpec?) {
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
                
                // Remove inputs
                captureSession.inputs.forEach({ captureSession.removeInput($0) })
                
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
            
            let outputSettings = videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: AVFileType.mov)
            
            assetWriterInputVideo = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
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
            // Start session
            let time = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 1000000)
            startSessionTime = time
            assetWriter.startSession(atSourceTime: time)
            
            completion()
        } else {
            error(assetWriter.error)
        }
    }
    
    func stopRecording(completion: @escaping (() -> Void), error: @escaping ((Error?) -> Void)) {
        let time = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 1000000)
        assetWriter.endSession(atSourceTime: time)
        
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
//        self.overlayBuffer = ImageProcessor.pixelBuffer(fromImage: image.cgImage!)
    }
    
    // MARK: - Video orientation
    
    func changeOrientation(orientation: UIDeviceOrientation) {
        // TODO: REMOVE, apply rotation on video
        guard videoConnection.isVideoOrientationSupported else {
            assertionFailure("VideoOrientation not Supported")
            return
        }
        
        guard let isBackCamera = isBackCamera else {
            assertionFailure("Camera missing")
            return
        }
        
        if isBackCamera {
            switch orientation {
            case .landscapeLeft:
                videoConnection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            case .landscapeRight:
                videoConnection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            case .portraitUpsideDown:
                videoConnection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            default:
                videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
            }
        } else {
            switch orientation {
            case .landscapeLeft:
                videoConnection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            case .landscapeRight:
                videoConnection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            case .portraitUpsideDown:
                videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
            default:
                videoConnection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            }
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("didDrop sampleBuffer")
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Get timestamp
        let sessionTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // Start session if needed
        if assetWriter != nil, assetWriter.status == .writing {
            // Start session
            if startSessionTime == nil {
                startSessionTime = sessionTime
                assetWriter.startSession(atSourceTime: startSessionTime!)
            }
        }
        
        if assetWriter != nil, assetWriter.status == .failed {
            print("Error occured status = \(assetWriter.status.rawValue), \(assetWriter.error!.localizedDescription)")
            return
        }
        
        if !CMSampleBufferDataIsReady(sampleBuffer) {
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
            if assetWriter != nil {
                if assetWriter.status == .writing {
                    // Append video sample
                    if assetWriterInputVideo.isReadyForMoreMediaData {
                        if assetWriterInputVideo.append(sampleBuffer) == false {
                            print("!!!!!AVAssetWriter error \(assetWriter.error!) \(assetWriter.status.rawValue)")
                        }
                    } else {
                        print("NOT ReadyForMoreMediaData video")
                    }
                } else {
                    print("not writing \(assetWriter.status.rawValue)")
                }
            }
            
            // Get timestamp
            let sessionTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            
            // Display Pixel Buffer
            let image = CIImage(cvPixelBuffer: pixelBuffer)
            let timestamp = sessionTime - (startSessionTime ?? sessionTime)
            let time: TimeInterval = CMTimeGetSeconds(timestamp)
            self.imageData = ImageData(image: image, time: time)
        } else if output == audioDataOutput {
            // Check assetWriter
            if assetWriter != nil {
                if assetWriter.status == .writing {
                    // Append audio sample
                    if assetWriterInputAudio.isReadyForMoreMediaData {
                        if assetWriterInputAudio.append(sampleBuffer) == false {
                            print("!!!!!AVAssetWriter error \(assetWriter.error!) \(assetWriter.status.rawValue)")
                        }
                    } else {
                        print("NOT ReadyForMoreMediaData audio")
                    }
                } else {
                    print("not writing \(assetWriter.status.rawValue)")
                }
            }
        }
    }
}
