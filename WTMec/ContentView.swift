import SwiftUI
import CoreMotion
import Foundation


struct ContentView: View {
    @StateObject private var earthquakeDetector = EarthquakeDetector()
    @StateObject private var waterDetector = WaterSubmersionSimulator()
    @StateObject private var soundDetector = SoundDetector()
    
    var body: some View {
        VStack(spacing: 30) {
            
            // Earthquake Status
            statusView(title: "🌍 Earthquake Detection",
                       isActive: earthquakeDetector.earthquakeDetected,
                       activeText: "⚠️ Earthquake Detected!",
                       color: .red)
            
            // Water Submersion Status
            statusView(title: "💧 Water Submersion Detection",
                       isActive: waterDetector.isSubmerged,
                       activeText: "⚠️ Device Submerged!",
                       color: .blue)
            
            // High Intensity Sound Status
            statusView(title: "🔊 High Intensity Sound Detection",
                       isActive: soundDetector.highIntensityDetected,
                       activeText: "⚠️ Loud Sound Detected!",
                       color: .orange)
            
            // Control Buttons
            HStack(spacing: 20) {
                Button(action: startAll) {
                    Text("Start Monitoring")
                        .padding()
                        .background(Color.green.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: stopAll) {
                    Text("Stop Monitoring")
                        .padding()
                        .background(Color.red.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .onAppear { startAll() }
        .onDisappear { stopAll() }
    }
    
    private func statusView(title: String, isActive: Bool, activeText: String, color: Color) -> some View {
        VStack {
            Text(title).font(.headline)
            Text(isActive ? activeText : "Monitoring...")
                .font(.title2)
                .foregroundColor(isActive ? color : .green)
        }
    }
    
    // MARK: - Helpers
    private func startAll() {
        earthquakeDetector.startDetection()
        waterDetector.startMonitoring()
        soundDetector.startMonitoring()
    }
    
    private func stopAll() {
        earthquakeDetector.stopDetection()
        waterDetector.stopMonitoring()
        soundDetector.stopMonitoring()
    }
}

