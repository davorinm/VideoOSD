import UIKit
import AVFoundation
import Photos

class VideoCaptureViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    @IBOutlet private weak var previewView: UIView!
    @IBOutlet private weak var recordingButton: UIButton!
    
    private let model: VideoCaptureViewModel = VideoCaptureViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.startCapturing = { [unowned self] (fileUrl) in
            // Start capturing
            self.videoCaptureView.startCapturing(to: fileUrl, completed: { (url) in
                print("Start capturing")
            }) { (error) in
                AlertHandler.showError(title: "String", message: error.localizedDescription, okActionTitle: "OK", fromViewController: self)
            }
        }
        
        model.stopCapturing = { [unowned self] in
            // Stop recording
            self.videoCaptureView.stopCapturing(completed: { (url, error) in
                
                
            })
        }
        
        model.load()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        model.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let error = videoCaptureView.videoCaptureError {
            switch error {
            case .deviceNotFound:
                AlertHandler.showError(title: "String", message: "waa", okActionTitle: "OK", fromViewController: self)
            case .inputFailed:
                AlertHandler.showError(title: "String", message: "waa", okActionTitle: "OK", fromViewController: self)
            case .outputFailed:
                AlertHandler.showError(title: "String", message: "waa", okActionTitle: "OK", fromViewController: self)
            case .captureSessionNotRunning:
                AlertHandler.showError(title: "String", message: "waa", okActionTitle: "OK", fromViewController: self)
            case .internalError(let error):
                AlertHandler.showError(title: "String", message: error.localizedDescription, okActionTitle: "OK", fromViewController: self)
            }
        }
    }
    
    // MARK: - Rotation
    
//    override var shouldAutorotate: Bool {
//        return false
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
    
    // MARK: - Actions
    
    @IBAction func recordingButtonPressed(_ sender: Any) {
        model.toggleCapturing()
    }
    
    // MARK: Orientation
    
    override var shouldAutorotate: Bool {
        get {
            // Prevent autorotate when recording
            return model.isCapturing
        }
    }
    
    // MARK: - Video
    
//    private func updateVideoOrientation() {
//        guard let previewLayer = self.previewLayer else {
//            return
//        }
//        guard previewLayer.connection?.isVideoOrientationSupported ?? false else {
//            print("isVideoOrientationSupported is false")
//            return
//        }
//
//        let deviceOrientation = UIDevice.current.orientation
//
//
//        let videoOrientation: AVCaptureVideoOrientation = statusBarOrientation.videoOrientation ?? .portrait
//
//        if previewLayer.connection.videoOrientation == videoOrientation {
//            print("no change to videoOrientation")
//            return
//        }
//
//        previewLayer.frame = cameraView.bounds
//        previewLayer.connection.videoOrientation = videoOrientation
//        previewLayer.removeAllAnimations()
//    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        PhotoLibrary.moveToPhotos(url: outputFileURL) { saved, error in
            self.dismiss(animated: true, completion: nil)
        }
    }
}
