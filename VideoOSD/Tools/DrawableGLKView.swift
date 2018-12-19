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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    private func setup() {
        self.enableSetNeedsDisplay = false
        
        // Setup GLView
        context = EAGLContext(api: .openGLES2)!
        ciContext = CIContext(eaglContext: self.context)
        
        bindDrawable()
    }
    
    func drawImage(_ image: CIImage) {
        // OpenGLES draws in pixels, not points so we scale to whatever the contents scale is.
        let scale = CGAffineTransform(scaleX: self.contentScaleFactor, y: self.contentScaleFactor)
        let drawingRect = self.bounds.applying(scale)
        
        // The image.extent is the bounds of the image.
        ciContext?.draw(image, in: drawingRect, from: image.extent)
        display()
    }
}

