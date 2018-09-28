//
//  OverlayView.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 27/08/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import UIKit

class OverlayView: UIView {
    @IBOutlet private weak var firstLabel: UILabel!
    @IBOutlet private weak var secondLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    private func setup() {
        // First
        firstLabel.text = "1"
        
        // Second
        secondLabel.text = "2"
    }
    
    func update(_ firstData: String, _ secondData: String) {
        firstLabel.text = firstData
        secondLabel.text = secondData
    }
}