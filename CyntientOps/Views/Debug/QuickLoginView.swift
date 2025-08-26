#if DEBUG
import SwiftUI

struct QuickLoginView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    @State private var users: [(id: String, name: String, email: String, role: String)] = []
    @State private var isLoading = false
    @State private var error: String?

    private let db = GRDBManager.shared

    // DEBUG-only password map for fast testing (never included in release)
    private let passwordByEmail: [String: String] = [
        // Workers / Manager
        "greg.hutson@cyntientops.com": "GregWorker2025!",
        "edwin.lema@cyntientops.com": "EdwinPark2025!",
        "kevin.dutan@cyntientops.com": "KevinRubin2025!",
        "mercedes.inamagua@cyntientops.com": "MercedesGlass2025!",
        "luis.lopez@cyntientops.com": "LuisElizabeth2025!",
        "angel.guiracocha@cyntientops.com": "AngelDSNY2025!",
        "shawn.magloire@cyntientops.com": "ShawnHVAC2025!",
        // Admin
        "admin@cyntientops.com": "CyntientAdmin2025!",
        // Clients
        "jm@jmrealty.com": "JMRealty2025!",
        "David@jmrealty.org": "DavidJM2025!",
        "sarah@jmrealty.com": "SarahJM2025!",
        "david@weberfarhat.com": "WeberFarhat2025!",
        "maria@solarone.org": "SolarOne2025!",
        "robert@grandelizabeth.com": "GrandEliz2025!",
        "alex@citadelrealty.com": "Citadel2025!",
        "jennifer@corbelproperty.com": "Corbel2025!"
    ]

    var body: some View {
        NavigationView {
            List(users, id: \.id) { user in
                Button(action: { Task { await quickLogin(email: user.email) } }) {
                    HStack {
                        Text(user.name).font(.body)
                        Spacer()
                        Text(user.role.capitalized).font(.caption).foregroundColor(.secondary)
                    }
                }
                .disabled(isLoading)
            }
            .overlay {
                if isLoading { ProgressView("Signing in...") }
            }
            .navigationTitle("Quick Login (DEBUG)")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Reload") { Task { await loadUsers() } } } }
            .task { await loadUsers() }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
        }
    }

    private func loadUsers() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let rows = try await db.query("SELECT id, name, email, role FROM workers WHERE isActive = 1 ORDER BY role DESC, name ASC")
            self.users = rows.compactMap { row in
                guard let id = row["id"] as? String,
                      let name = row["name"] as? String,
                      let email = row["email"] as? String,
                      let role = row["role"] as? String else { return nil }
                return (id: id, name: name, email: email, role: role)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func quickLogin(email: String) async {
        guard let pwd = passwordByEmail[email] else {
            self.error = "No debug password available for \(email)"
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await authManager.authenticate(email: email, password: pwd)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
#endif

