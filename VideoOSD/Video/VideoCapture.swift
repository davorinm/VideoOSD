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
    private var captureSession: AVCaptureSession!
    private var videoDevice: AVCaptureDevice!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var audioDataOutput: AVCaptureAudioDataOutput!
    private var videoConnection: AVCaptureConnection!
    
    private var assetWriter: AVAssetWriter!
    private var assetWriterInputVideo: AVAssetWriterInput!
    private var assetWriterInputAudio: AVAssetWriterInput!
    private var startSessionTime: CMTime?
    
    var overlayBuffer: CVPixelBuffer?
    
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
    var imageHandler: ((_ image: CIImage, _ time: TimeInterval) -> Void)?
    
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
    
    func setupVideoDeviceInput(cameraType: CameraType, preferredSpec: VideoSpec?) {
        if captureSession == nil {
            assertionFailure("Call setup first")
        }
        
        // Input device
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
    
    func setOverlayImage(overlayImage: UIImage) {
        self.overlayBuffer = self.buffer(from: overlayImage)
    }
    
    private func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    // MARK: - Video orientation
    
    func changeOrientation(orientation: UIDeviceOrientation) {
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
            // TODO: Create CVPixelBuffer from overlayImage, merge overlayImagePixelBuffer in video pixel buffer to remove CGContext
            // Maybe use CVPixelBufferPool
            // CISourceOverCompositing https://stackoverflow.com/questions/48969223/core-image-filter-cisourceovercompositing-not-appearing-as-expected-with-alpha-o
            // https://stackoverflow.com/a/4057608
            // https://stackoverflow.com/questions/21753926/avfoundation-add-text-to-the-cmsamplebufferref-video-frame/21754725
            // https://stackoverflow.com/questions/46524830/how-do-i-draw-onto-a-cvpixelbufferref-that-is-planar-ycbcr-420f-yuv-nv12-not-rgb/46524831#46524831
            // https://stackoverflow.com/questions/30609241/render-dynamic-text-onto-cvpixelbufferref-while-recording-video
            
            //!!!! https://www.objc.io/issues/23-video/core-image-video/
            // https://gist.github.com/bgayman/6b27428ea48750e8306975c735bd517e
            // https://stackoverflow.com/questions/35603608/ios-overlay-two-images-with-alpha-offscreen
            
            //!!! https://developer.apple.com/library/archive/samplecode/AVCustomEdit/Introduction/Intro.html#//apple_ref/doc/uid/DTS40013411-Intro-DontLinkElementID_2
            
            // !!!!!!!!
            // https://willowtreeapps.com/ideas/how-to-apply-a-filter-to-a-video-stream-in-ios
            // !!!!!!!!
            
            //!!!!!!!! https://stackoverflow.com/questions/51922595/confusion-about-cicontext-opengl-and-metal-swift-does-cicontext-use-cpu-or-g
            
            if overlayBuffer != nil {
                
                CVPixelBufferLockBaseAddress( backImageBuffer,  kCVPixelBufferLock_ReadOnly );
                backImageFromSample = [CIImage imageWithCVPixelBuffer:backImageBuffer];
                [coreImageContext render:backImageFromSample toCVPixelBuffer:nextImageBuffer bounds:toRect colorSpace:rgbSpace];
                CVPixelBufferUnlockBaseAddress( backImageBuffer,  kCVPixelBufferLock_ReadOnly );
            
                
                let ttt = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!, options: [kCIContextWorkingColorSpace : NSNull()])
                ttt.render(<#T##image: CIImage##CIImage#>, toBitmap: <#T##UnsafeMutableRawPointer#>, rowBytes: <#T##Int#>, bounds: <#T##CGRect#>, format: <#T##CIFormat#>, colorSpace: <#T##CGColorSpace?#>)
                
                
//                func write(image overlayImage: UIImage, toBuffer pixelBuffer: CVPixelBuffer) {
//                    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//                    var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
//                    bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
//
//                    let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
//                                            width: CVPixelBufferGetWidth(pixelBuffer),
//                                            height: CVPixelBufferGetHeight(pixelBuffer),
//                                            bitsPerComponent: 8,
//                                            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
//                                            space: CGColorSpaceCreateDeviceRGB(),
//                                            bitmapInfo: bitmapInfo)
//
//                    context!.draw(overlayImage.cgImage!, in: CGRect(x: 0.0, y: 0.0, width: overlayImage.size.width, height: overlayImage.size.height))
//                    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//                }
//
//                write(image: overlayImage!, toBuffer: pixelBuffer)
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
