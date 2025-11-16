import SwiftUI
import MapKit


import SwiftUI
/*
struct ContentView: View {
    var body: some View {
        Button("Send Test SMS") {
            TwilioManager.shared.sendSMS(to: "+16475136253", message: "Hello from Swift!")
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
}*/


// MARK: - Root ContentView
import SwiftUI

// MARK: - Root ContentView
struct ContentView: View {
    @ObservedObject private var supabase = SupabaseManager.shared
    @State private var showSignIn = false
    @State private var showMedicalID = false

    var body: some View {
        NavigationView {
            if let _ = supabase.user {
                // User is signed in
                if showMedicalID {
                    MedicalIDView(onDone: {
                        showMedicalID = false
                    })
                }
                    else {
                    // After Medical ID is completed, show main app
                    HomeView()
                }
            } else if showSignIn {
                SignInView(showSignIn: $showSignIn)
            } else {
                SignUpView(showSignIn: $showSignIn)
            }
        }
        .onChange(of:  showSignIn) { user in
            if user != nil {
                // Show MedicalIDView on login
                showMedicalID = true
            }
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
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
            MapViewContainer()
                .padding()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
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
/*
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
                    
                    
                    
                }
                .padding()
            }
            .navigationTitle("Monitoring")
        }
        .onAppear {
            startAll() // your existing detectors
            locationManager.requestAuthorization()
            locationManager.startTracking()
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
        .onChange(of: locationManager.lastLocation) { loc in
            if let loc = loc {
                region.center = loc.coordinate
            }
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
        let userName = SupabaseManager.shared.getUserName()
        let userPhone = SupabaseManager.shared.getUserPhone()

        guard !userName.isEmpty, !userPhone.isEmpty else {
            print("⚠️ User info missing, sending directly to contacts")
            sendToContacts(message: message)
            return
        }

        // Construct user alert message
        var userMessage = "⚠️ \(message)\nAre you okay? Reply YES within 30 seconds to cancel sending to contacts."
        if let loc = locationManager.lastLocation {
            userMessage += "\nLocation: https://maps.apple.com/?ll=\(loc.coordinate.latitude),\(loc.coordinate.longitude)"
        }

        // Send SMS to user first
        TwilioManager.shared.sendSMS(to: userPhone, message: userMessage)
        print("[Alert] Sent to user: \(userPhone)")

        // Wait 30 seconds for confirmation
        DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
            // Check if user responded (this requires storing user confirmation somewhere)
            if !SupabaseManager.shared.userConfirmedAlert {
                print("[Alert] User did not respond. Sending to emergency contacts.")
                sendToContacts(message: message)
            } else {
                print("[Alert] User confirmed, not contacting emergency contacts.")
                // Reset confirmation for next alert
                SupabaseManager.shared.userConfirmedAlert = false
            }
        }
    }

    private func sendToContacts(message: String) {
        SupabaseManager.shared.fetchContacts { contacts in
            let phoneNumbers = contacts.map { contact in
                var num = contact.number.trimmingCharacters(in: .whitespacesAndNewlines)
                num = num.replacingOccurrences(of: "^\\+?1?", with: "", options: .regularExpression)
                return "+1\(num)"
            }

            var fullMessage = message
            if let loc = locationManager.lastLocation {
                fullMessage += "\nUser: \(SupabaseManager.shared.getUserName())\n Location: https://maps.apple.com/?ll=\(loc.coordinate.latitude),\(loc.coordinate.longitude)"
            }

            for number in phoneNumbers {
                TwilioManager.shared.sendSMS(to: number, message: fullMessage)
            }
            DispatchQueue.main.async {
                print("[Alert] All messages to contacts queued.")
            }
        }
    }




    func numericToE164(_ number: Int, countryCode: String = "1") -> String {
        return "+1\(number)"
    }
}*/


/*
// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
*/
import SwiftUI
import MapKit
import CoreLocation

// MARK: - Map Annotation Model
struct MapLocation: Identifiable, Hashable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let type: LocationType

    enum LocationType: Hashable {
        case hospital
        case shelter
        case user
    }

    static func == (lhs: MapLocation, rhs: MapLocation) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude &&
               lhs.name == rhs.name &&
               lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
        hasher.combine(type)
    }
}


// MARK: - MapViewContainer
final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.262, longitude: -79.919),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @Published var annotations: [MapLocation] = []

    public let locationManager = CLLocationManager()
    func requestAuthorization() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - User Location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async {
            self.region.center = loc.coordinate
            // Add user annotation
            if !self.annotations.contains(where: { $0.type == .user }) {
                self.annotations.append(MapLocation(name: "You", coordinate: loc.coordinate, type: .user))
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }

    // MARK: - Search Functions
    // MARK: - Search Functions (FIXED)
    func findHospitals() {
        // Use natural language query instead of POI filter for better results
        searchPOI(query: "hospital", poiFilter: nil, type: .hospital)
    }

    func findShelters() {
        // Try multiple queries for better coverage
        searchPOI(query: "community center", poiFilter: nil, type: .shelter)
        // Also search for fire stations as emergency gathering points
        searchPOI(query: "fire station", poiFilter: nil, type: .shelter)
    }

    private func searchPOI(query: String?, poiFilter: MKPointOfInterestFilter?, type: MapLocation.LocationType) {
        guard let coord = currentCoordinate else {
            print("⚠️ Current location not available yet")
            return
        }
        
        let request = MKLocalSearch.Request()
        request.region = MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)  // Increased search radius
        )
        
        if let q = query {
            request.naturalLanguageQuery = q
        }
        if let filter = poiFilter {
            request.pointOfInterestFilter = filter
        }

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("⚠️ Search error for \(query ?? "POI"): \(error.localizedDescription)")
                return
            }
            
            guard let items = response?.mapItems else {
                print("⚠️ No results found for \(query ?? "POI")")
                return
            }
            
            print("✅ Found \(items.count) results for \(query ?? "POI")")
            
            let newAnnotations = items.map {
                MapLocation(
                    name: $0.name ?? "Unknown",
                    coordinate: $0.placemark.coordinate,
                    type: type
                )
            }
            
            DispatchQueue.main.async {
                for ann in newAnnotations {
                    if !self.annotations.contains(where: {
                        $0.coordinate.latitude == ann.coordinate.latitude &&
                        $0.coordinate.longitude == ann.coordinate.longitude
                    }) {
                        self.annotations.append(ann)
                    }
                }
            }
        }
    }

    // Add this helper to check location authorization status
    func checkLocationStatus() -> String {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            return "Not Determined - Request authorization"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied - Check Settings"
        case .authorizedAlways, .authorizedWhenInUse:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }

    var currentCoordinate: CLLocationCoordinate2D? {
        locationManager.location?.coordinate
    }

    // MARK: - Optional: Route to a location
    func openInMaps(_ location: MapLocation) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        mapItem.name = location.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

