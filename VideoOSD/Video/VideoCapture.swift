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

class VideoCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession?
    private var videoDevice: AVCaptureDevice!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var audioDataOutput: AVCaptureAudioDataOutput!
    
    private var assetWriter: AVAssetWriter!
    private var assetWriterInputVideo: AVAssetWriterInput!
    private var assetWriterInputAudio: AVAssetWriterInput!
    
    private var sessionAtSourceTime: CMTime?
    private var imgContext: CIContext!
    var overlayImage: UIImage?
    
    var isRecording: Bool {
        get {
            return assetWriter.status == .writing
        }
    }
    var imageHandler: ((_ image: CIImage, _ time: TimeInterval) -> Void)?
    
    func setup(cameraType: CameraType, preferredSpec: VideoSpec?, fileUrl: URL) {
        let captureSession = AVCaptureSession()
        
        videoDevice = cameraType.captureDevice()
        
        // setup video format
        do {
            captureSession.sessionPreset = AVCaptureSession.Preset.inputPriority
            if let preferredSpec = preferredSpec {
                // update the format with a preferred fps
                videoDevice.updateFormatWithPreferredVideoSpec(preferredSpec: preferredSpec)
            }
        }
        
        // setup video device input
        do {
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                guard captureSession.canAddInput(videoDeviceInput) else {
                    fatalError("Error adding videoDeviceInput")
                }
                captureSession.addInput(videoDeviceInput)
            } catch let error {
                fatalError("Could not create AVCaptureDeviceInput instance with error: \(error).")
            }
        }
        
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
            let queue = DispatchQueue(label: "com.shu223.videosamplequeue")
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)]
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: queue)
            guard captureSession.canAddOutput(videoDataOutput) else {
                fatalError("Error adding videoDataOutput")
            }
            captureSession.addOutput(videoDataOutput)
        }
        
        // setup audio output
        do {
            let queue = DispatchQueue(label: "com.shu223.audiosamplequeue")
            let audioDataOutput = AVCaptureAudioDataOutput()
            audioDataOutput.setSampleBufferDelegate(self, queue: queue)
            guard captureSession.canAddOutput(audioDataOutput) else {
                fatalError("Error adding audioDataOutput")
            }
            captureSession.addOutput(audioDataOutput)
        }
        
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
        
        // Set capture session
        self.captureSession = captureSession
        
        // Create image context
        self.imgContext = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
    }
    
    // MARK: - Controls
    
    func startSession() {
        guard let captureSession = self.captureSession else {
            assertionFailure("Run setup")
            return
        }
        
        if captureSession.isRunning {
            assertionFailure("Already running")
        }
        
        captureSession.startRunning()
    }
    
    func stopSession() {
        guard let captureSession = self.captureSession else {
            assertionFailure("Run setup")
            return
        }
        
        if !captureSession.isRunning {
            assertionFailure("Already stopped")
        }
        
        captureSession.stopRunning()
    }
    
    func startRecording() {
        assetWriter.startWriting()
    }
    
    func stopRecording(finished: @escaping (() -> Void)) {
        assetWriter.finishWriting {
            finished()
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("\(self.classForCoder)/" + #function)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Append sample
        if assetWriter.status == .writing {
            if sessionAtSourceTime == nil {
                sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                assetWriter.startSession(atSourceTime: sessionAtSourceTime!)
            }
            
            if output == videoDataOutput {
                videoDataHandler(sampleBuffer: sampleBuffer, connection: connection)
            } else if output == audioDataOutput {
                audioDataHandler(sampleBuffer: sampleBuffer)
            }
        }
    }
    
    // MARK: - AV Data handlers
    
    private func videoDataHandler(sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection) {
        // Apply orientation
        if connection.videoOrientation != AVCaptureVideoOrientation.portrait {
            connection.videoOrientation = AVCaptureVideoOrientation.portrait
        }
        
        // Get PixelBuffer
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        // Draw overlay
        if overlayImage != nil {
            let overlayCIImage = CIImage(cgImage: overlayImage!.cgImage!)
            
            imgContext.render(overlayCIImage,
                              to: pixelBuffer,
                              bounds: CGRect(x: 0, y: 0, width: 1080, height: 100),
                              colorSpace: nil)
        }
        
        // Display Pixel Buffer
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let time: TimeInterval = CMTimeGetSeconds(timestamp)
        
        DispatchQueue.main.async {
            self.imageHandler?(image, time)
        }
        
        // Append video sample
        if assetWriterInputVideo.isReadyForMoreMediaData {
            if assetWriterInputVideo.append(sampleBuffer) == false {
                if assetWriter.status == .failed {
                    assertionFailure("AVAssetWriter error \(assetWriter.error!)")
                }
            }
        }
    }
    
    private func audioDataHandler(sampleBuffer: CMSampleBuffer) {
        // Append audio sample
        if assetWriterInputAudio.isReadyForMoreMediaData {
            if assetWriterInputAudio.append(sampleBuffer) == false {
                if assetWriter.status == .failed {
                    assertionFailure("AVAssetWriter error \(assetWriter.error!)")
                }
            }
        }
    }
}
