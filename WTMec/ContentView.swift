import SwiftUI
import MapKit

// MARK: - Root ContentView
struct ContentView: View {
    @ObservedObject private var supabase = SupabaseManager.shared
    @State private var showSignIn = false
    
    var body: some View {
        NavigationView {
            if let _ = supabase.user {
                // User signed in and verified - show main app with tabs
                HomeView()
            } else if showSignIn {
                // Show sign in page
                SignInView(showSignIn: $showSignIn)
            } else {
                // Initial signup page
                SignUpView(showSignIn: $showSignIn)
            }
        }
    }
}

// MARK: - SignUp View
struct SignUpView: View {
    @ObservedObject private var supabase = SupabaseManager.shared
    @Binding var showSignIn: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var number = ""
    @State private var message = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Sign Up").font(.largeTitle).bold()
            
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disabled(isLoading)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .disabled(isLoading)
            
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .disabled(isLoading)
            
            TextField("Phone Number", text: $number)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)
                .disabled(isLoading)
            
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                Button("Sign Up") {
                    signUpUser()
                }
                .buttonStyle(.borderedProminent)
            }
            
            if !message.isEmpty {
                Text(message)
                    .foregroundColor(message.contains("❌") ? .red : .green)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            // Link to sign in if already have account
            Button("Already have an account? Sign In") {
                showSignIn = true
            }
            .foregroundColor(.blue)
            .padding(.top)
            
            Spacer()
        }
        .padding()
    }
    
    private func signUpUser() {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty, !number.isEmpty else {
            message = "❌ Please fill in all fields"
            return
        }
        
        isLoading = true
        message = ""
        
        supabase.signUp(email: email, password: password, name: name, number: number) { success, errorMessage in
            isLoading = false
            if success {
                message = "✅ Signed up! Please check your email to verify your account, then sign in."
                // Wait 2 seconds then switch to sign in view
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSignIn = true
                }
            } else {
                message = "❌ Sign up failed: \(errorMessage ?? "Unknown error")"
            }
        }
    }
}

// MARK: - SignIn View
struct SignInView: View {
    @ObservedObject private var supabase = SupabaseManager.shared
    @Binding var showSignIn: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Sign In").font(.largeTitle).bold()
            
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disabled(isLoading)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .disabled(isLoading)
            
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                Button("Sign In") {
                    signInUser()
                }
                .buttonStyle(.borderedProminent)
            }
            
            if !message.isEmpty {
                Text(message)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            // Link back to sign up
            Button("Don't have an account? Sign Up") {
                showSignIn = false
            }
            .foregroundColor(.blue)
            .padding(.top)
            
            Spacer()
        }
        .padding()
    }
    
    private func signInUser() {
        guard !email.isEmpty, !password.isEmpty else {
            message = "❌ Please enter email and password"
            return
        }
        
        isLoading = true
        message = ""
        
        supabase.signIn(email: email, password: password) { success, emailNotVerified, errorMessage in
            isLoading = false
            if success {
                message = ""
                // User will automatically navigate to HomeView via ContentView
            } else if emailNotVerified {
                message = "❌ Please verify your email before signing in. Check your inbox for the verification link."
            } else {
                message = "❌ Sign in failed: \(errorMessage ?? "Invalid credentials")"
            }
        }
    }
}

// MARK: - Home View with Tabs
struct HomeView: View {
    var body: some View {
        TabView {
            MainAppView()
                .tabItem {
                    Label("Monitor", systemImage: "sensor.fill")
                }
            
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.circle.fill")
                }
        }
    }
}

// MARK: - Account View
struct AccountView: View {
    @ObservedObject private var supabase = SupabaseManager.shared
    @State private var contacts: [EmergencyContact] = []
    @State private var showAddContact = false
    @State private var newContactName = ""
    @State private var newContactNumber = ""
    @State private var message = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // User Info Section
                VStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text(supabase.getUserName())
                        .font(.title2)
                        .bold()
                    
