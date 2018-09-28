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
    @IBOutlet weak var recordingButton: UIButton!
    
    private var captureSession: AVCaptureSession!
    
    private var assetWriter: AVAssetWriter!
    private var assetWriterInput: AVAssetWriterInput!
    
    private var fileUrl: URL!
    private var sessionAtSourceTime: CMTime?
    
    private var overlayView: OverlayView!
    private var overlayImage: UIImage?
    
    private var timer: CancelableTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup
        overlayView = UIView.createFromNib2(nibName: "OverlayView") as! OverlayView
        
        // Create session
        let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)!
        
        let deviceInput = try! AVCaptureDeviceInput(device: videoCaptureDevice)
        
        captureSession.beginConfiguration()
        
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)] as [String : Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        // videoDataOutput.availableVideoPixelFormatTypes
//        875704438.  kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
//        875704422.  kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
//        1111970369. kCVPixelFormatType_32BGRA
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        captureSession.commitConfiguration()
        
        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
        videoDataOutput.setSampleBufferDelegate(self, queue: queue)
        
        
        // Path for output file
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        fileUrl = paths[0].appendingPathComponent("output2.mov")
        
        // Remove old file
        try? FileManager.default.removeItem(at: fileUrl)
        
        //
        assetWriter = try! AVAssetWriter(outputURL: fileUrl, fileType: AVFileType.mov)
        
        //
        let outputSettings = videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: AVFileType.mov)
        
        //
        assetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        assetWriterInput.expectsMediaDataInRealTime = true
        
        //
        assetWriter.add(assetWriterInput)
        
        //
        assetWriter.startWriting()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        //
        captureSession.startRunning()
        
        timer = CancelableTimer(timeInterval: 3, callback: { [unowned self] in
            self.overlayView.firstLabel.text = "\(arc4random_uniform(55))"
            self.overlayView.secondLabel.text = "\(arc4random_uniform(55))"
            self.overlayView.thirdLabel.text = "\(arc4random_uniform(55))"
            self.overlayView.fourthLabel.text = "\(arc4random_uniform(55))"
            
            self.overlayImage = self.overlayView.image()
        })
    }
    
    // MARK: - Actions
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        captureSession.stopRunning()
        
        assetWriter.finishWriting { [unowned self] in
            PhotoLibrary.saveToPhotos(url: self.fileUrl, removeSourceFile: true) { (saved, error) in
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Draw
        if overlayImage != nil {
            draw(overlayImage: overlayImage!, to: sampleBuffer)
        }
        
        // Create preview image
        let image = createImageFromSampleBuffer(sampleBuffer: sampleBuffer)
        
        // Display preview image
        DispatchQueue.main.async {
            self.imageView.image = image
        }
        
        // Add buffer
        if assetWriter.status == .writing {
            if sessionAtSourceTime == nil {
                sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                assetWriter.startSession(atSourceTime: sessionAtSourceTime!)
            }
            
            if assetWriterInput.isReadyForMoreMediaData {
                if assetWriterInput.append(sampleBuffer) == false {
                    if assetWriter.status == .failed {
                        assertionFailure("AVAssetWriter error \(assetWriter.error!)")
                    }
                }
            } else {
                assertionFailure()
            }
            
        } else {
            assertionFailure()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("frame dropped")
    }
    
    // MARK: - Helpers
    
    private func createImageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage {
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let cameraImage: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let image = UIImage(ciImage: cameraImage)
        return image
    }
    
    private func draw(overlayImage: UIImage, to sampleBuffer: CMSampleBuffer) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
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
}
