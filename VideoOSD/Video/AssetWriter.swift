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
    private var assetWriter: AVAssetWriter!
    private var sessionAtSourceTime: CMTime?
    private var videoWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    
    var isWriting: Bool {
        get {
            return assetWriter.status == .writing
        }
    }
    
    init(fileUrl: URL) throws {        
        assetWriter = try AVAssetWriter(outputURL: fileUrl, fileType: AVFileType.mov)
        
        let outputSettings = videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: AVFileType.mov)
        
        let assetWriterInputVideo = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        assetWriterInputVideo.expectsMediaDataInRealTime = true
        assetWriter.add(assetWriterInputVideo)
        
        let audioOutputSettings = audioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: AVFileType.mov) as! [String : Any]
        
        let assetWriterInputAudio = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
        assetWriterInputAudio.expectsMediaDataInRealTime = true
        assetWriter.add(assetWriterInputAudio)
            
            
        
        
        
        
        
        videoWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Constant.Configuration.DefaultAssetSize.width,
            kCVPixelBufferHeightKey as String: Constant.Configuration.DefaultAssetSize.height,
            kCVPixelFormatOpenGLESCompatibility as String: true,
            ])
    }
    
    func start() {
        assetWriter.startWriting()
    }
    
    func stop(finished: @escaping (() -> Void)) {
        assetWriter.finishWriting {
            finished()
        }
    }
    
    func append() {        
        if assetWriter.status == .writing {
            if sessionAtSourceTime == nil {
                sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                assetWriter.startSession(atSourceTime: sessionAtSourceTime!)
            }
            
            if connection == videoConnection {
                if assetWriterInputVideo.isReadyForMoreMediaData {
                    if assetWriterInputVideo.append(sampleBuffer) == false {
                        if assetWriter.status == .failed {
                            assertionFailure("AVAssetWriter error \(assetWriter.error!)")
                        }
                    }
                }
            }
            
            if connection == audioConnection  {
                
            }
            
            if assetWriterInputVideo.isReadyForMoreMediaData {
                if assetWriter.status == .writing, assetWriterInputVideo.append(sampleBuffer) == false {
                    if assetWriter.status == .failed {
                        assertionFailure("AVAssetWriter error \(assetWriter.error!)")
                    }
                }
            } else {
                assertionFailure()
            }
        }
    }
}
