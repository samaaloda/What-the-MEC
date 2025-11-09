import Foundation

class TwilioManager {
    static let shared = TwilioManager()
    
    func sendSMS(to number: String, message: String) {
        guard let url = URL(string: "https://your-backend.com/send-sms") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "to": number,
            "message": message
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending SMS: \(error)")
                return
            }
            print("SMS sent successfully!")
        }.resume()
    }
}