                    Text(supabase.user?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if !supabase.getUserPhone().isEmpty {
                        Text(supabase.getUserPhone())
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                Divider()
                
                List {
                    Section(header: Text("Emergency Contacts")) {
                        ForEach(contacts) { contact in
                            VStack(alignment: .leading) {
                                Text(contact.name).font(.headline)
                                Text(contact.number).font(.subheadline).foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(message.contains("❌") ? .red : .green)
                        .padding()
                }
                
                Button("Sign Out") {
                    supabase.signOut()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .padding()
            }
            .navigationTitle("Account")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddContact = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddContact) {
                NavigationView {
                    VStack(spacing: 15) {
                        TextField("Contact Name", text: $newContactName)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                        
                        TextField("Phone Number", text: $newContactNumber)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.phonePad)
                            .padding()
                        
                        Button("Add Contact") {
                            addNewContact()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Spacer()
                    }
                    .navigationTitle("Add Contact")
                    .navigationBarItems(trailing: Button("Cancel") {
                        showAddContact = false
                    })
                }
            }
            .onAppear {
                loadContacts()
            }
        }
    }
    
    private func loadContacts() {
        supabase.fetchContacts { fetchedContacts in
            contacts = fetchedContacts
        }
    }
    
    private func addNewContact() {
        guard !newContactName.isEmpty, !newContactNumber.isEmpty else {
            message = "❌ Please fill in all fields"
            return
        }
        
        supabase.addContact(name: newContactName, number: newContactNumber) { success in
            if success {
                message = "✅ Contact added"
                newContactName = ""
                newContactNumber = ""
                showAddContact = false
                loadContacts()
            } else {
                message = "❌ Failed to add contact"
            }
        }
    }
}

// MARK: - Main App View (Earthquake & Sensors)
struct MainAppView: View {
    @StateObject private var earthquakeDetector = EarthquakeDetector()
    @StateObject private var waterDetector = WaterSubmersionSimulator()
    @StateObject private var soundDetector = SoundDetector()
    @StateObject private var locationManager = LocationManager()
    
    @State private var phoneNumber: String = "+1234567890"
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    statusView(title: "🌍 Earthquake Detection",
                               isActive: earthquakeDetector.earthquakeDetected,
                               activeText: "⚠️ Earthquake Detected!",
                               color: .red)
                    
                    statusView(title: "💧 Water Submersion Detection",
                               isActive: waterDetector.isSubmerged,
                               activeText: "⚠️ Device Submerged!",
                               color: .blue)
                    
                    statusView(title: "🔊 High Intensity Sound Detection",
                               isActive: soundDetector.highIntensityDetected,
                               activeText: "⚠️ Loud Sound Detected!",
                               color: .orange)
                    
                    TextField("Enter phone number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    Map(coordinateRegion: $region, showsUserLocation: true)
                        .frame(height: 200)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        Button("Start Monitoring") { startAll() }
                            .padding()
                            .background(Color.green.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        
                        Button("Stop Monitoring") { stopAll() }
                            .padding()
                            .background(Color.red.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Monitoring")
        }
        .onAppear {
            startAll()
            locationManager.requestAuth()
        }
        .onDisappear { stopAll() }
        .onChange(of: locationManager.lastLocation) { loc in
            if let loc = loc {
                region.center = loc.coordinate
            }
        }
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
    
    // MARK: - Helpers
    private func statusView(title: String, isActive: Bool, activeText: String, color: Color) -> some View {
        VStack {
            Text(title).font(.headline)
            Text(isActive ? activeText : "Monitoring...")
                .font(.title2)
                .foregroundColor(isActive ? color : .green)
        }
    }
    
    private func startAll() {
        earthquakeDetector.startDetection()
        waterDetector.startMonitoring()
        soundDetector.startMonitoring()
        locationManager.startTracking()
    }
    
    private func stopAll() {
        earthquakeDetector.stopDetection()
        waterDetector.stopMonitoring()
        soundDetector.stopMonitoring()
        locationManager.stopTracking()
    }
    
    private func sendAlert(message: String) {
        var fullMessage = message
        if let loc = locationManager.lastLocation {
            fullMessage += "\nLocation: https://maps.apple.com/?ll=\(loc.coordinate.latitude),\(loc.coordinate.longitude)"
        } else {
            fullMessage += "\nLocation: unavailable"
        }
        TwilioManager.shared.sendSMS(to: phoneNumber, message: fullMessage)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
