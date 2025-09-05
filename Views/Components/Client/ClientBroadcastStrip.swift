import SwiftUI

struct ClientBroadcastStrip: View {
    let criticalViolations: Int
    let behindScheduleCount: Int
    let budgetOverrun: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .scaleEffect(1.1)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: criticalViolations)
            
            Text(message)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(statusColor.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(statusColor.opacity(0.25), lineWidth: 1)
                )
        )
    }
    
    private var statusColor: Color {
        if criticalViolations > 0 { return CyntientOpsDesign.DashboardColors.critical }
        if budgetOverrun { return CyntientOpsDesign.DashboardColors.warning }
        if behindScheduleCount > 0 { return CyntientOpsDesign.DashboardColors.info }
        return CyntientOpsDesign.DashboardColors.success
    }
    
    private var message: String {
        if criticalViolations > 0 {
            return "\(criticalViolations) critical compliance issues need attention"
        }
        if budgetOverrun {
            return "Budget running hot — review monthly utilization"
        }
        if behindScheduleCount > 0 {
            return "\(behindScheduleCount) tasks behind schedule across portfolio"
        }
        return "All systems nominal — portfolio operating smoothly"
    }
}

