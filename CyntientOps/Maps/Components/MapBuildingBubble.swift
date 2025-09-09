import SwiftUI
import UIKit

// Enhanced Building Marker with Image Support
struct MapBuildingBubble: View {
    let building: NamedCoordinate
    let isSelected: Bool
    let isFocused: Bool
    let isInteractive: Bool
    let isAssigned: Bool
    let isVisited: Bool
    let metrics: BuildingMetrics?
    var onTap: (() -> Void)?
    var onHover: ((Bool) -> Void)?

    @State private var isPressed = false

    var body: some View {
        Button(action: { onTap?() }) {
            ZStack {
                if isFocused || isSelected {
                    Circle()
                        .fill(ringColor.opacity(0.3))
                        .frame(width: 65, height: 65)
                        .blur(radius: 2)
                }

                if let _ = BuildingAssetResolver.assetName(for: building),
                   let _ = BuildingAssetResolver.uiImage(for: building) {
                    buildingImageBubble
                } else {
                    iconBubble
                }

                if let metrics = metrics {
                    statusIndicator(metrics)
                }

                if isVisited {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        .offset(x: -18, y: -18)
                }

                if isSelected {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .background(Circle().fill(.white).frame(width: 16, height: 16))
                        .offset(x: 20, y: -20)
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .scaleEffect(isFocused ? 1.15 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isInteractive)
        .onHover { hovering in
            onHover?(hovering)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    @ViewBuilder
    private var buildingImageBubble: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 55, height: 55)

            if let uiImage = BuildingAssetResolver.uiImage(for: building) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 2)
                    )
                    .overlay(
                        selectedOverlay
                    )
            } else {
                iconBubbleContent
            }
        }
        .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
    }

    @ViewBuilder
    private var iconBubble: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 2)
                )

            iconBubbleContent
        }
        .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private var iconBubbleContent: some View {
        VStack(spacing: 0) {
            Image(systemName: buildingIcon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
        }
    }

    @ViewBuilder
    private var selectedOverlay: some View {
        // No overlay needed - the yellow star badge handles current location indication
        EmptyView()
    }

    private var ringColor: Color {
        if isSelected {
            return .green
        } else if let metrics = metrics {
            return riskColor(for: metrics)
        } else {
            return .blue
        }
    }

    private var borderColor: Color {
        if isSelected {
            return .green
        } else if let metrics = metrics {
            return riskColor(for: metrics).opacity(0.8)
        } else {
            return .white.opacity(0.3)
        }
    }

    private var shadowColor: Color {
        if isSelected {
            return .green.opacity(0.5)
        } else if isFocused {
            return .blue.opacity(0.5)
        } else {
            return .black.opacity(0.3)
        }
    }

    private var buildingIcon: String {
        let name = building.name.lowercased()

        if name.contains("museum") || name.contains("rubin") {
            return "building.columns.fill"
        } else if name.contains("park") || name.contains("stuyvesant") || name.contains("cove") {
            return "leaf.fill"
        } else if name.contains("perry") || name.contains("elizabeth") || name.contains("walker") {
            return "house.fill"
        } else if name.contains("west") || name.contains("east") || name.contains("franklin") {
            return "building.2.fill"
        } else if name.contains("avenue") {
            return "building.fill"
        } else {
            return "building.2.fill"
        }
    }

    private var iconColor: Color {
        if isSelected { return .green }
        if isAssigned { return .blue }
        if isVisited { return .purple }
        return .gray
    }

    @ViewBuilder
    private func statusIndicator(_ metrics: BuildingMetrics) -> some View {
        if metrics.urgentTasksCount > 0 {
            ZStack {
                Circle()
                    .fill(.red)
                    .frame(width: 20, height: 20)

                Text("\(metrics.urgentTasksCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .offset(x: 18, y: -18)
        }
    }

    private func riskColor(for metrics: BuildingMetrics) -> Color {
        if metrics.overdueTasks > 0 || metrics.urgentTasksCount > 0 {
            return .red
        } else if metrics.completionRate < 0.7 {
            return .orange
        } else {
            return .green
        }
    }
}
