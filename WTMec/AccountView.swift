import SwiftUI
/*
struct AccountView: View {
    @ObservedObject private var supabase = SupabaseManager.shared

    @State private var contacts: [EmergencyContact] = []
    @State private var isLoading = false
    @State private var showAddContact = false
    @State private var toast: Toast? = nil

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color(.systemBackground), .white],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                List {
                    Section { profileHeader }
                        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)

                    Section(header: Text("Emergency Contacts")) {
                        if contacts.isEmpty && !isLoading {
                            EmptyContacts()
                        } else {
                            ForEach(contacts) { c in
                                ContactRow(contact: c)
                            }
                            .onDelete(perform: delete)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .refreshable { loadContacts() }

                VStack {
                    Spacer()
                    Button(role: .destructive) { supabase.signOut() } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }

                if let toast = toast {
                    ToastView(toast: toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .navigationTitle("Account")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { loadContacts() } label: { Image(systemName: "arrow.clockwise") }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddContact = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add Contact")
                }
            }
        }
        .sheet(isPresented: $showAddContact) {
            AddContactSheet { name, number in
                add(name: name, number: number)
            }
        }
        .onAppear { loadContacts() }
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Brand.accent.opacity(0.18))
                Text(initials(supabase.getUserName()))
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(Brand.accent)
            }
            .frame(width: 76, height: 76)

            Text(supabase.getUserName().isEmpty ? "Your Name" : supabase.getUserName())
                .font(.title2.bold())
                .foregroundColor(Brand.ink)

            if let email = supabase.user?.email {
                Label(email, systemImage: "envelope.fill")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            if !supabase.getUserPhone().isEmpty {
                Label(supabase.getUserPhone(), systemImage: "phone.fill")
                    .font(.subheadline).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.cardBG)
        )
        .padding(.horizontal)
    }

    // MARK: - Data

    private func loadContacts() {
        isLoading = true
        supabase.fetchContacts { fetched in
            contacts = fetched
            isLoading = false
        }
    }

    private func add(name: String, number: String) {
        supabase.addContact(name: name, number: number) { ok in
            if ok {
                show(.success("Contact added"))
                loadContacts()
            } else {
                show(.error("Failed to add contact"))
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        // if you have a supabase.deleteContact(contact) method, call it here then reload.
        contacts.remove(atOffsets: offsets)
        show(.info("Contact removed locally"))
    }

    private func show(_ t: Toast) {
        withAnimation { toast = t }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { toast = nil } }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.map { $0.first.map(String.init) ?? "" }.joined()
        return letters.isEmpty ? "SE" : letters.uppercased()
    }
}

// MARK: - Rows & Sheets

private struct ContactRow: View {
    let contact: EmergencyContact
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Brand.accent.opacity(0.15))
                Image(systemName: "person.fill").foregroundColor(Brand.accent)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name).font(.headline)
                Text(contact.number).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            if let url = URL(string: "tel://\(contact.number.filter { $0.isNumber })") {
                Link(destination: url) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(8)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct EmptyContacts: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.secondary)
            Text("No emergency contacts yet").font(.headline)
            Text("Add a trusted person so we can notify them in an emergency.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 14)
    }
}

private struct AddContactSheet: View {
    var onAdd: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var number = ""
    @State private var isValid = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Full name", text: $name).textContentType(.name)
                    TextField("Phone number", text: $number)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                Section(footer: Text("We’ll text this contact if you don’t mark yourself safe during an alert.")) {
                    Button {
                        onAdd(name.trimmingCharacters(in: .whitespaces),
                              number.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    } label: {
                        Label("Add Contact", systemImage: "plus.circle.fill")
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onChange(of: name) { _ in validate() }
            .onChange(of: number) { _ in validate() }
            .onAppear { validate() }
        }
    }
    private func validate() {
        let digits = number.filter { $0.isNumber }
        isValid = !name.trimmingCharacters(in: .whitespaces).isEmpty && digits.count >= 7
    }
}

// MARK: - Toast

private struct Toast: Identifiable, Equatable {
    enum Kind { case success, error, info }
    let id = UUID()
    let kind: Kind
    let text: String
    static func success(_ t: String) -> Toast { .init(kind: .success, text: t) }
    static func error(_ t: String)   -> Toast { .init(kind: .error, text: t) }
    static func info(_ t: String)    -> Toast { .init(kind: .info, text: t) }
}

private struct ToastView: View {
    let toast: Toast
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
            Text(toast.text).font(.subheadline.weight(.semibold))
            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(border.opacity(0.2), lineWidth: 1))
        .padding(.horizontal).padding(.top, 8)
    }
    private var icon: String {
        switch toast.kind {
        case .success: "checkmark.circle.fill"
        case .error:   "xmark.octagon.fill"
        case .info:    "info.circle.fill"
        }
    }
    private var border: Color {
        switch toast.kind {
        case .success: .green
        case .error:   .red
        case .info:    Brand.accent
        }
    }
}
*/
