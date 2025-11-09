import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var lastLocation: CLLocation?
    @Published var path: [CLLocationCoordinate2D] = []

    private let manager = CLLocationManager()
    private var isTracking = false

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = true
        manager.activityType = .fitness
    }

    func requestAuthorization() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Location access restricted or denied")
        case .authorizedWhenInUse, .authorizedAlways:
            startTracking()
        @unknown default:
            break
        }
    }

    func startTracking() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services are disabled")
            return
        }

        if (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways) && !isTracking {
            manager.startUpdatingLocation()
            isTracking = true
        } else if authorizationStatus == .notDetermined {
            requestAuthorization()
        }
    }

    func stopTracking() {
        if isTracking {
            manager.stopUpdatingLocation()
            isTracking = false
        }
    }

    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            startTracking()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        if location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 50 {
            lastLocation = location
            path.append(location.coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }
}
