//
//  CityViewModel.swift
//  BusBudiOSChallenge
//
//  Created by Amanda Karolina Santos da Fonseca Paiva on 17/12/24.
//

import Foundation
import CoreLocation

enum ViewState {
    case permissionDenied
    case obtainingLocation
    case cities
    case error(String) // Estado de erro com mensagem
}

final class CityViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var cities: [City] = []
    @Published var viewState: ViewState = .obtainingLocation
    
    private let locationManager = CLLocationManager()
    private let cityService: CityService
    var userLocation: CLLocation?
    
    init(cityService: CityService = CityService()) {
        self.cityService = cityService
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func fetchCities() {
        guard let location = userLocation else {
            viewState = .error("Location not available.")
            return
        }
        
        cityService.fetchNearbyCities(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cities):
                    if cities.isEmpty {
                        self?.viewState = .error("No cities found nearby.")
                    } else {
                        self?.cities = cities.map { city in
                            var updatedCity = city
                            updatedCity.distance = location.distance(to: city) / 1000 
                            return updatedCity
                        }.sorted { ($0.distance ?? 0) < ($1.distance ?? 0) }
                        self?.viewState = .cities
                    }
                case .failure:
                    self?.viewState = .error("Failed to load cities. Check your internet connection.")
                }
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userLocation = location
            locationManager.stopUpdatingLocation()
            fetchCities()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        viewState = .error("Failed to get your location.")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            viewState = .permissionDenied
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
}
