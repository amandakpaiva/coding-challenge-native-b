//
//  ContentView.swift
//  BusBudiOSChallenge
//
//  Created by Amanda Karolina Santos da Fonseca Paiva on 17/12/24.
//

import SwiftUI

struct NearbyCitiesView: View {
    @StateObject private var viewModel = CityViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.viewState {
                case .permissionDenied:
                    permissionDeniedView
                case .obtainingLocation:
                    obtainingLocationView
                case .cities:
                    cityListView
                case .error(let message):
                    errorView(message: message)
                }
            }
            .navigationTitle("Nearby Cities")
        }
        .onAppear { viewModel.fetchCities() }
    }
    
    private var permissionDeniedView: some View {
        Text("Permission denied. Please enable location access.")
            .multilineTextAlignment(.center)
            .padding()
    }
    
    private var obtainingLocationView: some View {
        ProgressView("Obtaining Location...")
            .padding()
    }
    
    private var cityListView: some View {
        List(viewModel.cities) { city in
            NavigationLink(destination: CityDetailView(city: city)) {
                VStack(alignment: .leading) {
                    Text(city.cityName).font(.headline)
                    if let distance = city.distance {
                        Text(String(format: "%.2f km away", distance)).font(.subheadline)
                    }
                }
            }
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack {
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: viewModel.fetchCities) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
