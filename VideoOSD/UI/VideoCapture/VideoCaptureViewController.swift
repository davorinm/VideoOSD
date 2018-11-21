import UIKit
import AVFoundation
import Photos

class VideoCaptureViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    @IBOutlet private weak var videoCaptureView: VideoCaptureView!
    @IBOutlet private weak var overlayView: UIView!
    
    private var fileUrl: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create session
        videoCaptureView.createSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Path for output file
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        fileUrl = paths[0].appendingPathComponent("output.mov")
        
        // Remove old file
        try? FileManager.default.removeItem(at: fileUrl)
        
        // Start recording
        videoFileOutput.startRecording(to: fileUrl, recordingDelegate: self)
    }
    
    // MARK: - Rotation
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil, completion: { [weak self] (context) in
            DispatchQueue.main.async(execute: {
                self?.updateVideoOrientation()
            })
        })
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(
            alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
                let deltaTransform = coordinator.targetTransform
                let deltaAngle = atan2f(Float(deltaTransform.b), Float(deltaTransform.a))
                var currentRotation : Float = (self.previewView!.layer.valueForKeyPath("transform.rotation.z")?.floatValue)!
                // Adding a small value to the rotation angle forces the animation to occur in a the desired direction, preventing an issue where the view would appear to rotate 2PI radians during a rotation from LandscapeRight -> LandscapeLeft.
                currentRotation += -1 * deltaAngle + 0.0001;
                self.previewView!.layer.setValue(currentRotation, forKeyPath: "transform.rotation.z")
                self.previewView!.layer.frame = self.view.bounds
        },
            completion:
            { (UIViewControllerTransitionCoordinatorContext) in
                // Integralize the transform to undo the extra 0.0001 added to the rotation angle.
                var currentTransform : CGAffineTransform = self.previewView!.transform
                currentTransform.a = round(currentTransform.a)
                currentTransform.b = round(currentTransform.b)
                currentTransform.c = round(currentTransform.c)
                currentTransform.d = round(currentTransform.d)
                self.previewView!.transform = currentTransform
        })
    }
    
    // MARK: - Actions
    
    @IBAction func startStopButtonPressed(_ sender: Any) {
        // Stop recording
        videoCaptureView.stopCapturing(completed: { (url, error) in
            
            
        })
        
        videoCaptureView.startCapturing(to: URL, completed: { (url) in
            <#code#>
        }) { (error) in
            <#code#>
        }
        
    }
    
    // MARK: - Video
    
    private func updateVideoOrientation() {
        guard let previewLayer = self.previewLayer else {
            return
        }
        guard previewLayer.connection?.isVideoOrientationSupported ?? false else {
            print("isVideoOrientationSupported is false")
            return
        }
        
        let deviceOrientation = UIDevice.current.orientation
        
        
        let videoOrientation: AVCaptureVideoOrientation = statusBarOrientation.videoOrientation ?? .portrait
        
        if previewLayer.connection.videoOrientation == videoOrientation {
            print("no change to videoOrientation")
            return
        }
        
        previewLayer.frame = cameraView.bounds
        previewLayer.connection.videoOrientation = videoOrientation
        previewLayer.removeAllAnimations()
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        PhotoLibrary.moveToPhotos(url: outputFileURL) { saved, error in
            self.dismiss(animated: true, completion: nil)
        }
    }
}
