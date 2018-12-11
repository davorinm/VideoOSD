import UIKit
//import AVFoundation
//import Photos
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
        model.didStartCapturing = { [unowned self] in
            self.recordingButton.setTitle("STP", for: .normal)
            self.videoSaveSucess()
        }
        
        // Finish recording
        model.didStopCapturing = { [unowned self] in
            self.recordingButton.setTitle("REC", for: .normal)
            self.videoSaveSucess()
        }
        
        model.continueNewPreviewVideo = { [unowned self] in
            self.continueNewPreviewVideo()
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
        return !model.isCapturing
    }
    
    // MARK: - Actions
    
    @IBAction func recordingButtonPressed(_ sender: Any) {
        if model.isCapturing {
            model.stopCapturing()
        } else {
            model.startCapturing()
        }
    }
    
    // MARK: - Navigation
    
    private func continueNewPreviewVideo() {
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
    
    private func videoSaveSucess() {
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { [unowned self] (alertAction) in
            let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoPreviewVideoController") as! VideoPreviewVideoController
            vc.asset = asset
            self.present(vc, animated: true, completion: nil)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.destructive, handler: { [unowned self] (alertAction) in
            self.dismiss(animated: true, completion: nil)
        })
        
        AlertHandler.showAlertWithActions(title: "SUCESS",
                                          message: "Video saved to Photos\nWould you like to preview and edit it?",
                                          fromViewController: self,
                                          handlers: [okAction, cancelAction])
    }
}
