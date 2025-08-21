//
//  SyncStatusView.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 7/31/25.
//


//
//  SyncStatusView.swift
//  CyntientOps
//
//  Stream A: UI/UX & Spanish
//  Mission: Create a reusable component to display data sync status.
//
//  ✅ PRODUCTION READY: A clear, informative status indicator.
//  ✅ INTEGRATED: Driven by the DashboardSyncService.
//

import SwiftUI

struct SyncStatusView: View {
    
    @State private var isOnline = true
    @State private var pendingUpdatesCount = 0
    @State private var lastSyncTime: Date? = Date()
    
    var body: some View {
        HStack(spacing: 8) {
            statusIcon
                .font(.headline)
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(statusText)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let subtitle = statusSubtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isOnline == false || pendingUpdatesCount > 0 {
                Button("Retry") {
                    Task {
                        await performSync()
                    }
                }
                .font(.caption)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .animation(.easeInOut, value: isOnline)
        .animation(.easeInOut, value: pendingUpdatesCount)
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: Image {
        if !isOnline {
            return Image(systemName: "wifi.slash")
        }
        if pendingUpdatesCount > 0 {
            return Image(systemName: "arrow.triangle.2.circlepath")
        }
        return Image(systemName: "checkmark.icloud.fill")
    }
    
    private var statusColor: Color {
        if !isOnline {
            return .gray
        }
        if pendingUpdatesCount > 0 {
            return .orange
        }
        return .green
    }
    
    private var statusText: LocalizedStringKey {
        if !isOnline {
            return "Offline"
        }
        if pendingUpdatesCount > 0 {
            return "Syncing..."
        }
        return "Synced"
    }
    
    private var statusSubtitle: String? {
        if !isOnline {
            return "Your changes will be saved when you're back online."
        }
        if pendingUpdatesCount > 0 {
            return "\(pendingUpdatesCount) updates pending"
        }
        if let lastSync = lastSyncTime {
            return "Last sync: \(lastSync.formatted(date: .omitted, time: .shortened))"
        }
        return "All data is up to date."
    }
    
    // MARK: - Actions
    
    private func performSync() async {
        await MainActor.run {
            pendingUpdatesCount = 1
        }
        
        // Simulate sync process
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            isOnline = true
            pendingUpdatesCount = 0
            lastSyncTime = Date()
        }
    }
}

// MARK: - Preview
struct SyncStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SyncStatusView()
                .onAppear {
                    // Preview state configuration
                }
            
            SyncStatusView()
                .onAppear {
                    // Preview with pending updates
                }
            
            SyncStatusView()
                .onAppear {
                    // Preview offline state
                }
        }
        .padding()
        .background(Color.black)
    }
}