import UIKit
//import AVFoundation
//import Photos
import GLKit

class VideoCaptureViewController: UIViewController {
    @IBOutlet private weak var glImageView: GLKView!
    @IBOutlet private weak var recordingButton: UIButton!
    
    private var ciContext: CIContext!
    private var overlayView: OverlayView!

    private let model: VideoCaptureViewModel = VideoCaptureViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup GLView
        let glContext = EAGLContext(api: .openGLES2)
        glImageView.context = glContext!
        EAGLContext.setCurrent(glContext)
        ciContext = CIContext(eaglContext: glImageView.context)
        
        // Image
        model.displayImage = { image in
            self.glImageView.bindDrawable()
            self.ciContext.draw(image, in: image.extent, from: image.extent)
            self.glImageView.display()
        }
        
        // Setup OverlayView
        overlayView = OverlayView.createFromNib()
        
        // Finish recording
        model.didStopCapturing = { [unowned self] (fileUrl) in
            // Move video
            PhotoLibrary.moveToPhotos(url: fileUrl) { saved, error in
                if let error = error {
                    AlertHandler.showError(title: "ERROR",
                                           message: error.localizedDescription,
                                           okActionTitle: "OK",
                                           fromViewController: self)
                    return
                }
                
                AlertHandler.showError(title: "SUCESS",
                                       message: "Video saved to Photos",
                                       okActionTitle: "OK",
                                       fromViewController: self)
            }
        }
        
        model.load()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        model.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    // MARK: - Rotation
    
    override var shouldAutorotate: Bool {
        return !model.isCapturing
    }
    
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
    
    // MARK: - Layout
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        
    }
    
    // MARK: - Actions
    
    @IBAction func recordingButtonPressed(_ sender: Any) {
        model.toggleCapturing()
    }
}
