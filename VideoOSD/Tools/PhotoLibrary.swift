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
    class func moveToPhotos(url: URL, finished: @escaping ((_ saved: Bool, _ asset: PHAsset?, _ error: Error?) -> Void)) {
        var assetPlaceholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let changeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            assetPlaceholder = changeRequest?.placeholderForCreatedAsset
        }) { (saved, error) in
            if saved {                
                var asset: PHAsset? = nil
                if let placeholder = assetPlaceholder {
                    let fetchOptions = PHFetchOptions()
                    let fetchResult: PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [placeholder.localIdentifier], options: fetchOptions)
                    asset = fetchResult.firstObject
                }
                
                finished(true, asset, error)
            } else {
                finished(false, nil, error)
            }
        }
    }
}
