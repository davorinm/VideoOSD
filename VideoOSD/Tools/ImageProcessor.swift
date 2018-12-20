//
//  ImageProcessor.swift
//  VideoOSD
//
//  Created by Davorin Mađarić on 20/12/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation
import UIKit
import CoreVideo
import VideoToolbox

class ImageProcessor {
    class func pixelBuffer(fromImage image:CGImage) -> CVPixelBuffer? {
        let frameSize = CGSize(width: image.width, height: image.height)
        
        var pixelBuffer: CVPixelBuffer! = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(frameSize.width), Int(frameSize.height), kCVPixelFormatType_32BGRA , nil, &pixelBuffer)
        if status != kCVReturnSuccess {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.init(rawValue: 0))
        
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: data,
                                width: Int(frameSize.width),
                                height: Int(frameSize.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                space: rgbColorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        
        context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    class func draw(image overlayImage: CGImage, toBuffer pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: bitmapInfo)
        
        context!.draw(overlayImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    class func draw(buffer pixelBuffer: CVPixelBuffer, toBuffer destinationPixelBuffer: CVPixelBuffer) {
        // Draw overlay
        // TODO: Create CVPixelBuffer from overlayImage, merge overlayImagePixelBuffer in video pixel buffer to remove CGContext
        // Maybe use CVPixelBufferPool
        // CISourceOverCompositing https://stackoverflow.com/questions/48969223/core-image-filter-cisourceovercompositing-not-appearing-as-expected-with-alpha-o
        // https://stackoverflow.com/a/4057608
        // https://stackoverflow.com/questions/21753926/avfoundation-add-text-to-the-cmsamplebufferref-video-frame/21754725
        // https://stackoverflow.com/questions/46524830/how-do-i-draw-onto-a-cvpixelbufferref-that-is-planar-ycbcr-420f-yuv-nv12-not-rgb/46524831#46524831
        // https://stackoverflow.com/questions/30609241/render-dynamic-text-onto-cvpixelbufferref-while-recording-video
        //
        //!!!! https://www.objc.io/issues/23-video/core-image-video/
        // https://gist.github.com/bgayman/6b27428ea48750e8306975c735bd517e
        // https://stackoverflow.com/questions/35603608/ios-overlay-two-images-with-alpha-offscreen
        //
        //!!! https://developer.apple.com/library/archive/samplecode/AVCustomEdit/Introduction/Intro.html#//apple_ref/doc/uid/DTS40013411-Intro-DontLinkElementID_2
        //
        //!!!!!!!!
        // https://willowtreeapps.com/ideas/how-to-apply-a-filter-to-a-video-stream-in-ios
        //!!!!!!!!
        //
        //
        //!!!!!!!! https://stackoverflow.com/questions/51922595/confusion-about-cicontext-opengl-and-metal-swift-does-cicontext-use-cpu-or-g
        
        
        //        CVPixelBufferLockBaseAddress( backImageBuffer,  kCVPixelBufferLock_ReadOnly );
        //        backImageFromSample = [CIImage imageWithCVPixelBuffer:backImageBuffer];
        //        [coreImageContext render:backImageFromSample toCVPixelBuffer:nextImageBuffer bounds:toRect colorSpace:rgbSpace];
        //        CVPixelBufferUnlockBaseAddress( backImageBuffer,  kCVPixelBufferLock_ReadOnly );
        //
        //
        //        let ttt = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!, options: [CIContextOption.workingColorSpace : NSNull()])
        //        ttt.render(<#T##image: CIImage##CIImage#>, toBitmap: <#T##UnsafeMutableRawPointer#>, rowBytes: <#T##Int#>, bounds: <#T##CGRect#>, format: <#T##CIFormat#>, colorSpace: <#T##CGColorSpace?#>)
    }
    
    class func draw(image overlayImage: CIImage, toImage: CIImage) -> CIImage {
        let result = overlayImage.composited(over: toImage)
        return result
    }
    
    class func draw(image: CIImage, to videoImage: CIImage) -> CIImage? {
        let compositor = CIFilter(name: "CISourceOverCompositing")
        compositor?.setValue(image, forKey: kCIInputImageKey)
        compositor?.setValue(videoImage, forKey: kCIInputBackgroundImageKey)
        let compositedCIImage = compositor?.outputImage
        
        return compositedCIImage
    }
    
    class func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}

class CurrentTimeEffect {
    
    let filter: CIFilter? = CIFilter(name: "CISourceOverCompositing")
    
    let label: UILabel = {
        let label: UILabel = UILabel()
        label.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
        return label
    }()
    
    func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
        let now: Date = Date()
        label.text = now.description
        
        UIGraphicsBeginImageContext(image.extent.size)
        label.drawText(in: CGRect(x: 0, y: 0, width: 200, height: 200))
        let result: CIImage = CIImage(image: UIGraphicsGetImageFromCurrentImageContext()!, options: nil)!
        UIGraphicsEndImageContext()
        
        filter!.setValue(result, forKey: "inputImage")
        filter!.setValue(image, forKey: "inputBackgroundImage")
        
        return filter!.outputImage!
    }
    
    // CADisplayLink
//    func test() {
//        let player = AVPlayer(playerItem: AVPlayerItem(asset: video))
//        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: nil)
//        player.currentItem?.addOutput(self.output)
//        player.play()
//
//        let displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkDidRefresh(_:)))
//        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
//
//        func displayLinkDidRefresh(link: CADisplayLink){
//            let itemTime = output.itemTimeForHostTime(CACurrentMediaTime())
//            if output.hasNewPixelBufferForItemTime(itemTime){
//                if let pixelBuffer = output.copyPixelBufferForItemTime(itemTime, itemTimeForDisplay: nil){
//                    let image = CIImage(CVPixelBuffer: pixelBuffer)
//                    // apply filters to image
//                    // display image
//                }
//            }
//        }
//    }
}
