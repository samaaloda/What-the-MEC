import Foundation
import AVFoundation
import SwiftUI

class SoundDetector: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private var timer: Timer?
    
    @Published var highIntensityDetected = false
    
    // Threshold in decibels; adjust based on testing
    private let decibelThreshold: Float = -10.0 // dBFS (0 = max, lower = quieter)
    
    func startMonitoring() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            guard granted else {
                print("Microphone permission denied")
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let inputNode = self.audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    let channelData = buffer.floatChannelData![0]
                    let rms = sqrt((0..<Int(buffer.frameLength)).reduce(0) { $0 + channelData[$1]*channelData[$1] } / Float(buffer.frameLength))
                    let avgDb = 20 * log10(rms)
                    
                    DispatchQueue.main.async {
                        self.highIntensityDetected = avgDb > self.decibelThreshold
                    }
                }
                
                do {
                    try self.audioEngine.start()
                } catch {
                    print("Audio Engine failed to start: \(error.localizedDescription)")
                }
            }
        }
    }

    
    func stopMonitoring() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        highIntensityDetected = false
    }
}
