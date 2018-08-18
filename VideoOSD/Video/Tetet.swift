//
//  Tetet.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 18/08/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation


class trt {
    
    
    
    func applyVideoEffects(to composition: AVMutableVideoComposition, size: CGSize, currentLabel: UILabel) {
        
        let overlayLayer = CALayer()
        var overlayImage: UIImage? = nil
        overlayImage = UIImage.createTransparentImageFrom(label: currentLabel, imageSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width))
        overlayLayer.contents = overlayImage?.cgImage
        overlayLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        overlayLayer.masksToBounds = true
        
        
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        videoLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)
        // 3 - apply magic
        composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
    }
    
    func videoOutput(videoAsset: AVAsset, label: UILabel) {
        
        // Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()
        
        // Video track
        let videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try videoTrack.insertTimeRange(CMTimeRange(start: kCMTimeZero, duration: videoAsset.duration), of: videoAsset.tracks(withMediaType: AVMediaTypeVideo)[0], at: kCMTimeZero)
        } catch {
            print("Error selecting video track !!")
        }
        
        // Create AVMutableVideoCompositionInstruction
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: kCMTimeZero, duration: videoAsset.duration)
        
        // Create an AvmutableVideoCompositionLayerInstruction for the video track and fix orientation
        
        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTrack)
        let videoAssetTrack = videoAsset.tracks(withMediaType: AVMediaTypeVideo)[0]
        var videoAssetOrientation = UIImageOrientation.up
        var isVideoAssetPortrait = false
        let videoTransform = videoAssetTrack.preferredTransform
        
        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
            videoAssetOrientation = .right
            isVideoAssetPortrait = true
        }
        if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
            videoAssetOrientation = .left
            isVideoAssetPortrait = true
        }
        if videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0 {
            videoAssetOrientation = .up
        }
        if videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0 {
            videoAssetOrientation = .down
        }
        
        videoLayerInstruction.setTransform(videoAssetTrack.preferredTransform, at: kCMTimeZero)
        videoLayerInstruction.setOpacity(0.0, at: videoAsset.duration)
        
        //Add instructions
        
        mainInstruction.layerInstructions = [videoLayerInstruction]
        let mainCompositionInst = AVMutableVideoComposition()
        let naturalSize : CGSize!
        if isVideoAssetPortrait {
            naturalSize = CGSize(width: videoAssetTrack.naturalSize.height, height: videoAssetTrack.naturalSize.width)
        } else {
            naturalSize = videoAssetTrack.naturalSize
        }
        
        let renderWidth = naturalSize.width
        let renderHeight = naturalSize.height
        
        mainCompositionInst.renderSize = CGSize(width: renderWidth, height: renderHeight)
        mainCompositionInst.instructions = [mainInstruction]
        mainCompositionInst.frameDuration = CMTime(value: 1, timescale: 30)
        
        self.applyVideoEffects(to: mainCompositionInst, size: naturalSize, currentLabel: label)
        
        // Get Path
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let outputPath = documentsURL?.appendingPathComponent("newVideoWithLabel.mp4")
        if FileManager.default.fileExists(atPath: (outputPath?.path)!) {
            do {
                try FileManager.default.removeItem(atPath: (outputPath?.path)!)
            }
            catch {
                print ("Error deleting file")
            }
        }
        // Create exporter
        
        let exporter = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = outputPath
        exporter?.outputFileType = AVFileTypeQuickTimeMovie
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.videoComposition = mainCompositionInst
        exporter?.exportAsynchronously(completionHandler: {
            self.exportDidFinish(session: exporter!)
        })
    }
    
    func exportDidFinish(session: AVAssetExportSession) {
        if session.status == .completed {
            let outputURL: URL? = session.outputURL
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL!)
            }) { saved, error in
                if saved {
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                    let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                    PHImageManager().requestAVAsset(forVideo: fetchResult!, options: nil, resultHandler: { (avurlAsset, audioMix, dict) in
                        let newObj = avurlAsset as! AVURLAsset
                        print(newObj.url)
                        DispatchQueue.main.async(execute: {
                            print(newObj.url.absoluteString)
                        })
                    })
                    print (fetchResult!)
                }
            }
        }
    }
    
    import Foundation
    import UIKit
    
    extension UIImage {
        class func createTransparentImageFrom(label: UILabel, imageSize: CGSize) -> UIImage {
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 2.0)
            let currentView = UIView.init(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
            currentView.backgroundColor = UIColor.clear
            currentView.addSubview(label)
            
            currentView.layer.render(in: UIGraphicsGetCurrentContext()!)
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return img!
        }
    }
}
