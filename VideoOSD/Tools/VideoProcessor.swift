//
//  VideoProcessor.swift
//  VideoOSD
//
//  Created by Davorin Mađarić on 20/12/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class VideoProcessor {
    static let sepiaToneFilter = CIFilter(name: "CISepiaTone")!
    static let overCompositingFilter = CIFilter(name: "CISourceOverCompositing")!
    
    class func watermark(asset: AVAsset, watermarkImage: CIImage) {
        let videoComposition: AVMutableVideoComposition = AVMutableVideoComposition(asset: asset) { (request) in
            
            let source = request.sourceImage.clampedToExtent()
            overCompositingFilter.setValue(source, forKey: kCIInputImageKey)
            let output = overCompositingFilter.outputImage!.cropped(to: request.sourceImage.extent)
            request.finish(with: output, context: nil)
            
        }
        
//        videoComposition.renderSize = targetVideoSize
//        
//        videoComposition.frameDuration = CMTimeMake(1, 30)
//        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
//        
//        let url = AVAsset.tempMovieUrl
//        
//        let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
//        exporter?.outputURL = url
//        exporter?.outputFileType = AVFileTypeMPEG4
//        exporter?.shouldOptimizeForNetworkUse = true
//        exporter?.videoComposition = videoComp
//        
//        exporter?.exportAsynchronously
//            {
//                print( "Export completed" )
//        }
    }
}
