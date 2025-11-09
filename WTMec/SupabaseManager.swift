import Foundation
import Supabase

final class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
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
}

// MARK: - Contact Model
struct EmergencyContact: Codable, Identifiable {
    let id: String
    let user_id: String
    let name: String
    let number: String
}
