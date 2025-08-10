//
//  SmartWorkerHeroCard.swift
//  CyntientOps v6.0
//
//  Enhanced collapsible hero card with intelligent content prioritization
//  Expands from 80px to 320px with smart context-aware content
//  Automatically prioritizes time-sensitive information
//

import SwiftUI
import CoreLocation

struct SmartWorkerHeroCard: View {
    @Binding var isExpanded: Bool
    
    // Core data
    let workerProfile: CoreTypes.WorkerProfile?
    let currentBuilding: CoreTypes.NamedCoordinate?
    let weatherData: CoreTypes.WeatherData?
    let taskProgress: CoreTypes.TaskProgress
    let clockInStatus: ClockInStatus
    let syncStatus: SyncStatus
    let capabilities: WorkerCapabilities?
    
    // Smart context data
    let urgentTasks: [CoreTypes.ContextualTask]
    let nextTasks: [CoreTypes.ContextualTask]
    let todaysMetrics: TodaysMetrics
    let contextualAlerts: [ContextualAlert]
    
    // Action callbacks
    let onClockAction: () -> Void
    let onTaskTap: (CoreTypes.ContextualTask) -> Void
    let onEmergencyTap: () -> Void
    let onNavigateToBuilding: () -> Void
    let onSyncTap: () -> Void
    
    // Smart prioritization state
    @State private var prioritizedContent: [ContentPriority] = []
    @State private var currentTimeContext: TimeContext = .morning
    
    enum ClockInStatus {
        case notClockedIn
        case clockedIn(building: String, time: Date, location: CLLocation?)
    }
    
    enum SyncStatus {
        case synced
        case syncing(progress: Double)
        case offline
        case error(String)
    }
    
    struct WorkerCapabilities {
        let canUploadPhotos: Bool
        let canAddNotes: Bool
        let canViewMap: Bool
        let canAddEmergencyTasks: Bool
        let requiresPhotoForSanitation: Bool
        let simplifiedInterface: Bool
    }
    
    struct TodaysMetrics {
        let hoursWorked: Double
        let photosUploaded: Int
        let distanceWalked: Double
        let efficiency: Double
        let completionRate: Double
    }
    
    struct ContextualAlert {
        let id = UUID()
        let title: String
        let message: String
        let priority: AlertPriority
        let actionRequired: Bool
        let deadline: Date?
        
        enum AlertPriority {
            case low, medium, high, critical
            
            var color: Color {
                switch self {
                case .low: return CyntientOpsDesign.DashboardColors.info
                case .medium: return .orange
                case .high: return CyntientOpsDesign.DashboardColors.warning
                case .critical: return CyntientOpsDesign.DashboardColors.critical
                }
            }
        }
    }
    
    enum ContentPriority: Identifiable {
        case urgentTasks
        case weatherAlert
        case dsnyDeadline
        case clockInReminder
        case syncIssue
        case photoRequirement
        case buildingSpecificInfo
        case efficiencyInsight
        case routeOptimization
        
        var id: String { String(describing: self) }
        
        var weight: Int {
            switch self {
            case .urgentTasks: return 10
            case .dsnyDeadline: return 9
            case .weatherAlert: return 8
            case .syncIssue: return 7
            case .clockInReminder: return 6
            case .photoRequirement: return 5
            case .buildingSpecificInfo: return 4
            case .routeOptimization: return 3
            case .efficiencyInsight: return 2
            }
        }
    }
    
    enum TimeContext {
        case morning, midday, afternoon, evening
        
        static func current() -> TimeContext {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 5..<12: return .morning
            case 12..<17: return .midday
            case 17..<20: return .afternoon
            default: return .evening
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedContent
                    .frame(minHeight: 320)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            } else {
                collapsedContent
                    .frame(height: 80)
                    .transition(.identity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            CyntientOpsDesign.DashboardColors.cardBackground,
                            CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(CyntientOpsDesign.DashboardColors.borderColor.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            updateContentPrioritization()
            currentTimeContext = TimeContext.current()
        }
        .onChange(of: urgentTasks) { _ in updateContentPrioritization() }
        .onChange(of: contextualAlerts) { _ in updateContentPrioritization() }
    }
    
    // MARK: - Collapsed Content
    
    private var collapsedContent: some View {
        Button(action: {
            withAnimation(CyntientOpsDesign.Animations.spring) {
                isExpanded = true
            }
        }) {
            HStack(spacing: 12) {
                // Status Indicator with Smart Context
                statusIndicator
                
                // Worker Info
                if let worker = workerProfile {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(worker.name.split(separator: " ").first?.description ?? worker.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            .lineLimit(1)
                        
                        Text(smartContextSummary)
                            .font(.system(size: 11))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Smart Priority Indicator
                if let topPriority = prioritizedContent.first {
                    priorityIndicator(topPriority)
                }
                
                // Progress Ring (Mini)
                ZStack {
                    Circle()
                        .stroke(CyntientOpsDesign.DashboardColors.inactive.opacity(0.3), lineWidth: 3)
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .trim(from: 0, to: taskProgress.completionRate)
                        .stroke(
                            LinearGradient(
                                colors: [CyntientOpsDesign.DashboardColors.info, CyntientOpsDesign.DashboardColors.success],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(taskProgress.completionRate * 100))")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
                
                // Expand Indicator
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Expanded Content
    
    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Header with Collapse Button
            HStack {
                if let worker = workerProfile {
                    HStack(spacing: 12) {
                        // Worker Avatar
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.gray.opacity(0.8), .gray.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(worker.name.prefix(1).uppercased())
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contextualGreeting(for: worker.name))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            
                            HStack(spacing: 8) {
                                clockInStatusView
                                
                                if let building = currentBuilding {
                                    Button(action: onNavigateToBuilding) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "location.fill")
                                                .font(.system(size: 10))
                                            Text(building.name)
                                                .font(.system(size: 12))
                                        }
                                        .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(CyntientOpsDesign.Animations.spring) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                        .padding(8)
                        .background(Circle().fill(CyntientOpsDesign.DashboardColors.glassOverlay))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Smart Content Area
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(prioritizedContent.prefix(4)) { priority in
                        smartContentCard(for: priority)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)
            
            // Progress Section
            VStack(spacing: 12) {
                HStack {
                    Text("Today's Progress")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Spacer()
                    
                    Text("\(taskProgress.completedTasks)/\(taskProgress.totalTasks) tasks")
                        .font(.system(size: 12))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                // Enhanced Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(CyntientOpsDesign.DashboardColors.inactive.opacity(0.3))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [CyntientOpsDesign.DashboardColors.info, CyntientOpsDesign.DashboardColors.success],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * taskProgress.completionRate, height: 8)
                    }
                }
                .frame(height: 8)
                
                // Quick Stats
                HStack(spacing: 16) {
                    quickStat("Hours", value: String(format: "%.1f", todaysMetrics.hoursWorked))
                    quickStat("Photos", value: "\(todaysMetrics.photosUploaded)")
                    quickStat("Walked", value: String(format: "%.1f mi", todaysMetrics.distanceWalked))
                    quickStat("Efficiency", value: "\(Int(todaysMetrics.efficiency * 100))%")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Action Buttons
            HStack(spacing: 12) {
                // Primary Clock Action
                Button(action: onClockAction) {
                    HStack(spacing: 8) {
                        Image(systemName: clockIcon)
                            .font(.system(size: 16, weight: .medium))
                        Text(clockText)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(clockColor)
                    .cornerRadius(12)
                }
                
                // Emergency Button (if capability exists)
                if capabilities?.canAddEmergencyTasks == true {
                    Button(action: onEmergencyTap) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                            .frame(width: 48, height: 48)
                            .background(CyntientOpsDesign.DashboardColors.critical.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                
                // Sync Button
                Button(action: onSyncTap) {
                    Image(systemName: syncIcon)
                        .font(.system(size: 16))
                        .foregroundColor(syncColor)
                        .frame(width: 48, height: 48)
                        .background(syncColor.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Smart Content Prioritization
    
    private func updateContentPrioritization() {
        var priorities: [ContentPriority] = []
        
        // Urgent tasks always top priority
        if !urgentTasks.isEmpty {
            priorities.append(.urgentTasks)
        }
        
        // DSNY deadlines are critical
        let dsnyTasks = urgentTasks.filter { $0.title.lowercased().contains("dsny") || $0.title.lowercased().contains("trash") }
        if !dsnyTasks.isEmpty {
            priorities.append(.dsnyDeadline)
        }
        
        // Weather alerts
        if let weather = weatherData, weather.condition == .rain || weather.condition == .snow {
            priorities.append(.weatherAlert)
        }
        
        // Clock in reminders (morning context)
        if case .notClockedIn = clockInStatus, currentTimeContext == .morning {
            priorities.append(.clockInReminder)
        }
        
        // Sync issues
        if case .error = syncStatus {
            priorities.append(.syncIssue)
        }
        
        // Photo requirements
        let photoTasks = nextTasks.filter { $0.requiresPhoto == true }
        if !photoTasks.isEmpty {
            priorities.append(.photoRequirement)
        }
        
        // Building-specific info when clocked in
        if case .clockedIn = clockInStatus {
            priorities.append(.buildingSpecificInfo)
        }
        
        // Route optimization for multiple buildings
        if nextTasks.compactMap({ $0.buildingId }).count > 1 {
            priorities.append(.routeOptimization)
        }
        
        // Efficiency insights
        if todaysMetrics.efficiency > 0 {
            priorities.append(.efficiencyInsight)
        }
        
        prioritizedContent = priorities.sorted { $0.weight > $1.weight }
    }
    
    // MARK: - Helper Views and Properties
    
    private var statusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 8)
                        .scaleEffect(1.5)
                        .opacity(isActiveStatus ? 0.6 : 0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isActiveStatus)
                )
        }
    }
    
    private var statusColor: Color {
        if !urgentTasks.isEmpty {
            return CyntientOpsDesign.DashboardColors.critical
        }
        
        switch clockInStatus {
        case .clockedIn:
            return CyntientOpsDesign.DashboardColors.success
        case .notClockedIn:
            return CyntientOpsDesign.DashboardColors.inactive
        }
    }
    
    private var isActiveStatus: Bool {
        if case .clockedIn = clockInStatus { return true }
        return false
    }
    
    private var smartContextSummary: String {
        if !urgentTasks.isEmpty {
            return "\(urgentTasks.count) urgent task\(urgentTasks.count == 1 ? "" : "s")"
        }
        
        switch clockInStatus {
        case .clockedIn(let building, let time, _):
            let hours = Int(Date().timeIntervalSince(time)) / 3600
            return "\(hours)h at \(building)"
        case .notClockedIn:
            return "Ready to start"
        }
    }
    
    private var clockInStatusView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(clockStatusText)
                .font(.system(size: 12))
                .foregroundColor(statusColor)
        }
    }
    
    private var clockStatusText: String {
        switch clockInStatus {
        case .clockedIn(_, let time, _):
            let duration = Date().timeIntervalSince(time)
            let hours = Int(duration) / 3600
            let minutes = Int(duration % 3600) / 60
            return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        case .notClockedIn:
            return "Not clocked in"
        }
    }
    
    private func contextualGreeting(for name: String) -> String {
        let firstName = name.split(separator: " ").first?.description ?? name
        
        switch currentTimeContext {
        case .morning:
            return "Good morning, \(firstName)"
        case .midday:
            return "Hello, \(firstName)"
        case .afternoon:
            return "Good afternoon, \(firstName)"
        case .evening:
            return "Good evening, \(firstName)"
        }
    }
    
    private func quickStat(_ title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func priorityIndicator(_ priority: ContentPriority) -> some View {
        Circle()
            .fill(priorityColor(priority))
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(priorityColor(priority).opacity(0.3), lineWidth: 3)
                    .scaleEffect(1.3)
                    .opacity(0.6)
            )
    }
    
    private func priorityColor(_ priority: ContentPriority) -> Color {
        switch priority {
        case .urgentTasks, .dsnyDeadline:
            return CyntientOpsDesign.DashboardColors.critical
        case .weatherAlert, .syncIssue:
            return CyntientOpsDesign.DashboardColors.warning
        case .photoRequirement, .clockInReminder:
            return CyntientOpsDesign.DashboardColors.info
        default:
            return CyntientOpsDesign.DashboardColors.success
        }
    }
    
    private func smartContentCard(for priority: ContentPriority) -> some View {
        Button(action: {
            handlePriorityAction(priority)
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(priorityColor(priority))
                        .frame(width: 8, height: 8)
                    
                    Spacer()
                    
                    Image(systemName: priorityIcon(priority))
                        .font(.system(size: 12))
                        .foregroundColor(priorityColor(priority))
                }
                
                Text(priorityTitle(priority))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(priorityDescription(priority))
                    .font(.system(size: 10))
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(width: 140, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CyntientOpsDesign.DashboardColors.glassOverlay)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(priorityColor(priority).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Clock properties
    private var clockIcon: String {
        switch clockInStatus {
        case .notClockedIn: return "clock"
        case .clockedIn: return "clock.fill"
        }
    }
    
    private var clockText: String {
        switch clockInStatus {
        case .notClockedIn: return "Clock In"
        case .clockedIn: return "Clock Out"
        }
    }
    
    private var clockColor: Color {
        switch clockInStatus {
        case .notClockedIn: return CyntientOpsDesign.DashboardColors.info
        case .clockedIn: return CyntientOpsDesign.DashboardColors.success
        }
    }
    
    // Sync properties
    private var syncIcon: String {
        switch syncStatus {
        case .synced: return "checkmark.circle.fill"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .offline: return "wifi.slash"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    private var syncColor: Color {
        switch syncStatus {
        case .synced: return CyntientOpsDesign.DashboardColors.success
        case .syncing: return CyntientOpsDesign.DashboardColors.info
        case .offline: return CyntientOpsDesign.DashboardColors.inactive
        case .error: return CyntientOpsDesign.DashboardColors.critical
        }
    }
    
    // Priority helpers
    private func priorityIcon(_ priority: ContentPriority) -> String {
        switch priority {
        case .urgentTasks: return "exclamationmark.triangle.fill"
        case .weatherAlert: return "cloud.rain.fill"
        case .dsnyDeadline: return "trash.fill"
        case .clockInReminder: return "clock.fill"
        case .syncIssue: return "wifi.exclamationmark"
        case .photoRequirement: return "camera.fill"
        case .buildingSpecificInfo: return "building.2.fill"
        case .efficiencyInsight: return "chart.bar.fill"
        case .routeOptimization: return "map.fill"
        }
    }
    
    private func priorityTitle(_ priority: ContentPriority) -> String {
        switch priority {
        case .urgentTasks: return "\(urgentTasks.count) Urgent Tasks"
        case .weatherAlert: return "Weather Alert"
        case .dsnyDeadline: return "DSNY Deadline"
        case .clockInReminder: return "Ready to Start"
        case .syncIssue: return "Sync Issue"
        case .photoRequirement: return "Photos Needed"
        case .buildingSpecificInfo: return "Building Info"
        case .efficiencyInsight: return "Efficiency \(Int(todaysMetrics.efficiency * 100))%"
        case .routeOptimization: return "Route Planning"
        }
    }
    
    private func priorityDescription(_ priority: ContentPriority) -> String {
        switch priority {
        case .urgentTasks: return "Requires immediate attention"
        case .weatherAlert: return "Indoor tasks recommended"
        case .dsnyDeadline: return "Set out by 8:00 PM"
        case .clockInReminder: return "Tap to clock in"
        case .syncIssue: return "Data not synchronized"
        case .photoRequirement: return "Documentation required"
        case .buildingSpecificInfo: return currentBuilding?.name ?? "Building details"
        case .efficiencyInsight: return "Above average performance"
        case .routeOptimization: return "Optimize travel time"
        }
    }
    
    private func handlePriorityAction(_ priority: ContentPriority) {
        switch priority {
        case .urgentTasks:
            if let firstUrgent = urgentTasks.first {
                onTaskTap(firstUrgent)
            }
        case .clockInReminder:
            onClockAction()
        case .syncIssue:
            onSyncTap()
        case .buildingSpecificInfo:
            onNavigateToBuilding()
        default:
            break
        }
    }
}

// MARK: - Extension for TaskProgress

extension CoreTypes.TaskProgress {
    var completionRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
}

// MARK: - Preview Provider

#if DEBUG
struct SmartWorkerHeroCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Collapsed state
                SmartWorkerHeroCard(
                    isExpanded: .constant(false),
                    workerProfile: CoreTypes.WorkerProfile(
                        id: "4", 
                        name: "Kevin Dutan", 
                        email: "kevin@cyntientops.com", 
                        role: .worker, 
                        status: .clockedIn
                    ),
                    currentBuilding: CoreTypes.NamedCoordinate(
                        id: "14", 
                        name: "Rubin Museum", 
                        address: "150 W 17th St", 
                        latitude: 40.7408, 
                        longitude: -73.9971, 
                        type: .educational
                    ),
                    weatherData: nil,
                    taskProgress: CoreTypes.TaskProgress(totalTasks: 38, completedTasks: 16),
                    clockInStatus: .clockedIn(building: "Rubin Museum", time: Date().addingTimeInterval(-7200), location: nil),
                    syncStatus: .synced,
                    capabilities: SmartWorkerHeroCard.WorkerCapabilities(
                        canUploadPhotos: true,
                        canAddNotes: true,
                        canViewMap: true,
                        canAddEmergencyTasks: true,
                        requiresPhotoForSanitation: true,
                        simplifiedInterface: false
                    ),
                    urgentTasks: [],
                    nextTasks: [],
                    todaysMetrics: SmartWorkerHeroCard.TodaysMetrics(
                        hoursWorked: 2.5,
                        photosUploaded: 12,
                        distanceWalked: 1.2,
                        efficiency: 0.85,
                        completionRate: 0.42
                    ),
                    contextualAlerts: [],
                    onClockAction: { },
                    onTaskTap: { _ in },
                    onEmergencyTap: { },
                    onNavigateToBuilding: { },
                    onSyncTap: { }
                )
                
                // Expanded state
                SmartWorkerHeroCard(
                    isExpanded: .constant(true),
                    workerProfile: CoreTypes.WorkerProfile(
                        id: "4", 
                        name: "Kevin Dutan", 
                        email: "kevin@cyntientops.com", 
                        role: .worker, 
                        status: .clockedIn
                    ),
                    currentBuilding: CoreTypes.NamedCoordinate(
                        id: "14", 
                        name: "Rubin Museum", 
                        address: "150 W 17th St", 
                        latitude: 40.7408, 
                        longitude: -73.9971, 
                        type: .educational
                    ),
                    weatherData: CoreTypes.WeatherData(
                        temperature: 45,
                        condition: .rain,
                        humidity: 78,
                        windSpeed: 12.5,
                        description: "Light rain"
                    ),
                    taskProgress: CoreTypes.TaskProgress(totalTasks: 38, completedTasks: 16),
                    clockInStatus: .clockedIn(building: "Rubin Museum", time: Date().addingTimeInterval(-7200), location: nil),
                    syncStatus: .synced,
                    capabilities: SmartWorkerHeroCard.WorkerCapabilities(
                        canUploadPhotos: true,
                        canAddNotes: true,
                        canViewMap: true,
                        canAddEmergencyTasks: true,
                        requiresPhotoForSanitation: true,
                        simplifiedInterface: false
                    ),
                    urgentTasks: [],
                    nextTasks: [],
                    todaysMetrics: SmartWorkerHeroCard.TodaysMetrics(
                        hoursWorked: 2.5,
                        photosUploaded: 12,
                        distanceWalked: 1.2,
                        efficiency: 0.85,
                        completionRate: 0.42
                    ),
                    contextualAlerts: [],
                    onClockAction: { },
                    onTaskTap: { _ in },
                    onEmergencyTap: { },
                    onNavigateToBuilding: { },
                    onSyncTap: { }
                )
            }
            .padding()
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .preferredColorScheme(.dark)
    }
}
#endif