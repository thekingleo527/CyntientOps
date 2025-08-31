
//
//  ClientDashboardHeader.swift
//  CyntientOps
//
//  Created by Gemini on 2025-08-17.
//

import SwiftUI

struct ClientDashboardHeader: View {
    let clientName: String
    let portfolioValue: Double
    let activeBuildings: Int
    let complianceScore: Int
    let onProfileTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Client Info
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(clientName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("Portfolio Owner")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Key Metrics
            HStack(spacing: 16) {
                ClientHeaderMetric(
                    icon: "building.2",
                    value: "\(activeBuildings)",
                    label: "Buildings",
                    color: .blue
                )
                
                ClientHeaderMetric(
                    icon: "shield.checkered",
                    value: "\(complianceScore)%",
                    label: "Compliance",
                    color: complianceScore >= 90 ? .green : .orange
                )
                
                ClientHeaderMetric(
                    icon: "dollarsign.circle",
                    value: "$\(Int(portfolioValue/1000))K",
                    label: "Budget",
                    color: .cyan
                )
            }
            
            // Profile Button
            Button(action: onProfileTap) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.9),
                    Color.purple.opacity(0.1)
                ],
                startPoint: .leading,
                endPoint: .trailing
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
