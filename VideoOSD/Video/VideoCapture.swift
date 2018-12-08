//
//  VideoCapture.swift
//
//  Created by Shuichi Tsutsumi on 4/3/16.
//  Copyright © 2016 Shuichi Tsutsumi. All rights reserved.
//

import AVFoundation
import Foundation


struct VideoSpec {
    var fps: Int32?
    var size: CGSize?
}

typealias ImageBufferHandler = ((_ imageBuffer: CVPixelBuffer, _ timestamp: CMTime, _ outputBuffer: CVPixelBuffer?) -> ())

class VideoCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession?
    private var videoDevice: AVCaptureDevice!
    private var videoConnection: AVCaptureConnection!
    private var audioConnection: AVCaptureConnection!
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    var imageBufferHandler: ImageBufferHandler?
    
    func setup(cameraType: CameraType, preferredSpec: VideoSpec?, previewContainer: CALayer?) {
        let captureSession = AVCaptureSession()
        
        videoDevice = cameraType.captureDevice()
        
        // setup video format
        captureSession.sessionPreset = AVCaptureSession.Preset.inputPriority
        if let preferredSpec = preferredSpec {
            // update the format with a preferred fps
            videoDevice.updateFormatWithPreferredVideoSpec(preferredSpec: preferredSpec)
        }
        
        // setup video device input
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
        
        // setup preview
        if let previewContainer = previewContainer {
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = previewContainer.bounds
            previewLayer.contentsGravity = CALayerContentsGravity.resizeAspectFill
            previewLayer.videoGravity = .resizeAspectFill
            previewContainer.insertSublayer(previewLayer, at: 0)
            self.previewLayer = previewLayer
        }
        
        // setup video output
        do {
            let videoDataOutput = AVCaptureVideoDataOutput()
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
        do {
            let audioDataOutput = AVCaptureAudioDataOutput()
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
        }
        /*
         
         // Asset Writer
         self.assetWriterManager = [[TTMAssetWriterManager alloc] initWithVideoDataOutput:videoDataOutput
         audioDataOutput:audioDataOutput
         preferredSize:preferredSize
         mirrored:(cameraType == CameraTypeFront)];
         */
        
        self.captureSession = captureSession
    }
    
    func startCapture() {
        guard let captureSession = self.captureSession else {
            assertionFailure("Run setup")
            return
        }
        
        if captureSession.isRunning {
            assertionFailure("Already running")
        }
        
        captureSession.startRunning()
    }
    
    func stopCapture() {
        guard let captureSession = self.captureSession else {
            assertionFailure("Run setup")
            return
        }
        
        if !captureSession.isRunning {
            assertionFailure("Already stopped")
        }
        
        captureSession.stopRunning()
    }
    
    func resizePreview() {
        if let previewLayer = previewLayer {
            guard let superlayer = previewLayer.superlayer else {return}
            previewLayer.frame = superlayer.bounds
        }
    }
    
    // =========================================================================
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //        print("\(self.classForCoder)/" + #function)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // FIXME: temp
        if connection.videoOrientation != .portrait {
            connection.videoOrientation = .portrait
            return
        }
        
        if let imageBufferHandler = imageBufferHandler, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) , connection == videoConnection
        {
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            imageBufferHandler(imageBuffer, timestamp, nil)
        }
    }
}
