//
//  LocationProviderImpl.swift
//  VideoOSD
//
//  Created by Davorin Madaric on 29/11/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import Foundation
import CoreLocation

class LocationProviderImpl: LocationProvider, LocationProviderDelegate {
    var providerReponse: ObservableProperty<LocationProviderResponse> = ObservableProperty<LocationProviderResponse>(value: LocationProviderResponse(error: ProviderError.notFound))
    
    private let locationManager: CLLocationManager = CLLocationManager()
    private let locationProviderWrapper: LocationProviderWrapper = LocationProviderWrapper()
    
    private var nextAction: (() -> Void)?
    
    init() {        
        locationProviderWrapper.delegate = self
        
        locationManager.delegate = locationProviderWrapper
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func startUpdatingLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            
            nextAction = { [unowned self] in
                self.locationManager.startUpdatingLocation()
                self.nextAction = nil
            }
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            self.providerReponse.raise(LocationProviderResponse(error: ProviderError.notAllowed))
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - LocationProviderDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            nextAction?()
        case .notDetermined:
            break
        default:
            self.providerReponse.raise(LocationProviderResponse(error: ProviderError.cancelled))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let firstLocation = locations.first else {
            assertionFailure("Something went wrong")
            return
        }
        
        self.providerReponse.raise(LocationProviderResponse(location: Location(latitude: firstLocation.coordinate.latitude, longitude: firstLocation.coordinate.longitude)))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.providerReponse.raise(LocationProviderResponse(error: error))
    }
}

fileprivate protocol LocationProviderDelegate: class {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
}

fileprivate class LocationProviderWrapper: NSObject, CLLocationManagerDelegate {
    
    weak var delegate: LocationProviderDelegate?
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        delegate?.locationManager(manager, didChangeAuthorization: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.locationManager(manager, didUpdateLocations: locations)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationManager(manager, didFailWithError: error)
    }
}
