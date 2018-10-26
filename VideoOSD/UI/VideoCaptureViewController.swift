import UIKit
import AVFoundation
import Photos

class VideoCaptureViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    @IBOutlet private weak var videoView: UIView!
    
    private let captureSession = AVCaptureSession()
    private let videoFileOutput = AVCaptureMovieFileOutput()
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var fileUrl: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create session
        let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)!
        
        let videoInput = try! AVCaptureDeviceInput(device: videoCaptureDevice)
        
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
    
    // MARK: - Actions
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        // Stop recording
        videoFileOutput.stopRecording()
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
