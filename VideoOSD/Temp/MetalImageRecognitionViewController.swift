//
//  MetalImageRecognitionViewController.swift
//  iOS-10-Sampler
//
//  Created by Shuichi Tsutsumi on 9/9/16.
//  Copyright © 2016 Shuichi Tsutsumi. All rights reserved.
//
//  This class is based on Apple's sample named "MetalImageRecognition"

import UIKit
import Accelerate
import AVFoundation

class MetalImageRecognitionViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private var ciContext : CIContext!
    private var sourceTexture : MTLTexture? = nil
    
    private var videoCapture: VideoCapture!
    
    @IBOutlet private weak var predictLabel: UILabel!
    @IBOutlet private weak var previewView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let spec = VideoSpec(fps: 3, size: CGSize(width: 1280, height: 720))
        videoCapture = VideoCapture()
        videoCapture.setup(cameraType: .back,
                           preferredSpec: spec,
                           previewContainer: previewView.layer)
        videoCapture.imageBufferHandler = {[unowned self] (imageBuffer, timestamp, outputBuffer) in
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            guard let cgImage = self.ciContext.createCGImage(ciImage, from: ciImage.extent) else {return}
            
            
            // TODO: Fill
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let videoCapture = videoCapture else {return}
        videoCapture.startCapture()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let videoCapture = videoCapture else {return}
        videoCapture.resizePreview()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard let videoCapture = videoCapture else {return}
        videoCapture.stopCapture()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}
