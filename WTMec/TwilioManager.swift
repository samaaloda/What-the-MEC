import Foundation

final class TwilioManager {
    static let shared = TwilioManager()
    
    private let baseURL = URL(string: "http://172.18.96.59:3000/send-sms")!
    private let apiKey  = Config.twilioApiKey
    
    private init() { }

    private func sanitizeNumber(_ raw: String) -> String? {
        let allowedChars = CharacterSet(charactersIn: "+0123456789")
        let filtered = raw.filter { String($0).rangeOfCharacter(from: allowedChars) != nil }
        guard filtered.hasPrefix("+"), filtered.count >= 8 else {
            print("[TwilioManager] Invalid phone number, skipping:", raw)
            return nil
        }
        return filtered
    }

    func sendSMS(to rawNumber: String, message: String) {
        guard let number = sanitizeNumber(rawNumber) else { return }

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let body: [String: Any] = ["to": number, "message": message]
        guard let data = try? JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted]) else {
            print("[TwilioManager] Failed to encode JSON body for", number)
            return
        }
        request.httpBody = data

        // Print the full debug info before sending
        print("[TwilioManager] Sending SMS to:", number)
        print("[TwilioManager] URL:", baseURL.absoluteString)
        print("[TwilioManager] Headers:", request.allHTTPHeaderFields ?? [:])
        print("[TwilioManager] Body:", String(data: data, encoding: .utf8) ?? "")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[TwilioManager] Network error sending to \(number):", error)
                return
            }
            guard let http = response as? HTTPURLResponse else {
                print("[TwilioManager] No HTTP response for \(number)")
                return
            }

            let bodyString = String(data: data ?? Data(), encoding: .utf8) ?? ""
            print("[TwilioManager] HTTP status for \(number):", http.statusCode)
            print("[TwilioManager] Response body:", bodyString)

            if (200..<300).contains(http.statusCode),
               let json = try? JSONSerialization.jsonObject(with: data ?? Data()) as? [String: Any],
               let sid = json["sid"] as? String {
                print("[TwilioManager] SMS queued to \(number). SID:", sid)
            } else {
                print("[TwilioManager] SMS failed for \(number)")
            }
        }.resume()
    }

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
