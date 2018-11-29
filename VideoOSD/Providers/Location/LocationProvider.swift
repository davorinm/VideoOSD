//
//  LocationProvider.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 29/11/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation

struct Location {
    let latitude: Double
    let longitude: Double
}

struct LocationBounds {
    let latitude: (min: Double, max: Double)
    let longitude: (min: Double, max: Double)
}

struct LocationProviderResponse {
    let location: Location?
    let error: Error?
    
    init(location: Location) {
        self.location = location
        self.error = nil
    }
    
    init(error: Error) {
        self.location = nil
        self.error = error
    }
}

protocol LocationProvider {
    var providerReponse: ObservableProperty<LocationProviderResponse> { get }
    
    func startUpdatingLocation()
    func stopUpdatingLocation()
}
