//
//  AdminDashboardHeader.swift
//  CyntientOps Phase 4
//
//  Admin Dashboard Header - Fixed height 80px
//  Shows admin name, key metrics, and system status
//

import SwiftUI

struct AdminDashboardHeader: View {
    let adminName: String
    let totalBuildings: Int
    let activeWorkers: Int
    let criticalAlerts: Int
    let syncStatus: CoreTypes.DashboardSyncStatus
    
    private var syncStatusColor: Color {
        switch syncStatus {
        case .syncing: return .orange
        case .synced: return .green
        case .error: return .red
        case .failed: return .red
        case .offline: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Admin Info Section
            HStack(spacing: 12) {
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
                        .frame(width: 44, height: 44)
                    
                    // Stylized "CO" for CyntientOps
                    Text("CO")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .gray.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                // Admin Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(adminName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("Administrator")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Key Metrics
            HStack(spacing: 20) {
                AdminHeaderMetric(
                    icon: "building.2",
                    value: "\(totalBuildings)",
                    label: "Buildings",
                    color: .blue
                )
                
                AdminHeaderMetric(
                    icon: "person.3",
                    value: "\(activeWorkers)",
                    label: "Active",
                    color: .green
                )
                
                if criticalAlerts > 0 {
                    AdminHeaderMetric(
                        icon: "exclamationmark.triangle.fill",
                        value: "\(criticalAlerts)",
                        label: "Alerts",
                        color: .red
                    )
                }
            }
            
            // System Status
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(syncStatusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(syncStatus.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(syncStatusColor)
                }
                
                Text(Date().formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.9),
                    Color.black.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.white.opacity(0.1)),
            alignment: .bottom
        )
    }
}

struct AdminHeaderMetric: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

