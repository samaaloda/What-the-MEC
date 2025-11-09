//
//  EarthquakeDetector.swift
//  WTMec
//
//  Created by Sama on 2025-11-09.
//

import CoreMotion



class EarthquakeDetector: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var earthquakeDetected = false
    
    // Thresholds for earthquake-like shaking
    private let accelerationThreshold: Double = 0.7 // Gs (adjust as needed)
    private let shakeDurationThreshold: Double = 0.5 // seconds of continuous shaking
    private var shakeStartTime: Date?
    
    func startDetection() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.05 // 20 Hz
        
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] (motionData, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error getting motion data: \(error.localizedDescription)")
                return
            }
            
            
            if let data = motionData {
                let userAcc = data.userAcceleration
                let totalAcc = sqrt(userAcc.x * userAcc.x + userAcc.y * userAcc.y + userAcc.z * userAcc.z)
                print("hello \(totalAcc)")
                if totalAcc > self.accelerationThreshold {
                    // Start timing if shake starts
                    if self.shakeStartTime == nil {
                        self.shakeStartTime = Date()
                    } else if let start = self.shakeStartTime, Date().timeIntervalSince(start) >= self.shakeDurationThreshold {
                        // Sustained shaking detected
                        self.earthquakeDetected = true
                        print("Earthquake detected! Acceleration: \(totalAcc)")
                    }
                } else {
                    // Reset shake timing if acceleration drops
                    self.shakeStartTime = nil
                }
            }
        }
    }
    
    func stopDetection() {
        motionManager.stopDeviceMotionUpdates()
        earthquakeDetected = false
        shakeStartTime = nil
    }
}
