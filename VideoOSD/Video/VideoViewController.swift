import UIKit

class VideoViewController: UIViewController {
    @IBOutlet private weak var videoView: UIVideoView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let result = videoView.createSession() {
            print("videoView createSession \(result)")
        } else {
            print("videoView createSession ERROR")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        
        let documentsPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let filename = dateFormatter.string(from: Date())
        let folderURL: URL = URL(fileURLWithPath: documentsPath)
        let fileURL: URL = folderURL.appendingPathComponent(filename + ".mp4")
        
        
        
        
        self.videoView.startCapturing(to: fileURL, completed: { [unowned self] (url) in
            print("InWorkoutViewController startCapturing")
        }, error: { (error) in
            print("InWorkoutViewController startCapturing error \(error)")
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.videoView.stopCapturing(completed: { (url, error) in
            if let error = error {
                print("InWorkoutViewController stopCapturing2 \(error)")
                return
            }
            print("InWorkoutViewController stopCapturing2 \(url)")
        })
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
