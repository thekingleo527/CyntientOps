#if DEBUG
import SwiftUI

struct DeveloperLoginSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: NewAuthManager
    @State private var isLoading = false
    @State private var error: String?
    
    // Organized user groups with real data
    private let userGroups: [UserGroup] = [
        UserGroup(
            title: "JM Realty",
            subtitle: "9 Buildings Portfolio",
            color: .blue,
            icon: "building.2.fill",
            users: [
                DeveloperUser(name: "David Edelman", email: "David@jmrealty.org", role: "Client", password: "DavidJM2025!"),
                DeveloperUser(name: "Jerry Edelman", email: "jedelman@jmrealty.org", role: "Admin", password: "JerryJM2025!")
            ]
        ),
        UserGroup(
            title: "Field Team",
            subtitle: "CyntientOps Workers",
            color: .green,
            icon: "person.2.fill",
            users: [
                DeveloperUser(name: "Kevin Dutan", email: "kevin.dutan@cyntientops.com", role: "Worker", password: "KevinRubin2025!"),
                DeveloperUser(name: "Greg Hutson", email: "greg.hutson@cyntientops.com", role: "Worker", password: "GregWorker2025!"),
                DeveloperUser(name: "Edwin Lema", email: "edwin.lema@cyntientops.com", role: "Worker", password: "EdwinPark2025!")
            ]
        ),
        UserGroup(
            title: "Property Managers",
            subtitle: "Client Admins",
            color: .purple,
            icon: "building.fill",
            users: [
                DeveloperUser(name: "Moises Farhat", email: "mfarhat@farhatrealtymanagement.com", role: "Admin", password: "MoisesFarhat2025!"),
                DeveloperUser(name: "Michelle", email: "michelle@remidgroup.com", role: "Admin", password: "Michelle41E2025!"),
                DeveloperUser(name: "Stephen Shapiro", email: "sshapiro@citadelre.com", role: "Admin", password: "StephenCit2025!"),
                DeveloperUser(name: "Paul Lamban", email: "paul@corbelpm.com", role: "Admin", password: "PaulCorbel2025!"),
                DeveloperUser(name: "Candace", email: "candace@solar1.org", role: "Admin", password: "CandaceSolar2025!")
            ]
        ),
        UserGroup(
            title: "System Admin",
            subtitle: "Full Access",
            color: .orange,
            icon: "gear.circle.fill",
            users: [
                DeveloperUser(name: "System Admin", email: "admin@cyntientops.com", role: "Admin", password: "CyntientAdmin2025!")
            ]
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(userGroups, id: \.title) { group in
                        UserGroupCard(
                            group: group,
                            isLoading: isLoading,
                            onUserTap: { user in
                                Task { await quickLogin(user: user) }
                            }
                        )
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.07, green: 0.07, blue: 0.12),
                        Color(red: 0.05, green: 0.05, blue: 0.08)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Developer Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .preferredColorScheme(.dark)
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.white)
                            Text("Signing in...")
                                .foregroundColor(.white)
                                .padding(.top, 8)
                        }
                        .padding(24)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .alert("Login Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            Text(error ?? "")
        }
    }
    
    private func quickLogin(user: DeveloperUser) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authManager.devQuickLogin(email: user.email)
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to login as \(user.name): \(error.localizedDescription)"
            }
        }
    }
}

struct UserGroupCard: View {
    let group: UserGroup
    let isLoading: Bool
    let onUserTap: (DeveloperUser) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(group.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: group.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(group.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(group.subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Users
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(group.users, id: \.email) { user in
                    UserCard(
                        user: user,
                        groupColor: group.color,
                        isLoading: isLoading
                    ) {
                        onUserTap(user)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(group.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct UserCard: View {
    let user: DeveloperUser
    let groupColor: Color
    let isLoading: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                HStack {
                    Circle()
                        .fill(groupColor.opacity(0.8))
                        .frame(width: 8, height: 8)
                    
                    Spacer()
                    
                    Text(user.role)
                        .font(.caption2)
                        .foregroundColor(groupColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(groupColor.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Text(user.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(user.email.components(separatedBy: "@").first ?? "")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .padding(8)
            .frame(minHeight: 70)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(groupColor.opacity(0.4), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
    }
}

// MARK: - Supporting Types

struct UserGroup {
    let title: String
    let subtitle: String
    let color: Color
    let icon: String
    let users: [DeveloperUser]
}

struct DeveloperUser {
    let name: String
    let email: String
    let role: String
    let password: String
}

#endif