//
//  VideoBufferRecorder.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 27/09/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

enum VideoRecorderState {
    case unknown
    case initialized
    case sessionCreated
    case recording
    case error(VideoRecorderError)
}

enum VideoRecorderError: Error {
    case deviceNotFound
    case inputFailed
    case outputFailed
    case pathMissing
    case internalError(Error)
}

class VideoBufferRecorder {
    private(set) var status: VideoRecorderState = .unknown
    
    private let captureSession: AVCaptureSession = AVCaptureSession()
    private let audioDataSampleDelegate: AudioDataSampleDelegate = AudioDataSampleDelegate()
    private let videoDataSampleDelegate: VideoDataSampleDelegate = VideoDataSampleDelegate()
    
    private let delegateQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
    
    private var fileUrl: URL!
    
    private var audioDataOutput: AVCaptureAudioDataOutput!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    
    private var assetWriterInputVideo: AVAssetWriterInput!
    private var assetWriterInputAudio: AVAssetWriterInput!
    private var assetWriter: AVAssetWriter!
    
    private var sessionAtSourceTime: CMTime?
    
    private(set) var videoSize: CGSize = CGSize(width: 1080, height: 1920)
    var displayImage: ((_ image: CIImage) -> Void)?
    
    private var imgContext: CIContext!
    var overlayImage: UIImage?
    
    init() {
        audioDataSampleDelegate.captureOutputDidOutput = { (output: AVCaptureOutput, sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection) in
            self.captureAudioOutput(output, didOutput: sampleBuffer, from: connection)
        }
        audioDataSampleDelegate.captureOutputDidDrop = { (output: AVCaptureOutput, sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection) in
            self.captureAudioOutput(output, didDrop: sampleBuffer, from: connection)
        }
        
        videoDataSampleDelegate.captureOutputDidOutput = { (output: AVCaptureOutput, sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection) in
            self.captureVideoOutput(output, didOutput: sampleBuffer, from: connection)
        }
        videoDataSampleDelegate.captureOutputDidDrop = { (output: AVCaptureOutput, sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection) in
            self.captureVideoOutput(output, didDrop: sampleBuffer, from: connection)
        }
        
        imgContext = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
    }
    
    func createSession() -> VideoRecorderState {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            return .error(.deviceNotFound)
        }

        guard let audioCaptureDevice = AVCaptureDevice.default(for: AVMediaType.audio) else {
            return .error(.deviceNotFound)
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                return .error(.inputFailed)
            }

