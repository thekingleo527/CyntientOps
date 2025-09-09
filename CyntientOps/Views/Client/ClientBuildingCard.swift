//
//  ClientBuildingCard.swift
//  CyntientOps
//
//  Created by Gemini on 2025-08-17.
//

import SwiftUI
import UIKit

struct ClientBuildingCard: View {
    let building: CoreTypes.NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let onTap: () -> Void
    
    init(building: CoreTypes.NamedCoordinate, metrics: CoreTypes.BuildingMetrics?, onTap: @escaping () -> Void = {}) {
        self.building = building
        self.metrics = metrics
        self.onTap = onTap
    }
    
    var buildingImageAssetName: String? { BuildingAssetResolver.assetName(for: building) }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Building Image Header
                ZStack {
                    if let assetName = buildingImageAssetName,
                       let img = UIImage(named: assetName) {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 80)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.6), .purple.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(height: 80)
                            .overlay(
                                Image(systemName: "building.2")
                                    .font(.title)
                                    .foregroundColor(.white.opacity(0.8))
                            )
                    }
                    
                    // Status indicator overlay
                    VStack {
                        HStack {
                            Spacer()
                            if let metrics = metrics {
                                Circle()
                                    .fill(statusColor)
                                    .frame(width: 12, height: 12)
                                    .shadow(color: .black.opacity(0.3), radius: 2)
                            }
                        }
                        Spacer()
                    }
                    .padding(8)
                }
                
                // Building Info Section
                VStack(alignment: .leading, spacing: 8) {
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
                }
                .padding(12)
            }
            .frame(height: 120)
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
