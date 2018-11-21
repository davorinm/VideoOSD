//
//  FilterVideoController.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 23/08/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import UIKit
import GLKit

class VideoRecorderViewController: UIViewController {
    @IBOutlet weak var glImageView: GLKView!
    @IBOutlet weak var recordingButton: UIButton!
    
    private var videoRecorder: VideoBufferRecorder = VideoBufferRecorder()
    private var overlayView: OverlayView!
    private var refreshTimer: CancelableTimer?
    private var ciContext: CIContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup GLView
        let glContext = EAGLContext(api: .openGLES2)
        glImageView.context = glContext!
        EAGLContext.setCurrent(glContext)
        ciContext = CIContext(eaglContext: glImageView.context)
        
        // Recorder
        videoRecorder.displayImage = { image in
            self.glImageView.bindDrawable()
            self.ciContext.draw(image, in: image.extent, from: image.extent)
            self.glImageView.display()
        }
        
        // Setup OverlayView
        overlayView = OverlayView.createFromNib()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        // Setup Recorder
        // TODO: Combine createSession and startSession
        let result = videoRecorder.createSession()
        if case .initialized = result {
            //OK
        } else {
            self.showError("videoRecorder not initialized")
            return
        }
        
        videoRecorder.startSession()
        
        
        refreshTimer = CancelableTimer(timeInterval: 3, callback: { [unowned self] in
            var overlayViewFrame = self.overlayView.frame
            overlayViewFrame.size.width = self.videoRecorder.videoSize.width
            self.overlayView.frame = overlayViewFrame
            
            self.overlayView.update("\(arc4random_uniform(55))", "\(arc4random_uniform(55))")
            
            self.videoRecorder.overlayImage = self.overlayView.image()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        
        refreshTimer = nil

        videoRecorder.stopSession()
    }
    
    // MARK: - Actions
    
    @IBAction func startButtonPressed(_ sender: Any) {
        switch videoRecorder.status {
        case .unknown:
            break
        case .initialized:
            break
        case .sessionCreated:
            recordingButton.setTitle("STP", for: .normal)
            videoRecorder.startRecording()
        case .recording:
            recordingButton.setTitle("REC", for: .normal)
            videoRecorder.stopRecording { [unowned self] fileUrl in
                PhotoLibrary.moveToPhotos(url: fileUrl) { (saved, error) in
                    if saved {
                        self.showSaved()
                    } else {
                        if let error = error {
                            self.showError(error.localizedDescription)
                        } else {
                            self.showError("EEEEEE")
                        }
                    }
                }
            }
        case .error(_):
            self.showError("videoRecorder ERROR")
        }
    }
    
    // MARK: Orientation
    
    override var shouldAutorotate: Bool {
        get {
            // Prevent autorotate when recording
            return !videoRecorder.isRecording()
        }
    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        var videoOrientation = AVCaptureVideoOrientation.portrait
//
//        switch UIDevice.current.orientation {
//        case .unknown:
//            print("unknown")
//        case .portrait:
//            print("portrait")
//        case .portraitUpsideDown:
//            print("portraitUpsideDown")
//        case .landscapeLeft:
//            videoOrientation = .landscapeRight
//        case .landscapeRight:
//            videoOrientation = .landscapeLeft
//        case .faceUp:
//            print("faceUp")
//        case .faceDown:
//            print("faceDown")
//        }
//
//
////        // Video orientation
////        for rrr in captureSession.outputs {
////            for connection in rrr.connections {
////                if connection.isVideoOrientationSupported {
////                    connection.videoOrientation = videoOrientation
////                }
////            }
////        }
//    }
    
    // MARK: - Helpers
    
    private func showSaved() {
        let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func showError(_ error: String) {
        let alertController = UIAlertController(title: "ERROR", message: error, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
//    private func displayImage(from pixelBuffer: CVPixelBuffer) {
//        let cameraImage: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
//        let image = UIImage(ciImage: cameraImage)
//
//        DispatchQueue.main.async {
//            self.imageView.image = image
//        }
//    }
    
    
//draw(overlayImage: overlayImage!.cgImage!, in: CGRect(x: 0, y: 500, width: overlayImage!.size.width, height: overlayImage!.size.height), to: pixelBuffer)
//
//    // CPU Drawing
//    private func draw(overlayImage: CGImage, in rect: CGRect, to pixelBuffer: CVPixelBuffer) {
//        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//
//        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
//        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
//
//        let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
//                                width: CVPixelBufferGetWidth(pixelBuffer),
//                                height: CVPixelBufferGetHeight(pixelBuffer),
//                                bitsPerComponent: 8,
//                                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
//                                space: CGColorSpaceCreateDeviceRGB(),
//                                bitmapInfo: bitmapInfo)
//
//        context!.draw(overlayImage, in: rect)
//
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//    }
}
