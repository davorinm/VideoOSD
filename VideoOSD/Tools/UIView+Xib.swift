//
//  UIView+Xib.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 27/08/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import UIKit

extension UIView {
    /*
     Xib without owner
     */
    class func createFromNib<T : UIView>() -> T? {
        let nib = UINib(nibName: nibName, bundle: nil)
        let nibViews = nib.instantiate(withOwner: nil, options: nil)
        let view = nibViews.first as? T

        return view
    }
    
    /*
     Xib with owner
    */
    class func fromNib<T : UIView>() -> T {
        let owner = T(frame: CGRect.zero)
        
        let nib = UINib(nibName: nibName, bundle: nil)
        let nibViews = nib.instantiate(withOwner: owner, options: nil)
        guard let view = nibViews.first as? UIView else {
            fatalError("Error loading nib with name \(nibName)")
        }
        
        owner.addSubview(view)
        view.pinTo(owner)
        
        return owner
    }
    
    private class var nibName: String {
        let name = "\(self)".components(separatedBy: ".").first ?? ""
        return name
    }
    
    // View is parent
    func pinTo(_ view: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: view.topAnchor),
            self.leftAnchor.constraint(equalTo: view.leftAnchor),
            self.rightAnchor.constraint(equalTo: view.rightAnchor),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }
}
