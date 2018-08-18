//
//  ViewController.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 18/08/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "video", sender: nil)
    }
}

