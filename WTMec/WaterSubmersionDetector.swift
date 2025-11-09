import CoreMotion
import Foundation

class WaterSubmersionSimulator: ObservableObject {
    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()
    
    @Published var isSubmerged = false
    
    private var lowMotionStart: Date?
    
    func startMonitoring() {
        // Motion updates
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            let acc = data.userAcceleration
            let totalAcc = sqrt(acc.x*acc.x + acc.y*acc.y + acc.z*acc.z)
            
            if totalAcc < 0.05 { // almost stationary
                if self.lowMotionStart == nil {
                    self.lowMotionStart = Date()
                } else if Date().timeIntervalSince(self.lowMotionStart!) > 5 {
                    self.isSubmerged = true
                }
            } else {
                self.lowMotionStart = nil
                self.isSubmerged = false
            }
        }
        
        // Altimeter updates
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
                guard let self = self, let data = data else { return }
                if data.pressure.doubleValue < -5 { // example threshold
                    self.isSubmerged = true
                }
            }
        }
    }
    
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        altimeter.stopRelativeAltitudeUpdates()
        isSubmerged = false
    }
}
