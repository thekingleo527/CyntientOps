
//
//  ClientBuildingCard.swift
//  CyntientOps
//
//  Created by Gemini on 2025-08-17.
//

import SwiftUI

struct ClientBuildingCard: View {
    let building: CoreTypes.NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let onTap: () -> Void
    
    init(building: CoreTypes.NamedCoordinate, metrics: CoreTypes.BuildingMetrics?, onTap: @escaping () -> Void = {}) {
        self.building = building
        self.metrics = metrics
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "building.2")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if let metrics = metrics {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(building.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let metrics = metrics {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(metrics.completionRate * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if metrics.criticalIssues > 0 {
                            Text("\(metrics.criticalIssues) issues")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(12)
            .frame(height: 100)
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
    
    private var statusColor: Color {
        guard let metrics = metrics else { return .gray }
        if metrics.criticalIssues > 0 { return .red }
        if metrics.completionRate >= 0.9 { return .green }
        return .orange
    }
}
