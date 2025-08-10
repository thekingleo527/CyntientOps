//
//  AdminProfileView.swift
//  CyntientOps v6.0
//
//  Administrator profile and settings view
//

import SwiftUI

struct AdminProfileView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingLogoutAlert = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Header
                profileHeader
                
                // Profile Options
                profileOptions
                
                Spacer()
                
                // Logout Button
                logoutSection
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationTitle("Administrator Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await authManager.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                // CyntientOps Logo
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 60, height: 60)
                    
                    // Stylized "CO" for CyntientOps
                    Text("CO")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .gray.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            
            // User Info
            VStack(spacing: 4) {
                Text(authManager.currentUser?.name ?? "Administrator")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(authManager.currentUser?.email ?? "admin@cyntientops.com")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Administrator")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var profileOptions: some View {
        VStack(spacing: 12) {
            ProfileOptionRow(
                icon: "gearshape.fill",
                title: "Settings",
                subtitle: "App preferences and configuration",
                color: .gray,
                action: { showingSettings = true }
            )
            
            ProfileOptionRow(
                icon: "shield.fill",
                title: "Security",
                subtitle: "Password and authentication settings",
                color: .green,
                action: { /* Security settings */ }
            )
            
            ProfileOptionRow(
                icon: "bell.fill",
                title: "Notifications",
                subtitle: "Configure alert preferences",
                color: .orange,
                action: { /* Notification settings */ }
            )
            
            ProfileOptionRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Analytics",
                subtitle: "View usage and performance metrics",
                color: .purple,
                action: { /* Analytics */ }
            )
            
            ProfileOptionRow(
                icon: "questionmark.circle.fill",
                title: "Help & Support",
                subtitle: "Documentation and assistance",
                color: .blue,
                action: { /* Help */ }
            )
        }
    }
    
    private var logoutSection: some View {
        Button(action: { showingLogoutAlert = true }) {
            HStack {
                Image(systemName: "arrow.backward.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text("Sign Out")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
struct AdminProfileView_Previews: PreviewProvider {
    static var previews: some View {
        AdminProfileView()
            .environmentObject(NewAuthManager())
            .preferredColorScheme(.dark)
    }
}
#endif