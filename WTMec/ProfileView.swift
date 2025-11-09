import SwiftUI

struct ProfileView: View {
    @StateObject private var supabase = SupabaseManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var number = ""
    
    @State private var contactName = ""
    @State private var contactNumber = ""
    
    @State private var contacts: [EmergencyContact] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if supabase.user == nil {
                    // Signup / Signin
                    VStack(spacing: 10) {
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Phone Number", text: $number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Sign Up") {
                            supabase.signUp(email: email, password: password, name: name, number: number) { success, errorMessage in
                                if success {
                                    fetchContacts()
                                } else if let error = errorMessage {
                                    // Optionally handle the error message
                                    print("Sign up error: \(error)")
                                }
                            }
                        }
                        
                        Button("Sign In") {
                            supabase.signIn(email: email, password: password) { success, emailNotVerified, errorMessage in
                                if success {
                                    fetchContacts()
                                } else if emailNotVerified {
                                    // Optionally handle email not verified
                                    print("Email not verified")
                                } else if let error = errorMessage {
                                    // Optionally handle other errors
                                    print("Sign in error: \(error)")
                                }
                            }
                        }
                    }
                    .padding()
                } else {
                    // User Profile & Contacts
                    VStack(spacing: 10) {
                        Text("Logged in as \(name)")
                            .font(.headline)
                        Button("Sign Out") {
                            supabase.signOut()
                            contacts = []
                        }
                        
                        Divider()
                        
                        Text("Add Loved One")
                            .font(.subheadline)
                        TextField("Contact Name", text: $contactName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Contact Number", text: $contactNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Add Contact") {
                            supabase.addContact(name: contactName, number: contactNumber) { success in
                                if success { fetchContacts() }
                            }
                        }
                        
                        List(contacts) { contact in
                            HStack {
                                Text(contact.name)
                                Spacer()
                                Text(contact.number)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile Manager")
        }
    }
    
    private func fetchContacts() {
        supabase.fetchContacts { data in
            DispatchQueue.main.async {
                contacts = data
            }
        }
    }
}
