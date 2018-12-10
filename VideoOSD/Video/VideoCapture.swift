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
    private var videoConnection: AVCaptureConnection!
    private var audioConnection: AVCaptureConnection!
    private var assetWriter: AssetWriter!
    
    var isRecording: Bool {
        get {
            return assetWriter.isWriting
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
            let videoDeviceInput: AVCaptureDeviceInput
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            }
            catch {
                fatalError("Could not create AVCaptureDeviceInput instance with error: \(error).")
            }
            guard captureSession.canAddInput(videoDeviceInput) else {
                fatalError()
            }
            captureSession.addInput(videoDeviceInput)
        }
        
        // setup audio device input
        do {
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {fatalError()}
            let audioDeviceInput: AVCaptureDeviceInput
            do {
                audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            }
            catch {
                fatalError("Could not create AVCaptureDeviceInput instance with error: \(error).")
            }
            guard captureSession.canAddInput(audioDeviceInput) else {
                fatalError()
            }
            captureSession.addInput(audioDeviceInput)
        }
        
        // setup video output
        let videoDataOutput = AVCaptureVideoDataOutput()
        do {
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)]
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            let queue = DispatchQueue(label: "com.shu223.videosamplequeue")
            videoDataOutput.setSampleBufferDelegate(self, queue: queue)
            guard captureSession.canAddOutput(videoDataOutput) else {
                fatalError()
            }
            captureSession.addOutput(videoDataOutput)
            
            videoConnection = videoDataOutput.connection(with: .video)
        }
        
        // setup audio output
        let audioDataOutput = AVCaptureAudioDataOutput()
        do {
            let queue = DispatchQueue(label: "com.shu223.audiosamplequeue")
            audioDataOutput.setSampleBufferDelegate(self, queue: queue)
            guard captureSession.canAddOutput(audioDataOutput) else {
                fatalError()
            }
            captureSession.addOutput(audioDataOutput)
            
            audioConnection = audioDataOutput.connection(with: .audio)
        }
        
        // setup asset writer
        do {
            assetWriter = try AssetWriter(fileUrl: fileUrl)
        } catch let error {
            assertionFailure(error.localizedDescription)
        }
        
        self.captureSession = captureSession
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
        assetWriter.start()
    }
    
    func stopRecording(finished: @escaping (() -> Void)) {
        assetWriter.stop {
            finished()
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //        print("\(self.classForCoder)/" + #function)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Apply orientation
        if connection.videoOrientation != AVCaptureVideoOrientation.portrait {
            connection.videoOrientation = AVCaptureVideoOrientation.portrait
        }
        
        // Get PixelBuffer
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        // Draw overlay
        // TODO: todo
        
        // Append sample
        assetWriter.append()
        
        // Display Pixel Buffer
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let time: TimeInterval = CMTimeGetSeconds(timestamp)
        
        DispatchQueue.main.async {
            self.imageHandler?(image, time)
        }
    }
}
