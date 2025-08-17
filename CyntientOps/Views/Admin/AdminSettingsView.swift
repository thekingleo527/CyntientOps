//
//  AdminSettingsView.swift
//  CyntientOps v6.0
//
//  Admin system settings and configuration
//

import SwiftUI

public struct AdminSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var emergencyAlertsEnabled = true
    @State private var reportingInterval = "Daily"
    
    private let reportingIntervals = ["Hourly", "Daily", "Weekly"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notifications") {
                    Toggle("Push Notifications", isOn: $notificationsEnabled)
                    Toggle("Emergency Alerts", isOn: $emergencyAlertsEnabled)
                }
                
                Section("Reporting") {
                    Picker("Report Interval", selection: $reportingInterval) {
                        ForEach(reportingIntervals, id: \.self) { interval in
                            Text(interval).tag(interval)
                        }
                    }
                }
                
                Section("System") {
                    NavigationLink("User Management") {
                        Text("User Management")
                            .navigationTitle("Users")
                    }
                    
                    NavigationLink("Backup & Sync") {
                        Text("Backup & Sync")
                            .navigationTitle("Backup")
                    }
                    
                    NavigationLink("Security Settings") {
                        Text("Security Settings")
                            .navigationTitle("Security")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("6.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2024.1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("System Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    AdminSettingsView()
}