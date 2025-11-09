import SwiftUI
import Combine
import UniformTypeIdentifiers
import CoreImage.CIFilterBuiltins

// MARK: - Domain

enum BloodType: String, CaseIterable, Codable, Identifiable {
    case aPos = "A+", aNeg = "A-", bPos = "B+", bNeg = "B-", abPos = "AB+", abNeg = "AB-", oPos = "O+", oNeg = "O-"
    var id: String { rawValue }
}

struct MedicalProfile: Codable, Equatable {
    var name: String = ""
    var birthday: Date? = nil
    var weightKg: Double? = nil
    var heightCm: Double? = nil
    var bloodType: BloodType? = nil
    var allergies: String = "" // free-form
    var medications: String = ""
    var conditions: String = ""
    var emergencyContactName: String = ""
    var emergencyContactPhone: String = ""

    struct Visibility: Codable, Equatable {
        var name = true
        var birthday = true
        var weightKg = false
        var heightCm = false
        var bloodType = true
        var allergies = true
        var medications = false
        var conditions = true
        var emergencyContactName = true
        var emergencyContactPhone = true
    }
    var visibility = Visibility()
}

// MARK: - Persistence

final class ProfileStore: ObservableObject {
    @Published var profile: MedicalProfile = MedicalProfile()
    @Published var useImperial: Bool = false // units preference
 
    private let fileURL: URL

    init(filename: String = "medical_profile.json") {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = dir.appendingPathComponent(filename)
        load()
    }

    func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(SaveBundle.self, from: data)
            self.profile = decoded.profile
            self.useImperial = decoded.useImperial
        } catch {
            // first run or failed to decode -> keep defaults
        }
    }

    func save() {
        do {
            let encoded = try JSONEncoder().encode(SaveBundle(profile: profile, useImperial: useImperial))
            try encoded.write(to: fileURL, options: .atomic)
        } catch {
            print("Save error: \(error)")
        }
    }

    private struct SaveBundle: Codable { let profile: MedicalProfile; let useImperial: Bool }
}

// MARK: - Formatting helpers

extension MedicalProfile {
    func publicKeyValueLines(useImperial: Bool) -> [String] {
        var lines: [String] = []
        if visibility.name, !name.isEmpty { lines.append("Name: \(name)") }
        if visibility.birthday, let b = birthday {
            let df = DateFormatter(); df.dateStyle = .medium
            lines.append("Birthday: \(df.string(from: b))")
        }
        if visibility.bloodType, let bt = bloodType { lines.append("Blood Type: \(bt.rawValue)") }
        if visibility.heightCm, let cm = heightCm {
            let str = useImperial ? HeightFormatter.imperialString(fromCm: cm) : "\(Int(round(cm))) cm"
            lines.append("Height: \(str)")
        }
        if visibility.weightKg, let kg = weightKg {
            let str = useImperial ? String(format: "%.0f lb", kg * 2.20462) : String(format: "%.0f kg", kg)
            lines.append("Weight: \(str)")
        }
        if visibility.allergies, !allergies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Allergies: \(allergies)")
        }
        if visibility.medications, !medications.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Medications: \(medications)")
        }
        if visibility.conditions, !conditions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Conditions: \(conditions)")
        }
        if visibility.emergencyContactName, !emergencyContactName.isEmpty {
            lines.append("Emergency Contact: \(emergencyContactName)")
        }
        if visibility.emergencyContactPhone, !emergencyContactPhone.isEmpty {
            lines.append("Emergency Phone: \(emergencyContactPhone)")
        }
        return lines
    }
}

enum HeightFormatter {
    static func imperialString(fromCm cm: Double) -> String {
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12.0)
        let inches = Int(round(totalInches - Double(feet) * 12.0))
        return "\(feet)' \(inches)\""
    }
}

// MARK: - QR export



