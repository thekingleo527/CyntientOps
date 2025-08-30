//
//  DSNYScheduleComponents.swift
//  CyntientOps v6.0
//
//  Shared DSNY schedule display components
//

import SwiftUI

public struct DSNYScheduleRow: View {
    let day: String
    let time: String
    let items: String
    let isToday: Bool
    
    public init(day: String, time: String, items: String, isToday: Bool) {
        self.day = day
        self.time = time
        self.items = items
        self.isToday = isToday
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(day)
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .medium)
                    .foregroundColor(isToday ? CyntientOpsDesign.DashboardColors.secondaryAction : CyntientOpsDesign.DashboardColors.primaryText)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(items)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                if isToday {
                    Text("Today")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryAction)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(CyntientOpsDesign.DashboardColors.secondaryAction.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.8) : CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.4))
        )
    }
}