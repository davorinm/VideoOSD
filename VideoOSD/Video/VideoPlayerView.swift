////
////  VideoPlayerView.swift
////  ImpactWrapConsumer
////
////  Created by Davorin Mađarić on 14/06/2018.
////  Copyright © 2018 Inova. All rights reserved.
////
//
//import UIKit
//import AVKit
//import AVFoundation
//
//class VideoPlayerView: UIView {
//    override class var layerClass: AnyClass {
//        get {
//            return AVPlayerLayer.self
//        }
//    }
//    
//    var player: AVPlayer? {
//        get {
//            return playerLayer.player
//        }
//        
//        set {
//            playerLayer.player = newValue
//        }
//    }
//    
//    var playerLayer: AVPlayerLayer {
//        return layer as! AVPlayerLayer
//    }
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setup()
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        setup()
//    }
//    
//    private func setup() {
//        playerLayer.videoGravity = AVLayerVideoGravity.resize
//    }
//    
//    func play(asset: AVURLAsset) {
//        let playerItem = AVPlayerItem(asset: asset)
//        
//        let avPlayer = AVPlayer(playerItem: playerItem)
//        avPlayer.actionAtItemEnd = .none
//        avPlayer.isMuted = true
//        
//        player = avPlayer
//        
//        player?.play()
//        
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(playerDidPlayToEnd),
//                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
//                                               object: nil)
//    }
//    
//    @objc private func playerDidPlayToEnd() {
//        
//    }
//}
