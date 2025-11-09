//
//  MedicalIDView.swift
//  WTMec
//
//  Created by Sama on 2025-11-09.
//

import SwiftUI

struct MedicalIDView: View {

    var onDone: () -> Void   // << Add this
    @StateObject private var supabase = SupabaseManager.shared
    @State private var profile: MedicalProfile = MedicalProfile()
    @State private var useImperial = false
    @State private var message = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Identity") {
                    TextField("Full Name", text: $profile.name)
                    DatePicker("Birthday", selection: Binding($profile.birthday, replacingNilWith: Date()), displayedComponents: .date)
                }
                
                Section("Vitals") {
                    HStack {
                        if useImperial {
                            let pounds = Binding<Double?>(
                                get: { profile.weightKg.map { $0 * 2.20462 } },
                                set: { profile.weightKg = $0.map { $0 / 2.20462 } }
                            )
                            NumericField(title:"Weight (lb)", value: pounds)
                        } else {
                            NumericField(title:"Weight (kg)", value: $profile.weightKg)
                        }
                    }
                    
                    HStack {
                        if useImperial {
                            let inches = Binding<Double?>(
                                get: { profile.heightCm.map { $0 / 2.54 } },
                                set: { profile.heightCm = $0.map { $0 * 2.54 } }
                            )
                            NumericField(title:"Height (in)", value: inches)
                        } else {
                            NumericField(title:"Height (cm)", value: $profile.heightCm)
                        }
                    }
                    
                    Picker("Blood Type", selection: Binding($profile.bloodType, replacingNilWith: .oPos)) {
                        Text("Not set").tag(BloodType?.none)
                        ForEach(BloodType.allCases) { bt in
                            Text(bt.rawValue).tag(BloodType?.some(bt))
                        }
                    }
                }
                
                Section("Medical Notes") {
                    TextField("Allergies", text: $profile.allergies, axis: .vertical)
                    TextField("Medications", text: $profile.medications, axis: .vertical)
                    TextField("Conditions", text: $profile.conditions, axis: .vertical)
                }
                
                Section("Emergency Contact") {
                    TextField("Contact Name", text: $profile.emergencyContactName)
                    TextField("Contact Phone", text: $profile.emergencyContactPhone)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    Toggle("Use Imperial (ft/lb)", isOn: $useImperial)
                }
                
                Section {
                    Button("Save Medical ID") {
                        saveProfile()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if !message.isEmpty {
                        Text(message)
                            .foregroundColor(message.contains("❌") ? .red : .green)
                    }
                }
            }
            .navigationTitle("Medical ID")
            .onAppear { loadProfile() }
        }
    }
    
    // MARK: - Actions
    private func saveProfile() {
        supabase.saveMedicalProfile(profile) { success in
            if success {
                message = "✅ Profile saved"
                // Call onDone to notify ContentView to show HomeView
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onDone()
                }
            } else {
                message = "❌ Failed to save profile"
            }
        }
    }
    
    private func loadProfile() {
        supabase.fetchMedicalProfile { fetchedProfile in
            if let fetched = fetchedProfile {
                profile = fetched
            }
        }
    }
}


// MARK: - Helper for Numeric Input
struct NumericField: View {
    let title: String
    @Binding var value: Double?
    
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

// MARK: - Binding extension for optional replacement
extension Binding {
    init(_ source: Binding<Value?>, replacingNilWith defaultValue: Value) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = $0 }
        )
    }
}
