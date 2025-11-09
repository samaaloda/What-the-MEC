import SwiftUI

struct ContentView: View {
    @StateObject private var earthquakeDetector = EarthquakeDetector()
    @StateObject private var waterDetector = WaterSubmersionSimulator()
    @StateObject private var soundDetector = SoundDetector()
    
    // Variable number for SMS
    @State private var phoneNumber: String = "+1234567890"
    
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
            
            // Input field for SMS number
            TextField("Enter phone number", text: $phoneNumber)
                .keyboardType(.phonePad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
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
        .onChange(of: earthquakeDetector.earthquakeDetected) { detected in
            if detected { sendAlert(message: "⚠️ Earthquake Detected!") }
        }
        .onChange(of: waterDetector.isSubmerged) { submerged in
            if submerged { sendAlert(message: "⚠️ Device Submerged in Water!") }
        }
        .onChange(of: soundDetector.highIntensityDetected) { detected in
            if detected { sendAlert(message: "⚠️ High Intensity Sound Detected!") }
        }
    }
    
    // MARK: - Helper Views
    private func statusView(title: String, isActive: Bool, activeText: String, color: Color) -> some View {
        VStack {
            Text(title).font(.headline)
            Text(isActive ? activeText : "Monitoring...")
                .font(.title2)
                .foregroundColor(isActive ? color : .green)
        }
    }
    
    // MARK: - Monitoring
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
    
    // MARK: - Twilio SMS
    private func sendAlert(message: String) {
        TwilioManager.shared.sendSMS(to: phoneNumber, message: message)
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
