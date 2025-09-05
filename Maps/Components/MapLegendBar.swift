import SwiftUI

struct MapLegendBar: View {
    let buildingCount: Int
    let hasCurrent: Bool
    let isVisible: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All buildings chip
                LegendChip(
                    label: "All",
                    icon: "circle.grid.2x2",
                    count: buildingCount,
                    color: .blue
                )
                
                // Assigned buildings chip
                LegendChip(
                    label: "Assigned",
                    icon: "person.badge.key",
                    count: nil,
                    color: .orange
                )
                
                // Visited buildings chip
                LegendChip(
                    label: "Visited",
                    icon: "checkmark.seal",
                    count: nil,
                    color: .green
                )
                
                // Current site chip - only show if there's a current building
                // Remove the big green checkmark when current site star is present
                if hasCurrent {
                    LegendChip(
                        label: "Current Site",
                        icon: "star.fill",
                        count: nil,
                        color: .yellow
                    )
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .allowsHitTesting(false)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.3).delay(0.2), value: isVisible)
    }
}

// MARK: - Legend Chip Component
struct LegendChip: View {
    let label: String
    let icon: String
    let count: Int?
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(color)
                .frame(width: 10, height: 10)
            
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .default))
                .foregroundColor(.white)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            
            if let count = count {
                Text("\(count)")
                    .font(.system(size: 9, weight: .bold, design: .default))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
        .fixedSize()
    }
}

