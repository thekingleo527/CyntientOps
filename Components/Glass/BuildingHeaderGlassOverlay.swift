//
//  BuildingHeaderGlassOverlay.swift
//  CyntientOps v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Integrated with CyntientOpsDesign color system
//  ✅ IMPROVED: Glass effects optimized for dark theme
//  ✅ FIXED: Works with NamedCoordinate that doesn't have imageAssetName
//

import SwiftUI

struct BuildingHeaderGlassOverlay: View {
    let building: NamedCoordinate
    let clockedInStatus: (isClockedIn: Bool, buildingId: Int64?)
    let onClockAction: () -> Void
    
    @State private var isImageLoaded = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Building image background
            buildingImageBackground
            
            // Glass overlay with building info
            VStack(spacing: 0) {
                Spacer()
                
                // Glass card with dark theme
                VStack(alignment: .leading, spacing: 16) {
                    // Main building info row
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(building.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                                .multilineTextAlignment(.leading)
                            
                            // Location information using coordinates
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                                
                                Text(getFormattedLocation())
                                    .font(.caption)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                                    .lineLimit(2)
                            }
                            
                            // Coordinates for technical reference
                            Text("Lat: \(String(format: "%.4f", building.latitude)), Lon: \(String(format: "%.4f", building.longitude))")
                                .font(.caption2)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                                .monospaced()
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 12) {
                            // Building status badge
                            buildingStatusBadge
                            
                            // Clock status and action
                            clockStatusSection
                        }
                    }
                    
