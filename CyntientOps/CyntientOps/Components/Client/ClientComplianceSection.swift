
//
//  ClientComplianceSection.swift
//  CyntientOps
//
//  Created by Gemini on 2025-08-17.
//

import SwiftUI

struct ClientComplianceSection: View {
    let complianceOverview: CoreTypes.ComplianceOverview
    let criticalAlerts: [CoreTypes.ClientAlert]
    let onComplianceDetail: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Compliance & Alerts")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                StatusPill(
                    text: "\(Int(complianceOverview.overallScore * 100))%",
                    color: complianceOverview.overallScore >= 0.9 ? .green : .orange,
                    style: .filled
                )
                
                Spacer()
                
                Button(action: onComplianceDetail) {
                    Text("Details")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(complianceOverview.criticalViolations)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(complianceOverview.criticalViolations > 0 ? .red : .green)
                    
                    Text("Critical Violations")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(criticalAlerts.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(criticalAlerts.count > 0 ? .orange : .green)
                    
                    Text("Active Alerts")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(complianceOverview.overallScore >= 0.9 ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
