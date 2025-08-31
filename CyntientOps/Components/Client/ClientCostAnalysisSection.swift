
//
//  ClientCostAnalysisSection.swift
//  CyntientOps
//
//  Created by Gemini on 2025-08-17.
//

import SwiftUI

struct ClientCostAnalysisSection: View {
    let monthlyMetrics: CoreTypes.MonthlyMetrics
    let costInsights: [CoreTypes.CostInsight]
    let estimatedSavings: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost Analysis")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("$\(Int(monthlyMetrics.currentSpend))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Current Spend")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("of $\(Int(monthlyMetrics.monthlyBudget)) budget")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                if estimatedSavings > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("$\(Int(estimatedSavings))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("Potential Savings")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("per month")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Budget Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Budget Utilization")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int((monthlyMetrics.currentSpend / monthlyMetrics.monthlyBudget) * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.cyan)
                            .frame(width: geometry.size.width * (monthlyMetrics.currentSpend / monthlyMetrics.monthlyBudget), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}
