import Foundation
import Supabase

final class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    @Published var userConfirmedAlert: Bool = false
    
    @Published var user: User? = nil
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://gsgjcltslhxllyhaswme.supabase.co")!,
            supabaseKey: Config.supabaseApiKey
        )
        
        // Check if user is already signed in on app launch
        Task {
            await checkExistingSession()
        }
    }
    
    // MARK: - Session Management
    private func checkExistingSession() async {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.user = session.user
            }
        } catch {
            print("No existing session: \(error)")
        }
    }
    
    
    // MARK: - Auth
    func signUp(email: String, password: String, name: String, number: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                // Sign up user with metadata - Supabase will send verification email automatically
                let response = try await client.auth.signUp(
                    email: email,
                    password: password,
                    data: [
                        "name": .string(name),
                        "phone": .string(number)
                    ]
                )
                
                // User metadata is stored in auth.users table automatically
                // No need for separate profiles table
                
                await MainActor.run {
                    completion(true, nil)
                }
            } catch {
                print("SignUp error: \(error)")
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, Bool, String?) -> Void) {
        // completion: success, emailNotVerified, errorMessage
        Task {
            do {
                let session = try await client.auth.signIn(
                    email: email,
                    password: password
                )
                
                let user = session.user
                
                // Check if email is confirmed
                if user.emailConfirmedAt != nil {
                    // Email is verified, successful sign in
                    await MainActor.run {
                        self.user = user
                        completion(true, false, nil)
                    }
                } else {
                    // Email not verified yet
                    await MainActor.run {
                        completion(false, true, "Email not verified")
                    }
                }
            } catch {
                print("SignIn error: \(error)")
                let errorMsg = error.localizedDescription
                
                // Check if error is about email confirmation
                if errorMsg.contains("email") && errorMsg.contains("confirm") {
                    await MainActor.run {
                        completion(false, true, errorMsg)
                    }
                } else {
                    await MainActor.run {
                        completion(false, false, errorMsg)
                    }
                }
            }
        }
    }
    
    func signOut() {
        Task {
            do {
                try await client.auth.signOut()
                await MainActor.run {
                    self.user = nil
                }
            } catch {
                print("SignOut error: \(error)")
            }
        }
    }
    
    // MARK: - User Info
    func getUserName() -> String {
        guard let metadata = user?.userMetadata else { return "User" }
        return metadata["name"]?.stringValue ?? "User"
    }
    
    func getUserPhone() -> String {
        guard let metadata = user?.userMetadata else { return "" }
        return metadata["phone"]?.stringValue ?? ""
    }
    
    // MARK: - Contacts
    func addContact(name: String, number: String, completion: @escaping (Bool) -> Void) {
        guard let userId = user?.id.uuidString else {
            completion(false)
            return
        }
        Task {
            do {
                try await client.database
                    .from("contacts")
                    .insert([
                        "user_id": userId,
                        "name": name,
                        "number": number
                    ])
                    .execute()
                await MainActor.run {
                    completion(true)
                }
            } catch {
                print("AddContact error: \(error)")
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    func fetchContacts(completion: @escaping ([EmergencyContact]) -> Void) {
        guard let userId = user?.id.uuidString else {
            completion([])
            return
        }
        
        Task {
            do {
                let response: [EmergencyContact] = try await client.database
                    .from("contacts")
                    .select()
                    .eq("user_id", value: userId)
                    .execute()
                    .value
                
                await MainActor.run {
                    completion(response)
                }
            } catch {
                print("FetchContacts error: \(error)")
                await MainActor.run {
                    completion([])
                }
            }
        }
    }
    
    // Save medical profile
    func saveMedicalProfile11(_ profile: MedicalProfile, completion: @escaping (Bool) -> Void) {
        guard let userId = user?.id.uuidString else { completion(false); return }

        let data: [String: String] = [
            "user_id": userId,
            "name": profile.name,
            "birthday": profile.birthday?.iso8601String ?? "",
            "weight_kg": profile.weightKg != nil ? String(profile.weightKg!) : "",
            "height_cm": profile.heightCm != nil ? String(profile.heightCm!) : "",
            "blood_type": profile.bloodType?.rawValue ?? "",
            "allergies": profile.allergies,
            "medications": profile.medications,
            "conditions": profile.conditions,
            "emergency_contact_name": profile.emergencyContactName,
            "emergency_contact_phone": profile.emergencyContactPhone,
            "contact_verified": profile.emergencyContactPhone.isEmpty ? "false" : "true"
        ]

        Task {
            do {
                try await client.database
                    .from("medical_profiles")
                    .upsert(data) // now everything is String
                    .execute()
                await MainActor.run { completion(true) }
            } catch {
                print("SaveMedicalProfile error:", error)
                await MainActor.run { completion(false) }
            }
        }
    }


    // Fetch medical profile
    func fetchMedicalProfile(completion: @escaping (MedicalProfile?) -> Void) {
        guard let userId = user?.id.uuidString else { completion(nil); return }
        
        Task {
            do {
                struct Row: Codable {
                    let name: String?
                    let birthday: String?
                    let weight_kg: Double?
                    let height_cm: Double?
                    let blood_type: String?
                    let allergies: String?
                    let medications: String?
                    let conditions: String?
                    let emergency_contact_name: String?
                    let emergency_contact_phone: String?
                    let contact_verified: Bool?
                }
                
                let response: [Row] = try await client.database
                    .from("medical_profiles")
                    .select()
                    .eq("user_id", value: userId)
                    .execute()
                    .value
                
                if let row = response.first {
                    var profile = MedicalProfile()
                    profile.name = row.name ?? ""
                    if let bday = row.birthday { profile.birthday = ISO8601DateFormatter().date(from: bday) }
                    profile.weightKg = row.weight_kg
                    profile.heightCm = row.height_cm
                    if let bt = row.blood_type { profile.bloodType = BloodType(rawValue: bt) }
                    profile.allergies = row.allergies ?? ""
                    profile.medications = row.medications ?? ""
                    profile.conditions = row.conditions ?? ""
                    profile.emergencyContactName = row.emergency_contact_name ?? ""
                    profile.emergencyContactPhone = row.emergency_contact_phone ?? ""
                    
                    await MainActor.run { completion(profile) }
                } else {
                    await MainActor.run { completion(nil) }
                }
            } catch {
                print("FetchMedicalProfile error:", error)
                await MainActor.run { completion(nil) }
            }
        }
    }

    // Mark emergency number as verified
    func verifyEmergencyContact(completion: @escaping (Bool) -> Void) {
        guard let userId = user?.id.uuidString else { completion(false); return }
        
        Task {
            do {
                try await client.database
                    .from("medical_profiles")
                    .update(["contact_verified": true])
                    .eq("user_id", value: userId)
                    .execute()
                await MainActor.run { completion(true) }
            } catch {
                print("VerifyEmergencyContact error:", error)
                await MainActor.run { completion(false) }
            }
        }
    }

}

extension Date {
    var iso8601String: String { ISO8601DateFormatter().string(from: self) }
}


extension SupabaseManager {

    struct MedicalProfileUpsert: Encodable {
            var user_id: String
            var name: String?
            var birthday: String?
            var weight_kg: Double?
            var height_cm: Double?
            var blood_type: String?
            var allergies: String?
            var medications: String?
            var conditions: String?
            var emergency_contact_name: String?
            var emergency_contact_phone: String?
        }

        func saveMedicalProfile(_ profile: MedicalProfile, completion: @escaping (Bool) -> Void) {
            guard let userId = user?.id else {
                print("SaveMedicalProfile error: no logged-in user")
                completion(false)
                return
            }

            let birthdayString: String? = profile.birthday.map {
                ISO8601DateFormatter().string(from: $0)
            }

            let upsert = MedicalProfileUpsert(
                user_id: userId.uuidString,
                name: profile.name.isEmpty ? nil : profile.name,
                birthday: birthdayString,
                weight_kg: profile.weightKg,
                height_cm: profile.heightCm,
                blood_type: profile.bloodType?.rawValue,
                allergies: profile.allergies.isEmpty ? nil : profile.allergies,
                medications: profile.medications.isEmpty ? nil : profile.medications,
                conditions: profile.conditions.isEmpty ? nil : profile.conditions,
                emergency_contact_name: profile.emergencyContactName.isEmpty ? nil : profile.emergencyContactName,
                emergency_contact_phone: profile.emergencyContactPhone.isEmpty ? nil : profile.emergencyContactPhone
            )

            Task {
                do {
                    try await client.database
                        .from("medical_profiles")
                        .upsert(upsert, returning: .representation) // optional: get back row
                        .execute()
                    
                    await MainActor.run { completion(true) }
                } catch {
                    print("SaveMedicalProfile error:", error)
                    await MainActor.run { completion(false) }
                }
            }
        }
}




// MARK: - Contact Model
struct EmergencyContact: Codable, Identifiable {
    let id: String
    let user_id: String
    let name: String
    let number: String
}
