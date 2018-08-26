//
//  Filters.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 25/08/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import UIKit

struct Filters {
    static let CMYKHalftoneFilter = CIFilter(name: "CICMYKHalftone", withInputParameters: ["inputWidth" : 20, "inputSharpness": 1])
    static let ComicEffectFilter = CIFilter(name: "CIComicEffect")
    static let CrystallizeFilter = CIFilter(name: "CICrystallize", withInputParameters: ["inputRadius" : 30])
    static let EdgesEffectFilter = CIFilter(name: "CIEdges", withInputParameters: ["inputIntensity" : 10])
    static let HexagonalPixellateFilter = CIFilter(name: "CIHexagonalPixellate", withInputParameters: ["inputScale" : 40])
    static let InvertFilter = CIFilter(name: "CIColorInvert")
    static let PointillizeFilter = CIFilter(name: "CIPointillize", withInputParameters: ["inputRadius" : 30])
    static let LineOverlayFilter = CIFilter(name: "CILineOverlay")
    static let PosterizeFilter = CIFilter(name: "CIColorPosterize", withInputParameters: ["inputLevels" : 5])
}

