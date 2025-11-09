//
//  F.swift
//  WTMec
//
//  Created by Luna Almoayad on 2025-11-09.
//

import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?
    @Published var path: [CLLocationCoordinate2D] = []

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5          // meters between updates (tune for battery)
        manager.pausesLocationUpdatesAutomatically = true
        manager.activityType = .fitness     // or .otherNavigation for driving/evac routes
    }

    func requestAuth() {
        // Ask for "Always" only if you truly need it; otherwise WhenInUse is better.
        manager.requestWhenInUseAuthorization()
        // Later, if needed: manager.requestAlwaysAuthorization()
    }

    func startTracking() {
        if CLLocationManager.locationServicesEnabled() {
            manager.startUpdatingLocation()
            // For big jumps + low battery usage, consider: manager.startMonitoringSignificantLocationChanges()
        }
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startTracking()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        lastLocation = loc
        path.append(loc.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }
}
