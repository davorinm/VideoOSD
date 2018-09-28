//
//  VideoRecorder.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 27/09/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

enum VideoRecorderStatus {
    case initialized
    case sessionCreated
    case recording
}

enum VideoRecorderError: Error {
    case deviceNotFound
    case inputFailed
    case outputFailed
    case pathMissing
    case internalError(Error)
}

class VideoRecorder {
    private(set) var status: VideoRecorderStatus = .initialized
    
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
    
    var displayImage: ((_ image: CIImage) -> Void)?
    
    private var imgContext: CIContext!
    var overlayCIImage: CIImage?
    
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
}

private class VideoRecorderDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
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
