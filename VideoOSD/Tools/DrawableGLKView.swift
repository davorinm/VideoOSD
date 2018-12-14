//
//  DrawableGLKView.swift
//  VideoOSD
//
//  Created by Davorin Mađarić on 14/12/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation
import GLKit

class DrawableGLKView: GLKView {
    var ciContext: CIContext?
    
    func drawImage(_ image: CIImage) {
        // OpenGLES draws in pixels, not points so we scale to whatever the contents scale is.
        let scale = CGAffineTransform(scaleX: self.contentScaleFactor, y: self.contentScaleFactor)
        let drawingRect = self.frame.applying(scale)
        
        // The image.extent() is the bounds of the image.
        self.bindDrawable()
        self.ciContext?.draw(image, in: drawingRect, from: image.extent)
        self.display()
    }
}

