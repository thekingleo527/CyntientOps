//
//  AdminMainMenuView.swift
//  CyntientOps v6.0
//
//  Main navigation menu for administrators
//

import SwiftUI

struct AdminMainMenuView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingSettings = false
    @State private var showingReports = false
    @State private var showingAnalytics = false
    @State private var showingHelp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Menu Items
                ScrollView {
                    VStack(spacing: 16) {
                        // Core Functions Section
                        menuSection(
                            title: "Core Functions",
                            items: [
                                MenuItemData(
                                    icon: "building.2.fill",
                                    title: "Portfolio Management",
                                    subtitle: "Manage buildings and assignments",
                                    color: .blue,
                                    action: { /* Navigate to buildings */ }
                                ),
                                MenuItemData(
                                    icon: "person.3.fill",
                                    title: "Worker Management",
                                    subtitle: "Manage team members and schedules",
                                    color: .green,
                                    action: { /* Navigate to workers */ }
                                ),
                                MenuItemData(
                                    icon: "checkmark.shield.fill",
                                    title: "Compliance Center",
                                    subtitle: "Monitor compliance and violations",
                                    color: .orange,
                                    action: { /* Navigate to compliance */ }
                                ),
                                MenuItemData(
                                    icon: "chart.bar.fill",
                                    title: "Analytics Dashboard",
                                    subtitle: "Performance metrics and insights",
                                    color: .purple,
                                    action: { showingAnalytics = true }
                                )
                            ]
                        )
                        
                        // Reports Section
                        menuSection(
                            title: "Reports & Documentation",
                            items: [
                                MenuItemData(
                                    icon: "doc.text.fill",
                                    title: "Generate Reports",
                                    subtitle: "Create compliance and performance reports",
                                    color: .indigo,
                                    action: { showingReports = true }
                                ),
                                MenuItemData(
                                    icon: "photo.stack.fill",
                                    title: "Photo Evidence",
                                    subtitle: "View and manage photo documentation",
                                    color: .cyan,
                                    action: { /* Navigate to photos */ }
                                ),
                                MenuItemData(
                                    icon: "calendar.badge.clock",
                                    title: "Schedule Management",
                                    subtitle: "Manage inspections and maintenance",
                                    color: .teal,
                                    action: { /* Navigate to schedules */ }
                                )
                            ]
                        )
                        
                        // System Section
                        menuSection(
                            title: "System",
                            items: [
                                MenuItemData(
                                    icon: "gearshape.fill",
                                    title: "Settings",
                                    subtitle: "App configuration and preferences",
                                    color: .gray,
                                    action: { showingSettings = true }
                                ),
                                MenuItemData(
                                    icon: "questionmark.circle.fill",
                                    title: "Help & Support",
                                    subtitle: "Documentation and assistance",
                                    color: .mint,
                                    action: { showingHelp = true }
                                )
                            ]
                        )
                    }
                    .padding()
                }
            }
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
        }
    }
    
    private var headerView: some View {
        HStack {
            Button("Close") {
                dismiss()
            }
            .foregroundColor(.white)
            
            Spacer()
            
            VStack(spacing: 4) {
                // CyntientOps Logo
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 32, height: 32)
                    
                    // Stylized "CO" for CyntientOps
                    Text("CO")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .gray.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                Text("CyntientOps")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Placeholder for balance
            Button("Close") {
                dismiss()
            }
            .foregroundColor(.black.opacity(0))
            .disabled(true)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
    
    private func menuSection(title: String, items: [MenuItemData]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(items, id: \.title) { item in
                    AdminMenuItemRow(item: item)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MenuItemData {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
}

struct AdminMenuItemRow: View {
    let item: MenuItemData
    
    var body: some View {
        Button(action: item.action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 20))
                        .foregroundColor(item.color)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

