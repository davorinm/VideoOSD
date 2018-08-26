//
//  PhotoLibrary.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 25/08/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation
import Photos

class PhotoLibrary {
    class func saveToPhotos(url: URL, removeSourceFile: Bool = false, finished: @escaping ((_ saved: Bool, _ error: Error?) -> Void)) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { (saved, error) in
            if saved {
                if removeSourceFile {
                    try? FileManager.default.removeItem(at: url)
                }
                
                finished(true, error)
            } else {
                finished(false, error)
            }
        }
    }
}
