////
////  Bababa.swift
////  VideoOSD
////
////  Created by Davorin Madaric on 19/08/2018.
////  Copyright © 2018 Davorin Madaric. All rights reserved.
////
//
//import Foundation
//
//
//import UIKit
//import AVFoundation
//
//class BabababViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
//    var captureSession = AVCaptureSession()
//    var sessionOutput = AVCapturePhotoOutput()
//    var movieOutput = AVCaptureMovieFileOutput()
//    var previewLayer = AVCaptureVideoPreviewLayer()
//    
//    @IBOutlet var cameraView: UIView!
//    
//    override func viewWillAppear(_ animated: Bool) {
//        self.cameraView = self.view
//        
//        AVCaptureDevice.DiscoverySession(deviceTypes: [], mediaType: AVMediaType.video, position: AVCaptureDevicePosition.front)
//        
//        let devices = AVCaptureDevice.default(for: AVMediaType.).devices(for: AVMediaType.video)
//        for device in devices! {
//            if (device as AnyObject).position == AVCaptureDevicePosition.front{
//                let audioInputDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
//                
//                do
//                {
//                    let audioInput = try AVCaptureDeviceInput(device: audioInputDevice)
//                    
//                    // Add Audio Input
//                    if captureSession.canAddInput(audioInput)
//                    {
//                        captureSession.addInput(audioInput)
//                    }
//                    else
//                    {
//                        NSLog("Can't Add Audio Input")
//                    }
//                }
//                catch let error
//                {
//                    NSLog("Error Getting Input Device: \(error)")
//                }
//                
//                do{
//                    
//                    let input = try AVCaptureDeviceInput(device: device as! AVCaptureDevice)
//                    
//                    if captureSession.canAddInput(input){
//                        
//                        captureSession.addInput(input)
//                        sessionOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
//                        
//                        if captureSession.canAddOutput(sessionOutput){
//                            
//                            captureSession.addOutput(sessionOutput)
//                            
//                            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//                            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
//                            previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.portrait
//                            cameraView.layer.addSublayer(previewLayer)
//                            
//                            previewLayer.position = CGPoint(x: self.cameraView.frame.width / 2, y: self.cameraView.frame.height / 2)
//                            previewLayer.bounds = cameraView.frame
//                            
//                            
//                        }
//                        
//                        captureSession.addOutput(movieOutput)
//                        
//                        captureSession.startRunning()
//                        
//                        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//                        let fileUrl = paths[0].appendingPathComponent("output.mov")
//                        try? FileManager.default.removeItem(at: fileUrl)
//                        movieOutput.startRecording(toOutputFileURL: fileUrl, recordingDelegate: self)
//                        
//                        let delayTime = DispatchTime.now() + 5
//                        DispatchQueue.main.asyncAfter(deadline: delayTime) {
//                            print("stopping")
//                            self.movieOutput.stopRecording()
//                        }
//                    }
//                    
//                }
//                catch{
//                    
//                    print("Error")
//                }
//            }
//        }
//    }
//}
