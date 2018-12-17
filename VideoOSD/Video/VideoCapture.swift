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
    private var captureSession: AVCaptureSession = AVCaptureSession()
    private var videoDevice: AVCaptureDevice!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var audioDataOutput: AVCaptureAudioDataOutput!
    private var videoConnection: AVCaptureConnection!
    
    private var assetWriter: AVAssetWriter!
    private var assetWriterInputVideo: AVAssetWriterInput!
    private var assetWriterInputAudio: AVAssetWriterInput!
    private var startSessionTime: CMTime?
    
    var overlayImage: UIImage?
    
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
                return false
            case .front:
                return true
            }
        }
    }
    var imageHandler: ((_ image: CIImage, _ time: TimeInterval) -> Void)?
    
    func setup(cameraType: CameraType, preferredSpec: VideoSpec?) {
        // Input device
        videoDevice = cameraType.captureDevice()
        
        // setup video format
        do {
            captureSession.sessionPreset = AVCaptureSession.Preset.inputPriority
            if let preferredSpec = preferredSpec {
                // update the format with a preferred fps
                videoDevice?.updateFormatWithPreferredVideoSpec(preferredSpec: preferredSpec)
            }
        }
        
        // setup video device input
        do {
            do {
                guard let videoDevice = videoDevice else {
                    fatalError("Error adding videoDeviceInput")
                }
                
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
            videoDataOutput = AVCaptureVideoDataOutput()
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
            let queue = DispatchQueue(label: "com.shu223.audiosamplequeue")
            audioDataOutput = AVCaptureAudioDataOutput()
            audioDataOutput.setSampleBufferDelegate(self, queue: queue)
            guard captureSession.canAddOutput(audioDataOutput) else {
                fatalError("Error adding audioDataOutput")
            }
            captureSession.addOutput(audioDataOutput)
        }
    }
    
    private func createWriter(fileUrl: URL) {
        // Clanup
        startSessionTime = nil
        
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
        }
    }
    
    // MARK: - Video orientation
    
    func changeOrientation(orientation: UIDeviceOrientation) {
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
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if assetWriter != nil, assetWriter.status == .writing {
            print("didDrop sampleBuffer")
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Append sample
        if output == videoDataOutput {
            // Get PixelBuffer
            let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            
            // Draw overlay
            if overlayImage != nil {
                func write(image overlayImage: UIImage, toBuffer pixelBuffer: CVPixelBuffer) {
                    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
                    var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
                    bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue

                    let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                            width: CVPixelBufferGetWidth(pixelBuffer),
                                            height: CVPixelBufferGetHeight(pixelBuffer),
                                            bitsPerComponent: 8,
                                            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                            space: CGColorSpaceCreateDeviceRGB(),
                                            bitmapInfo: bitmapInfo)
                    
                    context!.draw(overlayImage.cgImage!, in: CGRect(x: 0.0, y: 0.0, width: overlayImage.size.width, height: overlayImage.size.height))
                    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
                }

                write(image: overlayImage!, toBuffer: pixelBuffer)
            }
            
            let sessionTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            
            if assetWriter != nil, assetWriter.status == .writing {
                // Start session
                if startSessionTime == nil {
                    startSessionTime = sessionTime
                    assetWriter.startSession(atSourceTime: startSessionTime!)
                }
                // Append video sample
                if assetWriterInputVideo.isReadyForMoreMediaData {
                    if assetWriterInputVideo.append(sampleBuffer) == false {
                        if assetWriter.status == .failed {
                            assertionFailure("AVAssetWriter error \(assetWriter.error!) \(assetWriter.status.rawValue)")
                        }
                    }
                } else {
                    print("NOT ReadyForMoreMediaData video")
                }
            }
            
            // Display Pixel Buffer
            let image = CIImage(cvPixelBuffer: pixelBuffer)
            let timestamp = sessionTime - (startSessionTime ?? sessionTime)
            let time: TimeInterval = CMTimeGetSeconds(timestamp)
            DispatchQueue.main.async {
                self.imageHandler?(image, time)
            }
        } else if output == audioDataOutput {
            if assetWriter != nil, assetWriter.status == .writing {
                // Start session
                if startSessionTime == nil {
                    startSessionTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    assetWriter.startSession(atSourceTime: startSessionTime!)
                }
                // Append audio sample
                if assetWriterInputAudio.isReadyForMoreMediaData {
                    if assetWriterInputAudio.append(sampleBuffer) == false {
                        if assetWriter.status == .failed {
                            assertionFailure("AVAssetWriter error \(assetWriter.error!)")
                        }
                    }
                } else {
                    print("NOT ReadyForMoreMediaData audio")
                }
            }
        }
    }
}
