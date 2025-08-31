//
//  DeveloperLoginBoard.swift
//  CyntientOps (Debug only)
//

import SwiftUI
import GRDB

#if DEBUG
struct DeveloperLoginBoard: View {
    @EnvironmentObject private var authManager: NewAuthManager
    @State private var admins: [UserRow] = []
    @State private var clients: [UserRow] = []
    @State private var workers: [UserRow] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var loginError: String?
    @State private var loggingEmail: String? = nil
    @Environment(\.dismiss) private var dismiss

    struct UserRow: Identifiable { let id = UUID(); let name: String; let email: String; let role: String }

    var body: some View {
        ZStack {
            CyntientOpsDesign.DashboardColors.baseBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    if let error = error {
                        Text(error).foregroundColor(.red)
                            .padding().background(Color.red.opacity(0.1)).cornerRadius(8)
                    }

                    userSectionGrid(title: "Admins", users: admins, color: .purple)
                    userSectionGrid(title: "Clients", users: clients, color: .green)
                    userSectionGrid(title: "Workers", users: workers, color: .blue)
                }
                .padding(16)
            }
            .overlay(alignment: .topTrailing) {
                if let err = loginError { Text(err).foregroundColor(.red).padding(8) }
            }
        }
        .task { await loadUsers() }
        .navigationBarHidden(true)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("CyntientOps Developer Login")
                .font(.title2).fontWeight(.bold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)

            Text("Tap a card to log in with seeded credentials")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)

        }
    }

    @ViewBuilder
    private func userSectionGrid(title: String, users: [UserRow], color: Color) -> some View {
        if !users.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)

                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(users) { user in
                        Button(action: { Task { await quickLogin(user.email) } }) {
                            VStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                        .frame(height: 110)
                                        .overlay(
                                            Text(initials(for: user.name))
                                                .font(.system(size: 32, weight: .bold))
                                                .foregroundColor(color)
                                        )
                                }
                                VStack(spacing: 2) {
                                    Text(user.name)
                                        .font(.footnote).fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(user.email)
                                        .font(.caption2).foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(loggingEmail != nil)
                    }
                }
            }
        }
    }

    private func loadUsers() async {
        do {
            let rows = try await GRDBManager.shared.query("SELECT name, email, role FROM workers WHERE isActive = 1 ORDER BY role, name")
            let mapped = rows.compactMap { row -> UserRow? in
                guard let rawName = row["name"] as? String, let email = row["email"] as? String, let role = row["role"] as? String else { return nil }
                let name = nameOverrides[email] ?? rawName
                return UserRow(name: name, email: email, role: role)
            }

            let a = mapped.filter { $0.role.lowercased() == "admin" }
            let c = mapped.filter { $0.role.lowercased() == "client" }
            let w = mapped.filter { $0.role.lowercased() == "worker" || $0.role.lowercased() == "manager" }

            await MainActor.run {
                self.admins = a
                self.clients = c
                self.workers = w
                self.isLoading = false
            }
            // Apply DB name corrections in background for known mismatches
            Task { await applyNameCorrectionsIfNeeded(rows: rows) }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func quickLogin(_ email: String) async {
        if loggingEmail != nil { return }
        loggingEmail = email
        loginError = nil
        // Try seeded credential first, fallback to devQuickLogin
        if let password = SeededCredentials.password(for: email) {
            do {
                try await authManager.authenticate(email: email, password: password)
                await MainActor.run { dismiss() }
            } catch {
                // Fallback (dev only bypass)
                do { try await authManager.devQuickLogin(email: email); await MainActor.run { dismiss() } } catch { loginError = error.localizedDescription }
            }
        } else {
            do { try await authManager.devQuickLogin(email: email); await MainActor.run { dismiss() } } catch { loginError = error.localizedDescription }
        }
        loggingEmail = nil
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "?"
        let last = parts.dropFirst().first?.prefix(1) ?? ""
        return String(first + last)
    }

    // Known display name corrections mapped by email
    private let nameOverrides: [String: String] = [
        "David@jmrealty.org": "David Edelman",
        "jm@jmrealty.com": "JM Realty Admin",
        "mfarhat@farhatrealtymanagement.com": "Moises Farhat",
        "candace@solar1.org": "Candace",
        "sshapiro@citadelre.com": "Stephen Shapiro",
        "paul@corbelpm.com": "Paul Lamban",
        "maria@solarone.org": "Maria Rodriguez"
    ]

    // Persist corrections back to DB so other screens use the fixed names
    private func applyNameCorrectionsIfNeeded(rows: [[String: Any]]) async {
        for row in rows {
            guard let email = row["email"] as? String,
                  let current = row["name"] as? String,
                  let corrected = nameOverrides[email], current != corrected else { continue }
            do {
                try await GRDBManager.shared.execute("UPDATE workers SET name = ?, updated_at = ? WHERE email = ?", [corrected, Date().ISO8601Format(), email])
            } catch {
                // Non-fatal; just log
                print("Name correction failed for \(email): \(error)")
            }
        }
    }
}
#endif