            let audioInput = try AVCaptureDeviceInput(device: audioCaptureDevice)

            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            } else {
                return .error(.inputFailed)
            }
            
            
            
            //        videoCaptureDevice.formats
            //        videoCaptureDevice.activeFormat
            

            
            
            audioDataOutput = AVCaptureAudioDataOutput()
            audioDataOutput.setSampleBufferDelegate(audioDataSampleDelegate, queue: delegateQueue)
            
            if captureSession.canAddOutput(audioDataOutput) {
                captureSession.addOutput(audioDataOutput)
            } else {
                return .error(.outputFailed)
            }
            
            videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)] as [String : Any]
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(videoDataSampleDelegate, queue: delegateQueue)
            
            // videoDataOutput.availableVideoPixelFormatTypes
            //        875704438  kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            //        875704422  kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            //        1111970369 kCVPixelFormatType_32BGRA
            
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            } else {
                return .error(.outputFailed)
            }
            
            // Path for output file
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            guard let firstPath = paths.first else {
                return .error(.pathMissing)
            }
            
            fileUrl = firstPath.appendingPathComponent("output.mov")
            
            // Remove old file
            if FileManager.default.fileExists(atPath: fileUrl.absoluteString) {
                try FileManager.default.removeItem(at: fileUrl)
            }
            
            //
            assetWriter = try AVAssetWriter(outputURL: fileUrl, fileType: AVFileType.mov)
            
            
            //
            let outputSettings = videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: AVFileType.mov)
            
            
            //
            assetWriterInputVideo = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
            assetWriterInputVideo.expectsMediaDataInRealTime = true
            
            //
            assetWriter.add(assetWriterInputVideo)
            
            
            
            
            
            let audioOutputSettings = audioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: AVFileType.mov) as! [String : Any]
            
            
            //
            assetWriterInputAudio = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
            assetWriterInputAudio.expectsMediaDataInRealTime = true
            
            //
            assetWriter.add(assetWriterInputAudio)
            
            
            
            
            
            return .initialized
        } catch let error {
            return .error(.internalError(error))
        }
        
        
        
        // TODO: Apply orientation
        
        
        
        //        // Video orientation
        //        for connection in videoDataOutput.connections {
        //            if connection.isVideoOrientationSupported {
        //                connection.videoOrientation = AVCaptureVideoOrientation.portrait
        //            }
        //        }
    }
    
    func startSession() {
        // TODO: create captureSession queue
        DispatchQueue.global().async {
            self.captureSession.startRunning()
        }
    }
    
    func stopSession() {        
        // TODO: create captureSession queue
        DispatchQueue.global().async {
            self.captureSession.stopRunning()
        }
    }
    
    func startRecording() {
        assetWriter.startWriting()
        
        // Check settings for resolution
        //            videoDataOutput.videoSettings
    }
    
    func stopRecording(finished: @escaping ((_ fileUrl: URL) -> Void)) {
        assetWriter.finishWriting { [unowned self] in
            finished(self.fileUrl)
        }
    }
    
    func changeQuality() {
        //        captureSession.sessionPreset = AVCaptureSession.Preset.medium
        
        
        let preset = AVCaptureSession.Preset.hd1920x1080
        if captureSession.canSetSessionPreset(preset) {
            captureSession.sessionPreset = preset
        } else {
            captureSession.sessionPreset = AVCaptureSession.Preset.high
        }
    }
    
    func isRecording() -> Bool {
        if case .recording = status {
            return true
        }
        
        return false
    }
    
    // MARK: - Capture Audio Output
    
    private func captureAudioOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if assetWriterInputAudio.isReadyForMoreMediaData {
            if assetWriterInputAudio.append(sampleBuffer) == false {
                print("audio frame append failed")
            }
        } else {
            //assertionFailure()
        }
    }
    
    private func captureAudioOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("audio frame dropped")
    }
    
    // MARK: - Capture Video Output
    
    private func captureVideoOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Apply orientation
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        
        // Draw overlay
        
        
        
        
        if overlayImage != nil {
            let overlayCIImage = CIImage(cgImage: overlayImage!.cgImage!)
            
            imgContext.render(overlayCIImage,
                              to: pixelBuffer,
                              bounds: CGRect(x: 0, y: 0, width: 1080, height: 100),
                              colorSpace: nil)
        }
        
        // TODO:
        //        if connection.videoOrientation != .portrait {
        //
        //        }
        
        // Display Pixel Buffer
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        DispatchQueue.main.async {
            self.displayImage?(image)
        }
        
        // Append sample
        // TODO: Move all assetWriter stuff outside, only assetWriterInputVideo must remain, also for audio
        if assetWriter.status == .writing {
            if sessionAtSourceTime == nil {
                sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                assetWriter.startSession(atSourceTime: sessionAtSourceTime!)
            }
            
            if assetWriterInputVideo.isReadyForMoreMediaData {
                if assetWriter.status == .writing, assetWriterInputVideo.append(sampleBuffer) == false {
                    if assetWriter.status == .failed {
                        assertionFailure("AVAssetWriter error \(assetWriter.error!)")
                    }
                }
            } else {
                assertionFailure()
            }
        }
    }
    
    private func captureVideoOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("video frame dropped")
    }
}

private class AudioDataSampleDelegate: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    var captureOutputDidOutput: ((_ output: AVCaptureOutput, _ sampleBuffer: CMSampleBuffer, _ connection: AVCaptureConnection) -> Void)?
    var captureOutputDidDrop: ((_ output: AVCaptureOutput, _ sampleBuffer: CMSampleBuffer, _ connection: AVCaptureConnection) -> Void)?
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        captureOutputDidOutput?(output, sampleBuffer, connection)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        captureOutputDidDrop?(output, sampleBuffer, connection)
    }
}

private class VideoDataSampleDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureOutputDidOutput: ((_ output: AVCaptureOutput, _ sampleBuffer: CMSampleBuffer, _ connection: AVCaptureConnection) -> Void)?
    var captureOutputDidDrop: ((_ output: AVCaptureOutput, _ sampleBuffer: CMSampleBuffer, _ connection: AVCaptureConnection) -> Void)?
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        captureOutputDidOutput?(output, sampleBuffer, connection)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        captureOutputDidDrop?(output, sampleBuffer, connection)
    }
}
