//
//  AdminMetricCard.swift
//  CyntientOps Phase 4
//
//  Admin metric display card for dashboard overview
//

import SwiftUI

struct AdminMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let onTap: (() -> Void)?
    
    init(icon: String, title: String, value: String, color: Color, onTap: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
        self.onTap = onTap
    }
    
    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            // Content
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(onTap != nil ? 0.08 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(onTap != nil ? 0.4 : 0.3), lineWidth: 1)
                )
        )
        .scaleEffect(onTap != nil ? 1.0 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: onTap != nil)
    }
}

#if DEBUG
struct AdminMetricCard_Previews: PreviewProvider {
    static var previews: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            AdminMetricCard(
                icon: "building.2",
                title: "Buildings",
                value: "16",
                color: .blue
            )
            
            AdminMetricCard(
                icon: "person.3.fill",
                title: "Workers",
                value: "5/7",
                color: .green
            )
            
            AdminMetricCard(
                icon: "list.bullet",
                title: "Ongoing Tasks",
                value: "124",
                color: .orange
            )
            
            AdminMetricCard(
                icon: "checkmark.circle.fill",
                title: "Completed Today",
                value: "87",
                color: .cyan
            )
            
            AdminMetricCard(
                icon: "exclamationmark.triangle.fill",
                title: "Critical Insights",
                value: "3",
                color: .red
            )
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif