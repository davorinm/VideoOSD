import UIKit
import Photos

class VideoCaptureViewController: UIViewController {
    @IBOutlet private weak var glImageView: DrawableGLKView!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var recordingButton: UIButton!
    @IBOutlet private weak var optionsButton: UIButton!
    @IBOutlet private weak var frontBackCameraButton: UIButton!
    
    private let model: VideoCaptureViewModel = VideoCaptureViewModel()
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.didLoad = { [unowned self] in
            self.model.start()
        }
        
        // Video data
        model.displayImage = { [unowned self] (image, timestamp) in
            // Time
            self.timeLabel.text = DateTimeFormatter.formatTime(time: timestamp)
            
            // Draw image
            self.glImageView.drawImage(image)
        }
        
        // Start recording
        model.didStartCapturing = { [unowned self] (error) in
            if let error = error {
                assertionFailure("errorDidOccured \(error.localizedDescription)")
                return
            }
            
            self.recordingButton.setTitle("STP", for: .normal)
        }
        
        // Finish recording
        model.didEndCapturing = { [unowned self] (asset, error) in
            if let error = error {
                print("errorDidOccured \(error.localizedDescription)")
                return
            }
            
            self.recordingButton.setTitle("REC", for: .normal)
            self.videoSaveSucess(asset: asset)
        }
        
        // Previous video exists
        model.previousVideoExists = { [unowned self] in
            self.previousVideoExists()
        }
        
        // Camera not authorized
        model.showVideoPermissionsError = { [unowned self] in
            self.showVideoPermissionsError()
        }
        
        model.load()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceOrientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        model.stop()
    }
    
    // MARK: - Rotation
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    @objc private func deviceOrientationDidChange(_ notification: Notification) {
        // Prevent rotation when recording
        if model.isRecording {
            return
        }
        
        let deviceOrientation = UIDevice.current.orientation
        
        let angle: Double
        switch deviceOrientation {
        case .portraitUpsideDown:
            angle = .pi
        case .landscapeLeft:
            angle = .pi / 2
        case .landscapeRight:
            angle = -.pi / 2
        default:
            angle = 0
        }
        
        UIView.animate(withDuration: 0.3) {
            self.recordingButton.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
            self.optionsButton.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
            self.frontBackCameraButton.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
        }
        
        model.deviceOrientationDidChange(orientation: deviceOrientation)
    }
    
    // MARK: - Actions
    
    @IBAction func recordingButtonPressed(_ sender: Any) {
        if model.isRecording {
            model.endRecording()
        } else {
            model.startRecording()
        }
    }
    
    @IBAction func switchCameraPressed(_ sender: Any) {
        if let isBackCamera = model.isBackCamera {
            if isBackCamera {
                model.useFrontCamera()
            } else {
                model.useBackCamera()
            }
        } else {
            assertionFailure("Not initialized")
        }
    }
    
    // MARK: - Navigation
    
    private func previousVideoExists() {
        let continueRecordingAction = UIAlertAction(title: "Continue recording", style: UIAlertAction.Style.default, handler: { [unowned self] (alertAction) in
            
        })
        
        let newVideoAction = UIAlertAction(title: "Record a new video ", style: UIAlertAction.Style.default, handler: { [unowned self] (alertAction) in
            
        })
        
        let previewAction = UIAlertAction(title: "Preview video", style: UIAlertAction.Style.default, handler: { [unowned self] (alertAction) in
            
        })
        
        AlertHandler.showAlertWithActions(title: "WARNING",
                                          message: "Previous video exists!",
                                          fromViewController: self,
                                          handlers: [continueRecordingAction, newVideoAction, previewAction])
    }
    
    private func videoSaveSucess(asset: PHAsset?) {
        if let asset = asset {
            let okAction = UIAlertAction(title: "Preview", style: UIAlertAction.Style.default, handler: { [unowned self] (alertAction) in
                let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoPreviewVideoController") as! VideoPreviewVideoController
                vc.asset = asset
                self.present(vc, animated: true, completion: nil)
            })
            
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.destructive, handler: { [unowned self] (alertAction) in
                self.dismiss(animated: true, completion: nil)
            })
            
            AlertHandler.showAlertWithActions(title: "SUCESS",
                                              message: "Video saved to Photos\nWould you like to preview and edit it?",
                                              fromViewController: self,
                                              handlers: [okAction, cancelAction])
        } else {
            AlertHandler.showAlert(title: "Error", message: "Video not saved to Photos", okActionTitle: "OK", fromViewController: self)
        }
    }
    
    // MARK: - Permissions
    
    private func showVideoPermissionsError() {
        let settingsAction = UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                    // TODO: Handle
                })
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        AlertHandler.showAlertWithActions(title: "Error",
                                          message: "Camera access is denied",
                                          fromViewController: self,
                                          handlers: [cancelAction, settingsAction])
    }
}
