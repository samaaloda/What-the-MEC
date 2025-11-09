import SwiftUI
/*
struct LoginSignupRouterView: View {
    @State private var showSignUp = false
    @State private var showSignIn = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Earthquake Alerts")
                .font(.title)
                .padding()
            
            Button("Sign Up") { showSignUp = true }
                .buttonStyle(.borderedProminent)
                .sheet(isPresented: $showSignUp) {
                    SignUpView()
                }
            
            Button("Sign In") { showSignIn = true }
                .buttonStyle(.bordered)
                .sheet(isPresented: $showSignIn) {
                    SignInView()
                }
        }
    }
}
 */

/*
import SwiftUI

struct SignUpView: View {
    @ObservedObject private var supabase = SupabaseManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var number = ""
    
    @State private var message = ""
    
    var body: some View {
        VStack(spacing: 15) {
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            
            TextField("Number", text: $number)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)
            
            Button("Sign Up") {
                supabase.signUp(email: email, password: password, name: name, number: number) { success in
                    if success {
                        // Sign up successful, but do NOT log in
                        message = "✅ Account created! Please verify your email, then sign in."
                    } else {
                        message = "❌ Sign up failed. Try again."
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            
            Text(message)
                .foregroundColor(.blue)
                .padding()
        }
        .padding()
    }
}


import SwiftUI
import SwiftUI

struct SignInView: View {
    @ObservedObject private var supabase = SupabaseManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    
    var body: some View {
        VStack(spacing: 15) {
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            Button("Sign In") {
                supabase.signIn(email: email, password: password) { success, needsVerification in
                    if needsVerification {
                        message = "⚠️ Please verify your email first!"
                    } else if success {
                        message = "✅ Signed in!"
                    } else {
                        message = "❌ Sign in failed."
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            
            Text(message)
                .foregroundColor(.red)
                .padding()
        }
        .padding()
    }
}
*/
