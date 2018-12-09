//
//  AssetWriter.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 09/12/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation
import AVFoundation

class AssetWriter {
    private var videoWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!

    
    
    init() {
        
        
        
        
        videoWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Constant.Configuration.DefaultAssetSize.width,
            kCVPixelBufferHeightKey as String: Constant.Configuration.DefaultAssetSize.height,
            kCVPixelFormatOpenGLESCompatibility as String: true,
            ])
    }
}
