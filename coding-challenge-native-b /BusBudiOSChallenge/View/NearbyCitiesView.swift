//
//  ContentView.swift
//  BusBudiOSChallenge
//
//  Created by Amanda Karolina Santos da Fonseca Paiva on 17/12/24.
//

import SwiftUI

// MARK: - View State Enum
enum ViewState {
    case permissionDenied
    case obtainingLocation
    case cities
}

struct NearbyCitiesView: View {
    @StateObject private var viewModel: CityViewModel
    @State private var showingPermissionAlert = false
    
    init(viewModel: CityViewModel = CityViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle(Constants.nearbyCitiesTitle)
                .onAppear { viewModel.fetchCities() }
        }
    }
    
    // MARK: - Content View
    private var content: some View {
        Group {
            switch viewState {
            case .permissionDenied:
                permissionDeniedView
            case .obtainingLocation:
                obtainingLocationView
            case .cities:
                cityListView
            }
        }
    }
    
    private var viewState: ViewState {
        if viewModel.locationPermissionDenied {
            return .permissionDenied
        } else if viewModel.userLocation == nil {
            return .obtainingLocation
        } else {
            return .cities
        }
    }
    
    private var permissionDeniedView: some View {
        Text(Constants.permissionDeniedMessage)
            .font(.headline)
            .padding()
            .alert(isPresented: $showingPermissionAlert) {
                Alert(
                    title: Text(Constants.permissionDeniedTitle),
                    message: Text(Constants.permissionDeniedAlertMessage),
                    primaryButton: .default(Text(Constants.permissionDeniedAlertOpenSettings)) {
                        openUserDeviceSettings()
                    },
                    secondaryButton: .cancel(Text(Constants.permissionDeniedAlertClose))
                )
            }
            .onAppear {
                showingPermissionAlert = true
            }
    }
    
    private var obtainingLocationView: some View {
        Text(Constants.obtainingLocation)
            .font(.headline)
            .padding()
    }
    
    private var cityListView: some View {
        List(viewModel.cities) { city in
            NavigationLink(destination: CityDetailView(city: city)) {
                VStack(alignment: .leading) {
                    Text(city.cityName)
                        .font(.headline)
                    if let distance = city.distance {
                        Text(String(format: "%.2f km away", distance))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private func openUserDeviceSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Constants
private struct Constants {
    static let permissionDeniedMessage = NSLocalizedString("Permission to access location is denied.", comment: "Message when location permission is denied")
    static let permissionDeniedTitle = NSLocalizedString("Location Permission Denied", comment: "Title for location permission denied alert")
    static let permissionDeniedAlertMessage = NSLocalizedString("We need location access to display nearby cities. Please enable location permissions in settings.", comment: "Alert message explaining the need for location access")
    static let permissionDeniedAlertOpenSettings = NSLocalizedString("Open Settings", comment: "Button text to open device settings")
    static let permissionDeniedAlertClose = NSLocalizedString("Close", comment: "Close the alert")
    static let obtainingLocation = NSLocalizedString("Obtaining your location...", comment: "Obtaining user location")
    static let nearbyCitiesTitle = "Nearby Cities"
}
