//
//  AdminRealtimeSection.swift
//  CyntientOps Phase 4
//
//  Real-time activity section showing cross-dashboard updates
//

import SwiftUI

struct AdminRealtimeSection: View {
    let updates: [CoreTypes.DashboardUpdate]
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
                    
                    Text("Real-time Activity")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                StatusPill(text: "\(updates.count)", color: .green, style: .filled)
                
                Spacer()
                
                Button(action: onViewAll) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Activity List
            VStack(spacing: 8) {
                ForEach(updates.prefix(4)) { update in
                    AdminActivityRow(update: update)
                }
                
                if updates.count > 4 {
                    Button(action: onViewAll) {
                        HStack {
                            Text("+ \(updates.count - 4) more activities")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct AdminActivityRow: View {
    let update: CoreTypes.DashboardUpdate
    
    private var sourceColor: Color {
        switch update.source {
        case .worker: return .green
        case .admin: return .blue
        case .client: return .purple
        case .system: return .gray
        }
    }
    
    private var sourceIcon: String {
        switch update.source {
        case .worker: return "person.fill"
        case .admin: return "person.badge.key.fill"
        case .client: return "building.2.fill"
        case .system: return "gear.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Source Indicator
            ZStack {
                Circle()
                    .fill(sourceColor.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Image(systemName: sourceIcon)
                    .font(.system(size: 12))
                    .foregroundColor(sourceColor)
            }
            
            // Update Content
            VStack(alignment: .leading, spacing: 2) {
                Text(update.description ?? "No description")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(update.source.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(sourceColor)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(update.timestamp.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    if let buildingName = update.data["buildingName"] {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Text(buildingName)
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // Update Type Badge
            if update.type == .criticalUpdate {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            } else if update.type == .taskCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}

#if DEBUG
struct AdminRealtimeSection_Previews: PreviewProvider {
    static var previews: some View {
        let mockUpdates = [
            CoreTypes.DashboardUpdate(
                id: "1",
                source: .worker,
                type: .taskCompleted,
                buildingId: "14",
                workerId: "4",
                data: ["buildingName": "Rubin Museum", "workerName": "Kevin Dutan"],
                timestamp: Date().addingTimeInterval(-300),
                description: "Kevin completed cleaning task at Rubin Museum"
            ),
            CoreTypes.DashboardUpdate(
                id: "2", 
                source: .worker,
                type: .workerClockedIn,
                buildingId: "1",
                workerId: "2",
                data: ["buildingName": "JM Building A", "workerName": "Mercedes Inamagua"],
                timestamp: Date().addingTimeInterval(-600),
                description: "Mercedes clocked in at JM Building A"
            ),
            CoreTypes.DashboardUpdate(
                id: "3",
                source: .system,
                type: .buildingMetricsChanged,
                buildingId: "5",
                workerId: "system",
                data: ["buildingName": "Solar One Building"],
                timestamp: Date().addingTimeInterval(-900),
                description: "Building metrics updated for efficiency tracking"
            ),
            CoreTypes.DashboardUpdate(
                id: "4",
                source: .system,
                type: .criticalUpdate,
                buildingId: "6",
                workerId: "system",
                data: ["buildingName": "Grand Elizabeth LLC"],
                timestamp: Date().addingTimeInterval(-1200),
                description: "Emergency maintenance required at Grand Elizabeth"
            )
        ]
        
        AdminRealtimeSection(
            updates: mockUpdates,
            onViewAll: {}
        )
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif