//
//  AccessModeComponents.swift
//  CyntientOps (formerly CyntientOps)
//
//  Extracted from CoverageInfoCard.swift - Reusable Access Mode Components
//  ✅ EXTRACTED: CoverageInfoCard, EmergencyAccessCard, TrainingAccessCard logic
//  ✅ ENHANCED: Modular, reusable components with improved functionality
//  ✅ INTEGRATED: WorkerBuildingAssignments, EmergencyContactService, StatusPill, WorkerAvatar
//

import SwiftUI

// MARK: - Base Access Card Component

public struct AccessModeCard: View {
    let building: NamedCoordinate
    let accessType: AccessType
    let onViewFullInfo: () -> Void
    
    // Services
    @StateObject private var emergencyService = EmergencyContactService.shared
    @State private var primaryWorker: String?
    @State private var isLoadingWorkerInfo = false
    @State private var isPressed = false
    @State private var pulseAnimation = false
    
    public init(building: NamedCoordinate, accessType: AccessType, onViewFullInfo: @escaping () -> Void) {
        self.building = building
        self.accessType = accessType
        self.onViewFullInfo = onViewFullInfo
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.md) {
            // Header with access type indication
            accessHeader
            
            // Description based on access type
            accessDescription
            
            // Primary worker info (for coverage and training modes)
            if accessType != .emergency {
                primaryWorkerSection
            }
            
            // Emergency-specific content
            if accessType == .emergency {
                emergencyContent
            }
            
            // Training-specific content
            if accessType == .training {
                trainingContent
            }
            
            // Main action button
            actionButton
        }
        .francoCardPadding()
        .background(backgroundView)
        .francoShadow(CyntientOpsDesign.Shadow.md)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(CyntientOpsDesign.Animations.quick, value: isPressed)
        .task {
            await loadPrimaryWorkerInfo()
            if accessType == .emergency {
                pulseAnimation = true
            }
        }
    }
    
    // MARK: - Access Header
    
    private var accessHeader: some View {
        HStack(spacing: CyntientOpsDesign.Spacing.sm) {
            // Access type icon with animation
            ZStack {
                Circle()
                    .fill(accessType.color.opacity(0.15))
                    .frame(width: accessType == .emergency ? 48 : 44, height: accessType == .emergency ? 48 : 44)
                
                Image(systemName: accessType.icon)
                    .font(accessType == .emergency ? .title2 : .title2)
                    .foregroundColor(accessType.color)
            }
            .overlay(
                // Pulse animation for emergency
                Group {
                    if accessType == .emergency {
                        Circle()
                            .stroke(accessType.color.opacity(0.3), lineWidth: 2)
                            .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                            .opacity(pulseAnimation ? 0 : 1)
                            .animation(
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                                value: pulseAnimation
                            )
                    }
                }
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(accessType.title)
                    .francoTypography(CyntientOpsDesign.Typography.headline)
                    .foregroundColor(accessType.color)
                
                Text(accessType.subtitle)
                    .francoTypography(CyntientOpsDesign.Typography.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            // Emergency timestamp or current user indicator
            if accessType == .emergency {
                emergencyTimestamp
            } else {
                currentUserIndicator
            }
        }
    }
    
    // MARK: - Access Description
    
    private var accessDescription: some View {
        VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.xs) {
            Text(accessType.primaryDescription)
                .francoTypography(CyntientOpsDesign.Typography.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if let secondaryDesc = accessType.secondaryDescription {
                Text(secondaryDesc)
                    .francoTypography(CyntientOpsDesign.Typography.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Primary Worker Section
    
    private var primaryWorkerSection: some View {
        VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.xs) {
            Text("Primary Coverage")
                .francoTypography(CyntientOpsDesign.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if isLoadingWorkerInfo {
                loadingWorkerView
            } else if let worker = primaryWorker {
                WorkerInfoRow(
                    workerName: worker,
                    subtitle: "Primary Worker",
                    status: .available
                )
            } else {
                noWorkerAssignedView
            }
        }
        .padding(CyntientOpsDesign.Spacing.sm)
        .francoGlassBackground(cornerRadius: CyntientOpsDesign.CornerRadius.md)
    }
    
    // MARK: - Emergency Content
    
    private var emergencyContent: some View {
        VStack(spacing: CyntientOpsDesign.Spacing.sm) {
            // Emergency note
            emergencyNote
            
            // Quick emergency contacts
            emergencyQuickActions
        }
    }
    
    // MARK: - Training Content
    
    private var trainingContent: some View {
        VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.xs) {
            Text("Training Progress")
                .francoTypography(CyntientOpsDesign.Typography.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            HStack {
                Text("0% Complete")
                    .francoTypography(CyntientOpsDesign.Typography.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                
                Spacer()
            }
            
            FrancoMetricsProgress(value: 0, role: .worker)
                .frame(height: 4)
        }
        .padding(CyntientOpsDesign.Spacing.sm)
        .francoGlassBackground(cornerRadius: CyntientOpsDesign.CornerRadius.sm)
    }
    
    // MARK: - Supporting Views
    
    private var emergencyTimestamp: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("EMERGENCY")
                .francoTypography(CyntientOpsDesign.Typography.caption2)
                .fontWeight(.bold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
            
            Text(Date().formatted(.dateTime.hour().minute()))
                .francoTypography(CyntientOpsDesign.Typography.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
    }
    
    private var currentUserIndicator: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("You")
                .francoTypography(CyntientOpsDesign.Typography.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            
            Text("Coverage Access")
                .francoTypography(CyntientOpsDesign.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        }
    }
    
    private var loadingWorkerView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
                .tint(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text("Loading worker information...")
                .francoTypography(CyntientOpsDesign.Typography.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
        .padding(CyntientOpsDesign.Spacing.sm)
    }
    
    private var noWorkerAssignedView: some View {
        HStack(spacing: CyntientOpsDesign.Spacing.sm) {
            Circle()
                .fill(CyntientOpsDesign.DashboardColors.glassOverlay)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("No primary worker assigned")
                    .francoTypography(CyntientOpsDesign.Typography.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                
                Text("Contact management for assistance")
                    .francoTypography(CyntientOpsDesign.Typography.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            
            Spacer()
        }
    }
    
    private var emergencyNote: some View {
        HStack(spacing: CyntientOpsDesign.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
            
            Text("Emergency situation detected. Full access to all building systems and procedures authorized.")
                .francoTypography(CyntientOpsDesign.Typography.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .padding(CyntientOpsDesign.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.sm)
                .fill(CyntientOpsDesign.DashboardColors.critical.opacity(0.1))
        )
    }
    
    private var emergencyQuickActions: some View {
        HStack(spacing: CyntientOpsDesign.Spacing.sm) {
            EmergencyActionButton(
                title: "911"
            ) {
                emergencyService.makeEmergencyCall(.primary911, buildingId: building.id)
            }
            
            EmergencyActionButton(
                title: "Security",
                isPrimary: false
            ) {
                let contacts = emergencyService.getEmergencyContacts(for: building.id)
                if let security = contacts.first(where: { $0.type == .buildingSecurity }) {
                    emergencyService.makeEmergencyCall(security, buildingId: building.id)
                }
            }
            
            Spacer()
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.lg)
            .fill(accessType.color.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.lg)
                    .stroke(accessType.color.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var actionButton: some View {
        Button(action: {
            withAnimation(CyntientOpsDesign.Animations.quick) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(CyntientOpsDesign.Animations.quick) {
                    isPressed = false
                }
                onViewFullInfo()
            }
        }) {
            HStack(spacing: CyntientOpsDesign.Spacing.xs) {
                Image(systemName: accessType.actionIcon)
                    .font(.subheadline)
                
                Text(accessType.actionTitle)
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.md)
                    .fill(accessType.color)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Data Loading
    
    private func loadPrimaryWorkerInfo() async {
        isLoadingWorkerInfo = true
        
        // Use WorkerBuildingAssignments to get primary worker
        let worker = WorkerBuildingAssignments.getPrimaryWorker(for: building.id)
        
        await MainActor.run {
            self.primaryWorker = worker
            self.isLoadingWorkerInfo = false
        }
    }
}

// MARK: - Access Type Definition

public enum AccessType {
    case coverage
    case emergency
    case training
    
    var title: String {
        switch self {
        case .coverage: return "Coverage Mode"
        case .emergency: return "Emergency Access"
        case .training: return "Training Mode"
        }
    }
    
    var subtitle: String {
        switch self {
        case .coverage: return "Emergency/Support Access"
        case .emergency: return "Complete building access authorized"
        case .training: return "Cross-training access"
        }
    }
    
    var icon: String {
        switch self {
        case .coverage: return "info.circle.fill"
        case .emergency: return "exclamationmark.triangle.fill"
        case .training: return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .coverage: return CyntientOpsDesign.DashboardColors.warning
        case .emergency: return CyntientOpsDesign.DashboardColors.critical
        case .training: return CyntientOpsDesign.DashboardColors.info
        }
    }
    
    var primaryDescription: String {
        switch self {
        case .coverage:
            return "This building is not in your regular assignments."
        case .emergency:
            return "Emergency situation detected. You have full access to all building information and emergency procedures."
        case .training:
            return "You're accessing this building for training purposes. View complete procedures and learn the systems."
        }
    }
    
    var secondaryDescription: String? {
        switch self {
        case .coverage:
            return "You have access to complete building information for coverage support, emergency situations, or cross-training purposes."
        case .emergency, .training:
            return nil
        }
    }
    
    var actionTitle: String {
        switch self {
        case .coverage: return "View Complete Building Intelligence"
        case .emergency: return "Access Emergency Information"
        case .training: return "Access Training Materials"
        }
    }
    
    var actionIcon: String {
        switch self {
        case .coverage: return "brain.head.profile"
        case .emergency: return "shield.lefthalf.filled"
        case .training: return "graduationcap.fill"
        }
    }
}

// MARK: - Emergency Action Button (Extracted and Enhanced)

public struct EmergencyActionButton: View {
    let title: String
    let isPrimary: Bool
    let action: () -> Void
    
    public init(title: String, isPrimary: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isPrimary = isPrimary
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .francoTypography(CyntientOpsDesign.Typography.caption)
                .fontWeight(isPrimary ? .bold : .medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.sm)
                        .fill(isPrimary ?
                            CyntientOpsDesign.DashboardColors.critical :
                            CyntientOpsDesign.DashboardColors.warning
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Access Type Detector

public struct AccessTypeDetector {
    
    /// Determine access type based on worker and building relationship
    public static func getAccessType(
        worker: String,
        buildingId: String,
        isEmergency: Bool = false,
        isTraining: Bool = false
    ) -> AccessType {
        if isEmergency {
            return .emergency
        }
        
        if isTraining {
            return .training
        }
        
        // Check if worker has primary assignment to this building
        let assignedBuildings = WorkerBuildingAssignments.getAssignedBuildings(for: worker)
        return assignedBuildings.contains(buildingId) ? .coverage : .coverage
    }
}

// MARK: - Preview

struct AccessModeComponents_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuilding = NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            address: "150 W 17th St",
            latitude: 40.7402,
            longitude: -73.9980
        )
        
        ScrollView {
            VStack(spacing: CyntientOpsDesign.Spacing.lg) {
                AccessModeCard(building: sampleBuilding, accessType: .coverage) {
                    print("Coverage mode tapped")
                }
                
                AccessModeCard(building: sampleBuilding, accessType: .emergency) {
                    print("Emergency mode tapped")
                }
                
                AccessModeCard(building: sampleBuilding, accessType: .training) {
                    print("Training mode tapped")
                }
            }
            .padding()
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .preferredColorScheme(.dark)
    }
}