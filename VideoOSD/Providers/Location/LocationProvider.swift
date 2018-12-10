//
//  LocationProvider.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 29/11/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation
import CoreLocation

struct LocationProviderResponse {
    let location: CLLocation?
    let error: Error?
    
    init(location: CLLocation) {
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
