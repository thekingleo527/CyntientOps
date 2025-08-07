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
    
    @StateObject private var syncService = DashboardSyncService.shared
    
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
            
            if syncService.isOnline == false || syncService.pendingUpdatesCount > 0 {
                Button("Retry") {
                    Task {
                        await syncService.processPendingUpdatesBatch()
                    }
                }
                .font(.caption)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .animation(.easeInOut, value: syncService.isOnline)
        .animation(.easeInOut, value: syncService.pendingUpdatesCount)
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: Image {
        if !syncService.isOnline {
            return Image(systemName: "wifi.slash")
        }
        if syncService.pendingUpdatesCount > 0 {
            return Image(systemName: "arrow.triangle.2.circlepath")
        }
        return Image(systemName: "checkmark.icloud.fill")
    }
    
    private var statusColor: Color {
        if !syncService.isOnline {
            return .gray
        }
        if syncService.pendingUpdatesCount > 0 {
            return .orange
        }
        return .green
    }
    
    private var statusText: LocalizedStringKey {
        if !syncService.isOnline {
            return "Offline"
        }
        if syncService.pendingUpdatesCount > 0 {
            return "Syncing..."
        }
        return "Synced"
    }
    
    private var statusSubtitle: String? {
        if !syncService.isOnline {
            return "Your changes will be saved when you're back online."
        }
        if syncService.pendingUpdatesCount > 0 {
            return "\(syncService.pendingUpdatesCount) updates pending"
        }
        if let lastSync = syncService.lastSyncTime {
            return "Last sync: \(lastSync.formatted(date: .omitted, time: .shortened))"
        }
        return "All data is up to date."
    }
}

// MARK: - Preview
struct SyncStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SyncStatusView()
                .onAppear {
                    let service = DashboardSyncService.shared
                    service.isOnline = true
                    service.pendingUpdatesCount = 0
                    service.lastSyncTime = Date()
                }
            
            SyncStatusView()
                .onAppear {
                    let service = DashboardSyncService.shared
                    service.isOnline = true
                    service.pendingUpdatesCount = 5
                }
            
            SyncStatusView()
                .onAppear {
                    let service = DashboardSyncService.shared
                    service.isOnline = false
                }
        }
        .padding()
        .background(Color.black)
    }
}