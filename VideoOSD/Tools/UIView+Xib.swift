//
//  UIView+Xib.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 27/08/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import UIKit

extension UIView {
    
    class func createFromNib2(nibName: String) -> UIView {
        let nib = UINib.init(nibName: nibName, bundle: nil)
        let view = nib.instantiate(withOwner: nil, options: nil).first as! UIView
        
        return view
    }
    
    class func createFromNib(nibName: String, owner: Any, addTo: UIView) {
        let nib = UINib.init(nibName: nibName, bundle: nil)
        let view = nib.instantiate(withOwner: owner, options: nil).first as! UIView
        
        addTo.addSubview(view)
        view.pinTo(addTo)
    }
    
    func pinTo(_ view: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0).isActive = true
    }
}
