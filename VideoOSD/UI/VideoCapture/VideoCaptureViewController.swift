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
        
        // Finish recording
        model.didStopCapturing = { [unowned self] (fileUrl) in
            // Move video
            PhotoLibrary.moveToPhotos(url: fileUrl) { saved, error in
                if let error = error {
                    AlertHandler.showAlert(title: "ERROR",
                                           message: error.localizedDescription,
                                           okActionTitle: "OK",
                                           fromViewController: self)
                    return
                }
                
                AlertHandler.showAlert(title: "SUCESS",
                                       message: "Video saved to Photos",
                                       okActionTitle: "OK",
                                       fromViewController: self)
            }
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
            model.stopCapturing { (sucess, error) in
                if sucess {
                    AlertHandler.showAlert(title: "Sucess", message: "Video saved", okActionTitle: "OK", fromViewController: self)
                } else if let error = error {
                    AlertHandler.showAlert(title: "ERROR", message: "\(error.localizedDescription)", okActionTitle: "OK", fromViewController: self)
                } else {
                    AlertHandler.showAlert(title: "ERROR", message: "VIDEO NOT SAVED", okActionTitle: "OK", fromViewController: self)
                }
            }
            recordingButton.setTitle("REC", for: .normal)
        } else {
            model.startCapturing()
            recordingButton.setTitle("STP", for: .normal)
        }
    }
}
