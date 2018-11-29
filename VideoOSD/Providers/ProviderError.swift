//
//  ProviderError.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 29/11/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation

enum ProviderError: Error, Equatable {
    case cancelled
    case notFound
    case notSelected
    case internalError
    case wrongState
    case userNotFound
    case userDataMissing
    case mappingError
    case timerNotExceeded
    case notAllowed
    case empty
    case tokenError
    case error(String)
}
