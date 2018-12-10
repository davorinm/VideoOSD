//
//  FilterVideoController.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 23/08/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import UIKit

class VideoRecorderViewController: UIViewController {
    
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
    
    
    
    //    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    //        super.viewWillTransition(to: size, with: coordinator)
    //
    //        coordinator.animate(alongsideTransition: nil, completion: { [weak self] (context) in
    //            DispatchQueue.main.async(execute: {
    //                self?.updateVideoOrientation()
    //            })
    //        })
    //    }
    
    //    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    //        super.viewWillTransition(to: size, with: coordinator)
    //
    //        coordinator.animate(
    //            alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
    //                let deltaTransform = coordinator.targetTransform
    //                let deltaAngle = atan2f(Float(deltaTransform.b), Float(deltaTransform.a))
    //                var currentRotation : Float = (self.previewView!.layer.valueForKeyPath("transform.rotation.z")?.floatValue)!
    //                // Adding a small value to the rotation angle forces the animation to occur in a the desired direction, preventing an issue where the view would appear to rotate 2PI radians during a rotation from LandscapeRight -> LandscapeLeft.
    //                currentRotation += -1 * deltaAngle + 0.0001;
    //                self.previewView!.layer.setValue(currentRotation, forKeyPath: "transform.rotation.z")
    //                self.previewView!.layer.frame = self.view.bounds
    //        },
    //            completion:
    //            { (UIViewControllerTransitionCoordinatorContext) in
    //                // Integralize the transform to undo the extra 0.0001 added to the rotation angle.
    //                var currentTransform : CGAffineTransform = self.previewView!.transform
    //                currentTransform.a = round(currentTransform.a)
    //                currentTransform.b = round(currentTransform.b)
    //                currentTransform.c = round(currentTransform.c)
    //                currentTransform.d = round(currentTransform.d)
    //                self.previewView!.transform = currentTransform
    //        })
    //    }
    
}
