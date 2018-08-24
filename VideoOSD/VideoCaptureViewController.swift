import UIKit
import AVFoundation
import Photos

class VideoCaptureViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    @IBOutlet private weak var videoView: UIView!
    
    private let captureSession = AVCaptureSession()
    private let videoFileOutput = AVCaptureMovieFileOutput()
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create session
        let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)!
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = videoView.layer.bounds
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoView.layer.addSublayer(previewLayer)
            
            if captureSession.canAddOutput(videoFileOutput) {
                captureSession.addOutput(videoFileOutput)
            }
            
            captureSession.startRunning()
        } catch let error {
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Path for output file
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("output.mov")
        
        // Remove old file
        try? FileManager.default.removeItem(at: fileUrl)
        
        // Start recording
        videoFileOutput.startRecording(to: fileUrl, recordingDelegate: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop recording
        videoFileOutput.stopRecording()
    }
    
    // MARK: - Actions
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        self.saveToPhotos(url: outputFileURL)
    }
    
    // MARK: - Save to Photos
    
    private func saveToPhotos(url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { (saved, error) in
            if saved {
                // Remove saved file
                try? FileManager.default.removeItem(at: url)
                
                let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
