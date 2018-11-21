//
//  VideoCaptureView.swift
//  ImpactWrapConsumer
//
//  Created by Davorin Mađarić on 11/01/2018.
//  Copyright © 2018 Inova. All rights reserved.
//

import UIKit
import AVFoundation

enum VideoCaptureError: Error {
    case deviceNotFound
    case inputFailed
    case outputFailed
    case internalError(Error)
}

class VideoCaptureView: UIView, AVCaptureFileOutputRecordingDelegate {
    private let captureSession = AVCaptureSession()
    private let videoFileOutput = AVCaptureMovieFileOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var didStartRecording: ((URL) -> Void)?
    private var didFinishRecording: ((URL, Error?) -> Void)?
    
    func createSession() -> VideoCaptureError? {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            return .deviceNotFound
        }
        
        guard let audioCaptureDevice = AVCaptureDevice.default(for: AVMediaType.audio) else {
            return .deviceNotFound
        }
        
        captureSession.sessionPreset = AVCaptureSession.Preset.medium

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                return .inputFailed
            }
            
            let audioInput = try AVCaptureDeviceInput(device: audioCaptureDevice)
            
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            } else {
                return .inputFailed
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer!.frame = self.layer.bounds
            previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.layer.addSublayer(previewLayer!)
            
            captureSession.startRunning()
            return nil
        } catch let error {
            return .internalError(error)
        }
    }
    
    func startCapturing(to url: URL, completed: ((URL) -> Void)?, error: ((VideoCaptureError) -> Void)?) {
        if captureSession.canAddOutput(videoFileOutput) {
            captureSession.addOutput(videoFileOutput)
            
            // Do recording and save the output to url
            didStartRecording = completed
            videoFileOutput.startRecording(to: url, recordingDelegate: self)
        } else {
            error?(.outputFailed)
        }
    }
    
    func stopCapturing(completed: ((URL, Error?) -> Void)?) {
        didFinishRecording = completed
        videoFileOutput.stopRecording()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.sublayers?.forEach({ (subLayer) in
            subLayer.frame = self.layer.bounds
        })
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        didStartRecording?(fileURL)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        didFinishRecording?(outputFileURL, error)
    }
}
