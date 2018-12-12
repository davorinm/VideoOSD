import UIKit
import Photos
import GLKit

class VideoCaptureViewController: UIViewController {
    @IBOutlet private weak var glImageView: GLKView!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var recordingButton: UIButton!
    
    private var ciContext: CIContext!

    private let model: VideoCaptureViewModel = VideoCaptureViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup GLView
        let glContext = EAGLContext(api: .openGLES2)
        glImageView.context = glContext!
        EAGLContext.setCurrent(glContext)
        ciContext = CIContext(eaglContext: glImageView.context)
        
        // Video data
        model.displayImage = { [unowned self] (image, timestamp) in
            // Time
            self.timeLabel.text = DateTimeFormatter.formatTime(time: timestamp)
            
            // Draw image
            self.glImageView.bindDrawable()
            self.ciContext.draw(image, in: image.extent, from: image.extent)
            self.glImageView.display()
        }
        
        // Start recording
        model.didStartCapturing = { [unowned self] (error) in
            if let error = error {
                assertionFailure("errorDidOccured")
                return
            }
            
            self.recordingButton.setTitle("STP", for: .normal)
        }
        
        // Finish recording
        model.didEndCapturing = { [unowned self] (asset, error) in
            if let error = error {
                assertionFailure("errorDidOccured")
                return
            }
            
            self.recordingButton.setTitle("REC", for: .normal)
            self.videoSaveSucess(asset: asset)
        }
        
        // Previous video exists
        model.previousVideoExists = { [unowned self] in
            self.previousVideoExists()
        }
        
        model.load()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
        model.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        model.stop()
    }
    
    // MARK: - Rotation
    
    override var shouldAutorotate: Bool {
        return !model.isRecording
    }
    
    // MARK: - Actions
    
    @IBAction func recordingButtonPressed(_ sender: Any) {
        if model.isRecording {
            model.endRecording()
        } else {
            model.startRecording()
        }
    }
    
    // MARK: - Navigation
    
    private func previousVideoExists() {
        let continueRecordingAction = UIAlertAction(title: "Continue recording", style: UIAlertAction.Style.default, handler: { [unowned self] (alertAction) in
            
        })
        
        let newVideoAction = UIAlertAction(title: "Record a new video ", style: UIAlertAction.Style.default, handler: { [unowned self] (alertAction) in
            self.model.startRecording()
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
            AlertHandler.showAlert(title: "SUCESS", message: "Video saved to Photos", okActionTitle: "OK", fromViewController: self)
        }
    }
}