// MARK: - SwiftUI MapView
struct MapViewContainer: View {
    @StateObject private var vm = MapViewModel()

    var body: some View {
        NavigationView{
            VStack {
                // Buttons for POI searches
                HStack {
                    Button("Hospitals") { vm.findHospitals() }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.currentCoordinate == nil) // disable until we have location
                    Button("Shelters") { vm.findShelters() }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.currentCoordinate == nil)
                }
                .padding(.horizontal)
                // Map
                Map(coordinateRegion: $vm.region, showsUserLocation: true, annotationItems: vm.annotations) { location in
                    MapAnnotation(coordinate: location.coordinate) {
                        VStack {
                            Image(systemName: location.type == .hospital ? "cross.fill" : location.type == .shelter ? "house.fill" : "person.circle.fill")
                                .foregroundColor(location.type == .hospital ? .red : location.type == .shelter ? .blue : .green)
                                .font(.title2)
                                .onTapGesture { vm.openInMaps(location) }
                            Text(location.name).font(.caption2)
                        }
                    }
                }
                .frame(height: 500)
                .cornerRadius(10)
                .padding(.horizontal)
                
            }
            .navigationTitle("Map")
        }
        
        .onAppear {
            vm.requestAuthorization()
            print("Location Status: \(vm.checkLocationStatus())")
            print("Current Coordinate: \(vm.currentCoordinate?.latitude ?? 0), \(vm.currentCoordinate?.longitude ?? 0)")
        }
    }
}

import SwiftUI

// MARK: - Alert Model
struct EmergencyAlert: Identifiable {
    let id = UUID()
    let message: String
    let timestamp: Date
}
import SwiftUI
import MapKit
import CoreLocation

// MARK: - Brand Colors
private enum Brand {
    static let ink       = Color(red: 28/255,  green: 27/255,  blue: 41/255)   // deep plum/ink
    static let canvas    = Color(.systemBackground)
    static let card      = Color.white
    static let subtle    = Color.black.opacity(0.06)
    static let accent    = Color(red: 92/255,  green: 71/255,  blue: 200/255)  // soft purple
    static let ok        = Color(hex: "#18894A")
    static let warnRed   = Color(hex: "#E53935")
    static let waterBlue = Color(hex: "#1E88E5")
    static let soundOrg  = Color(hex: "#FB8C00")
}

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8)  / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}

