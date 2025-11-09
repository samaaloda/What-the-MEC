import CoreMotion
import Foundation

class WaterSubmersionSimulator: ObservableObject {
    private let altimeter = CMAltimeter()
    @Published var isSubmerged = false

    // Threshold in kPa for submersion
    private let waterPressureThreshold = 1.0 // ~1 kPa above normal air pressure

    private var baselinePressure: Double?

    func startMonitoring() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }

        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            
            let pressure = data.pressure.doubleValue // in kPa

            // Set baseline if not already set
            if self.baselinePressure == nil {
                self.baselinePressure = pressure
            }

            if let baseline = self.baselinePressure {
                // If pressure rises significantly, consider submerged
                if pressure - baseline > self.waterPressureThreshold {
                    self.isSubmerged = true
                } else {
                    self.isSubmerged = false
                }
            }
        }
    }

    func stopMonitoring() {
        altimeter.stopRelativeAltitudeUpdates()
        isSubmerged = false
        baselinePressure = nil
    }
}
