//
//  MetricCard.swift
//  CyntientOps v6.0
//
//  ✅ SHARED COMPONENT: Universal metric card for all roles
//

import SwiftUI

public struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let style: MetricCardStyle
    
    public init(title: String, value: String, icon: String, color: Color, style: MetricCardStyle = .default) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.style = style
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .foregroundColor(style.primaryTextColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(style.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(style.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }
}

public enum MetricCardStyle {
    case `default`
    case admin
    case client
    case worker
    
    var backgroundColor: Color {
        switch self {
        case .default: return Color.secondary.opacity(0.2)
        case .admin: return CyntientOpsDesign.DashboardColors.adminAccent.opacity(0.1)
        case .client: return CyntientOpsDesign.DashboardColors.clientPrimary.opacity(0.1)
        case .worker: return CyntientOpsDesign.DashboardColors.workerAccent.opacity(0.1)
        }
    }
    
    var primaryTextColor: Color {
        return CyntientOpsDesign.DashboardColors.primaryText
    }
    
    var secondaryTextColor: Color {
        return CyntientOpsDesign.DashboardColors.tertiaryText
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .default, .admin, .client: return 8
        case .worker: return 12
        }
    }
}

// MARK: - Convenience Initializers
extension MetricCard {
    public static func admin(title: String, value: String, icon: String, color: Color = .blue) -> MetricCard {
        MetricCard(title: title, value: value, icon: icon, color: color, style: .admin)
    }
    
    public static func client(title: String, value: String, icon: String, color: Color = .green) -> MetricCard {
        MetricCard(title: title, value: value, icon: icon, color: color, style: .client)
    }
    
    public static func worker(title: String, value: String, icon: String, color: Color = .orange) -> MetricCard {
        MetricCard(title: title, value: value, icon: icon, color: color, style: .worker)
    }
}