// MARK: - Main App View (with polished UI)
struct MainAppView: View {

    @StateObject private var earthquakeDetector = EarthquakeDetector()
    @StateObject private var waterDetector      = WaterSubmersionSimulator()
    @StateObject private var soundDetector      = SoundDetector()
    @StateObject private var locationManager    = LocationManager()

    // Alert state
    @State private var showAlert      = false
    @State private var currentAlert: EmergencyAlert?
    @State private var alertTimer: Timer?
    @State private var countdown      = 30
    @State private var userMarkedSafe = false

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    // Bottom tab
    @State private var currentTab: Tab = .home
    enum Tab { case home, map, profile }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Brand.canvas, Color.white]),
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    header

                    // Content
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Monitoring…")
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundColor(Brand.ink)
                                .padding(.top, 6)

                            StatusCard(
                                icon: "globe.europe.africa.fill",
                                iconTint: Brand.accent,
                                title: "Earth Quake Detection",
                                statusText: earthquakeDetector.earthquakeDetected ? "⚠️ Earthquake Detected!" : "Status: None",
                                statusColor: earthquakeDetector.earthquakeDetected ? Brand.warnRed : Brand.ok
                            )

                            StatusCard(
                                icon: "drop.fill",
                                iconTint: Brand.waterBlue,
                                title: "Water Detection",
                                statusText: waterDetector.isSubmerged ? "⚠️ Device Submerged!" : "Status: None",
                                statusColor: waterDetector.isSubmerged ? Brand.waterBlue : Brand.ok
                            )

                            StatusCard(
                                icon: "speaker.wave.3.fill",
                                iconTint: Brand.soundOrg,
                                title: "Sound Detection",
                                statusText: soundDetector.highIntensityDetected ? "⚠️ Loud Sound Detected!" : "Status: None",
                                statusColor: soundDetector.highIntensityDetected ? Brand.soundOrg : Brand.ok
                            )

                            // App wordmark
                            Text("Seismo")
                                .font(.system(size: 38, weight: .bold, design: .serif))
                                .foregroundColor(Brand.ink)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 10)
                                .padding(.bottom, 90) // room for tab bar
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 8)
                    }

                    // Bottom Tab Bar
                }
                .ignoresSafeArea(edges: .bottom)

                // Full-screen alert overlay
                if showAlert, let alert = currentAlert {
                    alertOverlay(message: alert.message)
                        .transition(.opacity)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            startAll()
            locationManager.requestAuthorization()
            locationManager.startTracking()
        }
        .onDisappear { stopAll() }
        .onChange(of: locationManager.lastLocation) { loc in
            if let loc = loc { region.center = loc.coordinate }
        }
        .onChange(of: earthquakeDetector.earthquakeDetected) { detected in
            if detected { triggerAlert(message: "⚠️ Earthquake Detected!") }
        }
        .onChange(of: waterDetector.isSubmerged) { submerged in
            if submerged { triggerAlert(message: "⚠️ Device Submerged in Water!") }
        }
        .onChange(of: soundDetector.highIntensityDetected) { detected in
            if detected { triggerAlert(message: "⚠️ High Intensity Sound Detected!") }
        }
    }

    // MARK: Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hello, \(SupabaseManager.shared.getUserName().isEmpty ? "Luna" : SupabaseManager.shared.getUserName())")
                .font(.system(size: 44, weight: .black))
                .foregroundColor(Brand.ink)

            Text("\(formattedLocation()), \(formattedTime())")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(activeDisasterLine())
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.horizontal, 22)
        .padding(.bottom, 8)
    }

    // MARK: Bottom Tab Bar


    // MARK: Alert Overlay
    @ViewBuilder
    private func alertOverlay(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 22) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Brand.warnRed)

                Text(message)
                    .font(.title.bold())
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 6) {
                    Text("Emergency contacts will be notified in:")
                        .font(.headline)
                        .foregroundColor(.black)

                    Text("\(countdown)")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(countdown <= 10 ? Brand.warnRed : .yellow)
                        .animation(.easeInOut, value: countdown)

                    Text("seconds")
                        .font(.headline)
                        .foregroundColor(.black)
                }
                .padding(.vertical, 8)

                Button(action: dismissAlert) {
                    HStack(spacing: 10) {
                        Image(systemName: userMarkedSafe ? "checkmark.circle.fill" : "hand.raised.fill")
                            .font(.title2)
                        Text(userMarkedSafe ? "MARKED SAFE ✓" : "I'M SAFE — CANCEL ALERT")
                            .font(.title3.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(userMarkedSafe ? Brand.accent : Brand.ok)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 6)
                .disabled(userMarkedSafe)
            }
            .padding(.vertical, 28)
            .frame(maxWidth: 420)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(radius: 24)
            .padding()
        }
    }

    // MARK: Helpers
    private func formattedTime() -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: Date())
    }

    private func formattedLocation() -> String {
        guard let loc = locationManager.lastLocation else { return "Location" }
        return String(format: "%.4f, %.4f", loc.coordinate.latitude, loc.coordinate.longitude)
    }

    private func activeDisasterLine() -> String {
        if earthquakeDetector.earthquakeDetected || waterDetector.isSubmerged || soundDetector.highIntensityDetected {
            return "⚠️ Warning active"
        }
        return "No natural disasters reported"
    }

    private func statusView(title: String, isActive: Bool, activeText: String, color: Color) -> some View {
        // (Kept for compatibility if you still call this elsewhere.)
        VStack {
            Text(title).font(.headline)
            Text(isActive ? activeText : "Monitoring…")
                .font(.title2)
                .foregroundColor(isActive ? color : Brand.ok)
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
        alertTimer?.invalidate()
    }

    // MARK: Alert Logic (unchanged)
    private func triggerAlert(message: String) {
        guard !showAlert else { return }

        currentAlert = EmergencyAlert(message: message, timestamp: Date())
        countdown = 30
        showAlert = true

        // SMS to user
        let userPhone = SupabaseManager.shared.getUserPhone()
        if !userPhone.isEmpty {
            var userMessage = "⚠️ \(message)\nReply YES to cancel emergency contact notification."
            if let loc = locationManager.lastLocation {
                userMessage += "\nLocation: https://maps.apple.com/?ll=\(loc.coordinate.latitude),\(loc.coordinate.longitude)"
            }
            TwilioManager.shared.sendSMS(to: userPhone, message: userMessage)
        }

        alertTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            countdown -= 1
            if countdown <= 0 {
                timer.invalidate()
                alertTimer = nil
                sendToContacts(message: message)
                dismissAlert()
            }
        }
    }

    private func dismissAlert() {
        alertTimer?.invalidate()
        alertTimer = nil

        withAnimation { userMarkedSafe = true }
        SupabaseManager.shared.userConfirmedAlert = true

        let userPhone = SupabaseManager.shared.getUserPhone()
        if !userPhone.isEmpty {
            TwilioManager.shared.sendSMS(to: userPhone, message: "✅ Alert cancelled. You marked yourself as safe.")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showAlert = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                currentAlert = nil
                userMarkedSafe = false
                SupabaseManager.shared.userConfirmedAlert = false
            }
        }
    }

    private func sendToContacts(message: String) {
        SupabaseManager.shared.fetchContacts { contacts in
            let phoneNumbers = contacts.map { contact in
                var num = contact.number.trimmingCharacters(in: .whitespacesAndNewlines)
                num = num.replacingOccurrences(of: "^\\+?1?", with: "", options: .regularExpression)
                return "+1\(num)"
            }

            var fullMessage = message
            if let loc = locationManager.lastLocation {
                fullMessage += "\nUser: \(SupabaseManager.shared.getUserName())\nLocation: https://maps.apple.com/?ll=\(loc.coordinate.latitude),\(loc.coordinate.longitude)"
            }

            for number in phoneNumbers {
                TwilioManager.shared.sendSMS(to: number, message: fullMessage)
            }
            DispatchQueue.main.async { print("[Alert] Emergency contacts notified.") }
        }
    }
}

// MARK: - Reusable Views

private struct StatusCard: View {
    let icon: String
    let iconTint: Color
    let title: String
    let statusText: String
    let statusColor: Color

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle().fill(iconTint.opacity(0.15))
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(iconTint)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(statusText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(statusColor)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.card)
                .shadow(color: Brand.subtle, radius: 12, x: 0, y: 6)
        )
    }
}

private struct TabButton: View {
    let system: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: system)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isActive ? Brand.accent : .secondary)
                Circle()
                    .fill(isActive ? Brand.accent : .clear)
                    .frame(width: 6, height: 6)
                    .opacity(isActive ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isActive)
            }
        }
        .buttonStyle(.plain)
    }
}
