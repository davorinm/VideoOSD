//
//  Filters.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 25/08/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import UIKit

struct Filters {
    static let CMYKHalftoneFilter = CIFilter(name: "CICMYKHalftone", parameters: ["inputWidth" : 20, "inputSharpness": 1])
    static let ComicEffectFilter = CIFilter(name: "CIComicEffect")
    static let CrystallizeFilter = CIFilter(name: "CICrystallize", parameters: ["inputRadius" : 30])
    static let EdgesEffectFilter = CIFilter(name: "CIEdges", parameters: ["inputIntensity" : 10])
    static let HexagonalPixellateFilter = CIFilter(name: "CIHexagonalPixellate", parameters: ["inputScale" : 40])
    static let InvertFilter = CIFilter(name: "CIColorInvert")
    static let PointillizeFilter = CIFilter(name: "CIPointillize", parameters: ["inputRadius" : 30])
    static let LineOverlayFilter = CIFilter(name: "CILineOverlay")
    static let PosterizeFilter = CIFilter(name: "CIColorPosterize", parameters: ["inputLevels" : 5])
}

