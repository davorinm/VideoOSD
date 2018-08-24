////
////  UIVideoView.swift
////  ImpactWrapConsumer
////
////  Created by Davorin Mađarić on 11/01/2018.
////  Copyright © 2018 Inova. All rights reserved.
////
//
//import UIKit
//import AVFoundation
//
//enum UIVideoViewError: Error {
//    case deviceNotFound
//    case inputFailed
//    case outputFailed
//    case internalError(Error)
//}
//
//class UIVideoView: UIView, AVCaptureFileOutputRecordingDelegate {
//    
//    private var label: UILabel!
//    
//    private let captureSession = AVCaptureSession()
//    private let videoFileOutput = AVCaptureMovieFileOutput()
//    
//    
//    let videoOutput = AVCaptureVideoDataOutput()
//    
//    
//    private var previewLayer: AVCaptureVideoPreviewLayer?
//    
//    private var didStartRecording: ((URL) -> Void)?
//    private var didFinishRecording: ((URL, Error?) -> Void)?
//    
//    func createSession() -> UIVideoViewError? {
//        let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)!
//        
//        captureSession.sessionPreset = AVCaptureSession.Preset.medium
//
//        do {
//            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
//            
//            if captureSession.canAddInput(videoInput) {
//                captureSession.addInput(videoInput)
//            } else {
//                return .inputFailed
//            }
//            
//            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//            previewLayer!.frame = self.layer.bounds
//            previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
//            self.layer.addSublayer(previewLayer!)
//            
//            
//            if captureSession.canAddOutput(videoFileOutput) {
//                captureSession.addOutput(videoFileOutput)
//            }
//            
//            captureSession.startRunning()
//            
//            
//            return nil
//        } catch let error {
//            return .internalError(error)
//        }
//    }
//    
//    func startCapturing(to url: URL, completed: ((URL) -> Void)?, error: ((UIVideoViewError) -> Void)?) {
//       
//            
//            // Do recording and save the output to url
//            didStartRecording = completed
//            videoFileOutput.startRecording(to: url, recordingDelegate: self)
//        
//    }
//    
//    func stopCapturing(completed: ((URL, Error?) -> Void)?) {
//        didFinishRecording = completed
//        videoFileOutput.stopRecording()
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        
//        self.layer.sublayers?.forEach({ (subLayer) in
//            subLayer.frame = self.layer.bounds
//        })
//    }
//    
//    // MARK: - AVCaptureFileOutputRecordingDelegate
//    
//    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
//        didStartRecording?(fileURL)
//    }
//    
//    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
//        didFinishRecording?(outputFileURL, error)
//    }
//}