// MARK: - Views
/*
struct ContentView: View {
    @StateObject private var store = ProfileStore()
    @State private var showingShare = false
    @State private var showingQR = false

    var body: some View {
        NavigationStack {
            List {
                Section("Profile") {
                    NavigationLink { ProfileEditorView(profile: $store.profile, useImperial: $store.useImperial).onDisappear { store.save() } } label: {
                        HStack {
                            Image(systemName: "person.text.rectangle")
                            VStack(alignment: .leading) {
                                Text(store.profile.name.isEmpty ? "Set your info" : store.profile.name)
                                Text("Tap to edit").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Visibility") {
                    VisibilityTogglesView(profile: $store.profile).onDisappear { store.save() }
                }

                Section("Preview (what others see)") {
                    PublicCardView(lines: store.profile.publicKeyValueLines(useImperial: store.useImperial))
                }

                Section("Units") {
                    Toggle("Use Imperial (ft / lb)", isOn: $store.useImperial)
                        .onChange(of: store.useImperial) { _ in store.save() }
                }
            }
            .navigationTitle("Medical ID")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingQR = true } label: { Image(systemName: "qrcode") }
                        .accessibilityLabel("Show QR")
                    Button { showingShare = true } label: { Image(systemName: "square.and.arrow.up") }
                        .accessibilityLabel("Share")
                }
            }
        }
    }
}

struct ProfileEditorView: View {
    @Binding var profile: MedicalProfile
    @Binding var useImperial: Bool

    var body: some View {
        Form {
            Section("Identity") {
                TextField("Full name", text: $profile.name)
                DatePicker("Birthday", selection: Binding($profile.birthday, replacingNilWith: Date()), displayedComponents: .date)
            }

            Section("Vitals") {
                HStack {
                    if useImperial {
                        let pounds = Binding<Double?>(
                            get: { profile.weightKg.map { $0 * 2.20462 } },
                            set: { profile.weightKg = $0.map { $0 / 2.20462 } }
                        )
                        NumericField("Weight (lb)", value: pounds)
                    } else {
                        NumericField("Weight (kg)", value: $profile.weightKg)
                    }
                }
                HStack {
                    if useImperial {
                        let inches = Binding<Double?>(
                            get: { profile.heightCm.map { $0 / 2.54 } },
                            set: { profile.heightCm = $0.map { $0 * 2.54 } }
                        )
                        NumericField("Height (in)", value: inches)
                    } else {
                        NumericField("Height (cm)", value: $profile.heightCm)
                    }
                }
                Picker("Blood type", selection: Binding($profile.bloodType, replacingNilWith: .oPos)) {
                    Text("Not set").tag(BloodType?.none)
                    ForEach(BloodType.allCases) { bt in Text(bt.rawValue).tag(BloodType?.some(bt)) }
                }
            }

            Section("Medical notes") {
                TextField("Allergies", text: $profile.allergies, axis: .vertical)
                TextField("Medications", text: $profile.medications, axis: .vertical)
                TextField("Conditions", text: $profile.conditions, axis: .vertical)
            }

            Section("Emergency contact") {
                TextField("Name", text: $profile.emergencyContactName)
                TextField("Phone", text: $profile.emergencyContactPhone)
                    .keyboardType(.phonePad)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VisibilityTogglesView: View {
    @Binding var profile: MedicalProfile

    var body: some View {
        Toggle("Name", isOn: $profile.visibility.name)
        Toggle("Birthday", isOn: $profile.visibility.birthday)
        Toggle("Blood type", isOn: $profile.visibility.bloodType)
        Toggle("Height", isOn: $profile.visibility.heightCm)
        Toggle("Weight", isOn: $profile.visibility.weightKg)
        Toggle("Allergies", isOn: $profile.visibility.allergies)
        Toggle("Medications", isOn: $profile.visibility.medications)
        Toggle("Conditions", isOn: $profile.visibility.conditions)
        Toggle("Emergency contact name", isOn: $profile.visibility.emergencyContactName)
        Toggle("Emergency phone", isOn: $profile.visibility.emergencyContactPhone)
    }
}

struct PublicCardView: View {
    var lines: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(lines, id: \.self) { line in
                HStack(alignment: .top) {
                    Circle().frame(width: 6, height: 6).foregroundStyle(.secondary)
                    Text(line)
                }
            }
            if lines.isEmpty {
                Text("No fields are visible. Enable items in Visibility.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Utilities

extension Binding {
    /// Treat an Optional value as non-optional by replacing `nil` with a default.
    init(_ source: Binding<Value?>, replacingNilWith defaultValue: Value) {
        self.init(get: { source.wrappedValue ?? defaultValue }, set: { source.wrappedValue = $0 })
    }
}

struct NumericField: View {
    let title: String
    @Binding var value: Double?

    init(_ title: String, value: Binding<Double?>) {
        self.title = title
        self._value = value
    }

    @State private var buffer: String = ""

    var body: some View {
        TextField(title, text: Binding(
            get: { bufferFromValue() },
            set: { new in buffer = new; value = Double(new) }
        ))
        .keyboardType(.decimalPad)
        .onAppear { buffer = bufferFromValue() }
    }

    private func bufferFromValue() -> String {
        if let v = value {
            if v.rounded(.toNearestOrAwayFromZero) == v { return String(Int(v)) }
            return String(v)
        }
        return buffer
    }
}

// MARK: - App

@main
struct MedicalIDApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}*/
