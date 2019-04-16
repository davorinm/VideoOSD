//
//  VideoSettingsViewModel.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 04/12/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation

enum VideoOptionsItemType {
    case number
}

struct VideoSettingsItem {
//    let type: VideoOptionsItemType
//    let title: String
//    let value: String
}

struct VideoSettings {
    let videoResolution: String
    let format: String
}

class VideoSettingsViewModel {
    private var items: [VideoSettingsItem] = [VideoSettingsItem(), VideoSettingsItem(), VideoSettingsItem()]
    
    // MARK: - Items
    
    func numberOfItems() -> Int {
        return items.count
    }
    
    func itemFor(_ row: Int) -> VideoSettingsItem {
        return items[row]
    }
}