                    // Building metrics row
                    buildingMetricsRow
                }
                .padding(20)
                .background(darkGlassBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(glassOverlayBorder)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(height: 280)
        .animation(.easeInOut(duration: 0.3), value: isImageLoaded)
    }
    
    // MARK: - Sub-components
    
    private var buildingImageBackground: some View {
        Group {
            let imageName = getBuildingImageName()
            
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 280)
                    .clipped()
                    .overlay(darkImageOverlay)
                    .onAppear { isImageLoaded = true }
            } else {
                // Fallback gradient with building icon
                ZStack {
                    LinearGradient(
                        colors: [
                            CyntientOpsDesign.DashboardColors.info.opacity(0.3),
                            CyntientOpsDesign.DashboardColors.info.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.info.opacity(0.3))
                }
                .frame(height: 280)
                .overlay(darkImageOverlay)
            }
        }
    }
    
    private var darkImageOverlay: some View {
        LinearGradient(
            colors: [
                CyntientOpsDesign.DashboardColors.baseBackground.opacity(0.3),
                Color.clear,
                CyntientOpsDesign.DashboardColors.baseBackground.opacity(0.8)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var darkGlassBackground: some View {
        ZStack {
            // Dark base
            RoundedRectangle(cornerRadius: 20)
                .fill(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.9))
            
            // Glass material
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.3))
            
            // Gradient overlay
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            CyntientOpsDesign.DashboardColors.glassOverlay.opacity(0.2),
                            CyntientOpsDesign.DashboardColors.glassOverlay.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    private var glassOverlayBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    private var buildingStatusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(CyntientOpsDesign.DashboardColors.success)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(CyntientOpsDesign.DashboardColors.success.opacity(0.3), lineWidth: 8)
                        .scaleEffect(1.5)
                        .opacity(0.6)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: true)
                )
            
            Text("Operational")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(CyntientOpsDesign.DashboardColors.success.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(CyntientOpsDesign.DashboardColors.success.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(20)
    }
    
    private var clockStatusSection: some View {
        VStack(spacing: 8) {
            if isClockedInCurrentBuilding {
                // Clocked in indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.success)
                        .frame(width: 8, height: 8)
                    
                    Text("On Site")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(CyntientOpsDesign.DashboardColors.success.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(CyntientOpsDesign.DashboardColors.success.opacity(0.4), lineWidth: 1)
                )
                .cornerRadius(16)
            }
            
            // Clock action button
            Button(action: onClockAction) {
                HStack(spacing: 6) {
                    Image(systemName: isClockedInCurrentBuilding ? "clock.badge.xmark" : "clock.badge.checkmark")
                        .font(.caption)
                    
                    Text(isClockedInCurrentBuilding ? "Clock Out" : "Clock In")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(CyntientOpsDesign.DashboardColors.glassOverlay)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(20)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var buildingMetricsRow: some View {
        HStack(spacing: 20) {
            buildingMetric(
                icon: "building.2",
                label: "Building ID",
                value: building.id
            )
            
            Divider()
                .frame(height: 30)
                .background(CyntientOpsDesign.DashboardColors.glassOverlay)
            
            buildingMetric(
                icon: "map",
                label: "District",
                value: getDistrict()
            )
            
            Divider()
                .frame(height: 30)
                .background(CyntientOpsDesign.DashboardColors.glassOverlay)
            
            buildingMetric(
                icon: "person.2",
                label: "Type",
                value: getBuildingType()
            )
        }
    }
    
    private func buildingMetric(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var isClockedInCurrentBuilding: Bool {
        clockedInStatus.isClockedIn &&
        clockedInStatus.buildingId == Int64(building.id)
    }
    
    // MARK: - Helper Methods
    
    private func getBuildingImageName() -> String {
        // Map building IDs to their image assets
        switch building.id {
        case "14", "15":
            return "Rubin_Museum_142_148_West_17th_Street"
        case "1":
            return "building_12w18"
        case "2":
            return "building_29e20"
        case "3":
            return "building_133e15"
        case "4":
            return "building_104franklin"
        case "5":
            return "building_36walker"
        case "6":
            return "building_68perry"
        case "7":
            return "building_136w17"
        case "8":
            return "building_41elizabeth"
        case "9":
            return "building_117w17"
        case "10":
            return "building_123first"
        case "11":
            return "building_131perry"
        case "12":
            return "building_135w17"
        case "13":
            return "building_138w17"
        case "16":
            return "stuyvesant_park"
        default:
            // Try to create a name from the building name
            let cleanName = building.name
                .lowercased()
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: "-", with: "_")
            return cleanName
        }
    }
    
    private func getFormattedLocation() -> String {
        let district = getDistrict()
        let buildingType = getBuildingType()
        return "\(district) • \(buildingType)"
    }
    
    private func getDistrict() -> String {
        // Determine NYC district based on building name/address
        let name = building.name.lowercased()
        if name.contains("west") || name.contains("17th") || name.contains("18th") {
            return "Chelsea"
        } else if name.contains("east") || name.contains("20th") || name.contains("15th") {
            return "Union Sq"
        } else if name.contains("walker") || name.contains("franklin") || name.contains("elizabeth") {
            return "SoHo"
        } else if name.contains("perry") {
            return "West Village"
        } else if name.contains("1st ave") {
            return "East Village"
        } else if name.contains("stuyvesant") {
            return "Waterfront"
        }
        return "Midtown"
    }
    
    private func getBuildingType() -> String {
        if building.name.contains("Museum") {
            return "Museum"
        } else if building.name.contains("Park") {
            return "Public"
        } else {
            return "Residential"
        }
    }
}

// MARK: - Preview

struct BuildingHeaderGlassOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            CyntientOpsDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            VStack {
                BuildingHeaderGlassOverlay(
                    building: NamedCoordinate(
                        id: "15",
                        name: "Rubin Museum (142-148 W 17th)",
                        latitude: 40.740370,
                        longitude: -73.998120
                    ),
                    clockedInStatus: (true, 15),
                    onClockAction: {
                        print("Clock action tapped")
                    }
                )
                
                Spacer()
                
                // Example without image
                BuildingHeaderGlassOverlay(
                    building: NamedCoordinate(
                        id: "99",
                        name: "New Building Complex",
                        latitude: 40.750000,
                        longitude: -74.000000
                    ),
                    clockedInStatus: (false, nil),
                    onClockAction: {
                        print("Clock action tapped")
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}
