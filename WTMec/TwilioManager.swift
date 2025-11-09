import Foundation

final class TwilioManager {
    static let shared = TwilioManager()
    
    private let baseURL = URL(string: "http://172.18.178.137:3000/send-sms")!
    private let apiKey  = Config.twilioApiKey // store in config/Keychain
    
    private init() { }

    /// Ensure the number is numeric and has a leading + (basic validation)
    private func sanitizeNumber(_ raw: String) -> String? {
        // Remove all non-digit characters except +
        let allowedChars = CharacterSet(charactersIn: "+0123456789")
        let filtered = raw.filter { String($0).rangeOfCharacter(from: allowedChars) != nil }
        // Must start with + and at least 8 digits
        guard filtered.hasPrefix("+"), filtered.count >= 8 else {
            print("Invalid phone number, skipping:", raw)
            return nil
        }
        return filtered
    }

    /// Send an SMS message to a single number
    func sendSMS(to rawNumber: String, message: String) {
        guard let number = sanitizeNumber(rawNumber) else { return }

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let body: [String: Any] = [
            "to": number,
            "message": message
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending SMS to \(number):", error)
                return
            }
            guard let http = response as? HTTPURLResponse else {
                print("No HTTP response for \(number)")
                return
            }

            let bodyString = String(data: data ?? Data(), encoding: .utf8) ?? ""
            print("HTTP status for \(number):", http.statusCode)
            print("Response body:", bodyString)

            if (200..<300).contains(http.statusCode),
               let json = try? JSONSerialization.jsonObject(with: data ?? Data()) as? [String: Any],
               let sid = json["sid"] as? String {
                print("SMS queued to \(number). SID:", sid)
            } else {
                print("SMS failed for \(number)")
            }
        }.resume()
    }

    /// Send to multiple numbers
    func sendBulkSMS(to rawNumbers: [String], message: String) {
        for raw in rawNumbers {
            sendSMS(to: raw, message: message)
        }
    }
}

struct Config {
    static var twilioApiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "TWILIO_API_KEY") as? String ?? ""
    }
    
    static var supabaseApiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_API_KEY") as? String ?? ""
    }
}
