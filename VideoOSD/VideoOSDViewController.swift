//
//  FilterVideoController.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 23/08/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import UIKit
import AVFoundation

class VideoOSDViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupCameraSession()
    }
    
    lazy var cameraSession: AVCaptureSession = {
        let s = AVCaptureSession()
        s.sessionPreset = AVCaptureSession.Preset.medium
        return s
    }()
    
    func setupCameraSession() {
        let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)!
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            cameraSession.beginConfiguration()
            
            if (cameraSession.canAddInput(deviceInput) == true) {
                cameraSession.addInput(deviceInput)
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)] as [String : Any]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if (cameraSession.canAddOutput(dataOutput) == true) {
                cameraSession.addOutput(dataOutput)
            }
            
            cameraSession.commitConfiguration()
            
            let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
            cameraSession.startRunning()
            
        } catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }
    }
    
    // MARK: - Actions
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let cameraImage: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let filteredImage = UIImage(ciImage: cameraImage)
        
        DispatchQueue.main.async {
            self.imageView.image = filteredImage
        }
        
        // TODO
        //AVAssetWriter
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("frame dropped")
    }
}
