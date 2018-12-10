//
//  AlertHandler.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 30/11/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import UIKit

class AlertHandler {
    class func showAlert(title: String, message: String, okActionTitle actionTitle: String, fromViewController viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: UIAlertAction.Style.default, handler: nil))
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    class func showAlertWithActions(title: String, message: String, fromViewController viewController: UIViewController, handlers: [UIAlertAction]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        for handler in handlers {
            alert.addAction(handler)
        }
        
        viewController.present(alert, animated: true, completion: nil)
    }
}
