//
//  CityViewModel.swift
//  BusBudiOSChallenge
//
//  Created by Amanda Karolina Santos da Fonseca Paiva on 17/12/24.
//

import Foundation
import CoreLocation

// MARK: - CityViewModel
final class CityViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var cities: [City] = []
    @Published var userLocation: CLLocation?
    @Published var locationPermissionDenied: Bool = false
    @Published var error: NSError?
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func fetchCities() {
        guard let location = userLocation else {
            setError(message: Constants.userLocationNotAvailable)
            return
        }
        
        guard let url = URL(string: "\(Constants.baseURL)?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&limit=\(Constants.limit)&lang=\(Constants.language)") else {
            setError(message: Constants.invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = Constants.headers
        
        URLSession.shared.dataTask(with: request) { [self] data, response, error in
            if let error = error {
                setError(message: String(format: Constants.requestError, error.localizedDescription))
                return
            }
            
            guard let data = data else {
                setError(message: Constants.noDataInResponse)
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(SuggestionsResponse.self, from: data)
                let citiesWithDistance = decodedResponse.suggestions.map { city -> City in
                    var updatedCity = city
                    if let userLocation = self.userLocation {
                        updatedCity.distance = userLocation.distance(to: city)
                    }
                    return updatedCity
                }
                
                DispatchQueue.main.async {
                    self.cities = citiesWithDistance.sorted { ($0.distance ?? 0) < ($1.distance ?? 0) }
                }
                
            } catch {
                self.setError(message: String(format: Constants.decodingError, error.localizedDescription))
            }
            
        }.resume()
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userLocation = location
            locationManager.stopUpdatingLocation()
            fetchCities()
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        setError(message: String(format: Constants.locationError,
                                 error.localizedDescription))
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            locationPermissionDenied = true
        default:
            locationPermissionDenied = false
        }
    }
    
    // MARK: - Error Handling
    private func setError(message: String) {
        error = NSError(domain: "busbud.com", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

// MARK: - Constants
private struct Constants {
    static let baseURL = "https://napi.busbud.com/flex/suggestions/points-of-interest"
    static let headers: [String: String] = [
        "Accept": "application/vnd.busbud+json; version=3; profile=https://schema.busbud.com/v3/anything.json"
    ]
    static let language = "en"
    static let limit = 25
    static let userLocationNotAvailable = "User location not available."
    static let invalidURL = "Invalid URL."
    static let requestError = "Request error: %@"
    static let noDataInResponse = "No data in response."
    static let decodingError = "Error to decoding JSON: %@"
    static let locationError = "Error to getting location: %@"
}
