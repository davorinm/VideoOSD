//
//  PhotosHelper.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 25/08/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation
import Photos

class PhotosHelper {
    class func checkAuthorization(authorized: @escaping (() -> Void), denied: @escaping (() -> Void)) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PhotosHelper.requestAuthorization(authorized: authorized, denied: denied)
        case .restricted:
            denied()
        case .denied:
            denied()
        case .authorized:
            authorized()
        case .limited:
            authorized()
        }
    }
    
    class func requestAuthorization(authorized: @escaping (() -> Void), denied: @escaping (() -> Void)) {
        PHPhotoLibrary.requestAuthorization { _ in
            PhotosHelper.checkAuthorization(authorized: authorized, denied: denied)
        }
    }
    
    class func moveToPhotos(url: URL, finished: @escaping ((_ saved: Bool, _ asset: PHAsset?, _ error: Error?) -> Void)) {
        // TODO: Create album - https://stackoverflow.com/questions/27008641/save-images-with-phimagemanager-to-custom-album
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
