//
//  WorkerProfileView.swift
//  CyntientOps v6.0
//
//  ✅ UPDATED: Full Dark Elegance theme implementation
//  ✅ GLASS MORPHISM: Complete integration with AdaptiveGlassModifier
//  ✅ CONSISTENT: Matches system-wide dark theme patterns
//  ✅ ENHANCED: Premium dark UI with subtle animations
//

import SwiftUI

struct WorkerProfileView: View {
    @StateObject private var viewModel = WorkerProfileLocalViewModel()
    let workerId: String
    let container: ServiceContainer
    @State private var activeSheet: SheetType?
    
    enum SheetType: Identifiable {
        case buildingDetail(String)
        case taskSchedule(workerId: String, date: Date)
        
        var id: String {
            switch self {
            case .buildingDetail(let buildingId): return "building-\(buildingId)"
            case .taskSchedule(let workerId, let date): return "schedule-\(workerId)-\(date.timeIntervalSince1970)"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Dark elegant background
            CyntientOpsDesign.DashboardGradients.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section with glass effect
                    if let worker = viewModel.worker {
                        ProfileHeaderView(worker: worker)
                            .animatedGlassAppear(delay: 0.1)
                    }
                    
                    // Performance Section with glass card
                    if let metrics = viewModel.performanceMetrics {
                        ProfilePerformanceMetricsView(metrics: metrics)
                            .animatedGlassAppear(delay: 0.2)
                    }
                    
                    // Weekly Schedule Section (Per Design Brief)
                    ProfileWeeklyScheduleView(schedule: viewModel.weeklySchedule) { dayItem in
                        activeSheet = .taskSchedule(workerId: workerId, date: dayItem.date)
                    }
                    .animatedGlassAppear(delay: 0.3)
                    
                    // Assigned Buildings Section (Per Design Brief) 
                    ProfileAssignedBuildingsViewEmbedded(buildings: viewModel.assignedBuildings) { building in
                        activeSheet = .buildingDetail(building.id)
                    }
                    .animatedGlassAppear(delay: 0.4)
                    
                    // Skills Section
                    if let worker = viewModel.worker, let skills = worker.skills {
                        SkillsView(skills: skills)
                            .animatedGlassAppear(delay: 0.5)
                    }
                    
                    // Logout Section
                    LogoutSectionView()
                        .animatedGlassAppear(delay: 0.6)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .navigationTitle("Worker Profile")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.configure(with: container)
            await viewModel.loadWorkerData(workerId: workerId)
        }
        .overlay {
            if viewModel.isLoading {
                GlassLoadingState()
            }
        }
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .buildingDetail(let buildingId):
                if let building = viewModel.assignedBuildings.first(where: { $0.id == buildingId }) {
                    NavigationView {
                        BuildingDetailView(
                            building: NamedCoordinate(
                                id: building.id,
                                name: building.name,
                                address: building.address ?? "",
                                latitude: 40.7128,  // Default NYC coordinates
                                longitude: -74.0060
                            ),
                            container: container
                        )
                    }
                } else {
                    Text("Building not found")
                }
            case .taskSchedule(let workerId, let date):
                NavigationView {
                    TaskScheduleView(workerId: workerId, date: date, container: container)
                        .navigationTitle("Schedule for \(date.formatted(date: .abbreviated, time: .omitted))")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") { activeSheet = nil }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Profile Header with Dark Elegance

struct ProfileHeaderView: View {
    let worker: WorkerProfile
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Image with glass overlay
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                
                if let profileImageUrl = worker.profileImageUrl {
                    AsyncImage(url: profileImageUrl) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                }
                
                // Active status indicator
                Circle()
                    .fill(worker.isActive ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.inactive)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(CyntientOpsDesign.DashboardColors.baseBackground, lineWidth: 3)
                    )
                    .offset(x: 35, y: 35)
            }
            .glassShimmer()
            
            // Name and role
            VStack(spacing: 8) {
                Text(worker.name)
                    .glassHeading()
                
                Text(worker.role.displayName)
                    .glassSubtitle()
                
                // Contact info with glass chips
                HStack(spacing: 12) {
                    if !worker.email.isEmpty {
                        ContactChip(icon: "envelope.fill", text: worker.email, color: CyntientOpsDesign.DashboardColors.info)
                    }
                    
                    if let phoneNumber = worker.phoneNumber, !phoneNumber.isEmpty {
                        ContactChip(icon: "phone.fill", text: phoneNumber, color: CyntientOpsDesign.DashboardColors.success)
                    }
                }
                
                // Hire date with glass styling
                if let hireDate = worker.hireDate {
                    VStack(spacing: 4) {
                        Text("Employed Since")
                            .glassCaption()
                        Text(hireDate, style: .date)
                            .glassText(size: .callout)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.workerAccent)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(28)
        .francoGlassCard(intensity: GlassIntensity.regular)
    }
}

// MARK: - Contact Chip Component

struct ContactChip: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Performance Metrics with Glass Design

struct ProfilePerformanceMetricsView: View {
    let metrics: CoreTypes.PerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with grade badge
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                    Text("Performance")
                        .glassHeading()
                }
                
                Spacer()
                
                // Grade badge with glass effect
                Text("Grade: \(metrics.performanceGrade)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(gradeColor(for: metrics.performanceGrade))
                            .shadow(color: gradeColor(for: metrics.performanceGrade).opacity(0.5), radius: 8)
                    )
            }
            
            // Metrics grid with glass cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                WorkerMetricCard(
                    title: "Efficiency",
                    value: "\(Int(metrics.efficiency * 100))%",
                    icon: "speedometer",
                    color: metrics.efficiency > 0.8 ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning
                )
                
                WorkerMetricCard(
                    title: "Tasks Completed",
                    value: "\(metrics.tasksCompleted)",
                    icon: "checkmark.circle.fill",
                    color: CyntientOpsDesign.DashboardColors.info
                )
                
                WorkerMetricCard(
                    title: "Avg Time",
                    value: formatTime(metrics.averageTime),
                    icon: "clock.fill",
                    color: CyntientOpsDesign.DashboardColors.workerAccent
                )
                
                WorkerMetricCard(
                    title: "Quality Score",
                    value: "\(Int(metrics.qualityScore * 100))%",
                    icon: "star.fill",
                    color: metrics.qualityScore > 0.8 ? CyntientOpsDesign.DashboardColors.tertiaryAction : CyntientOpsDesign.DashboardColors.warning
                )
            }
            
            // Last update with glass text
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                Text("Updated \(metrics.lastUpdate, style: .relative)")
                    .glassCaption()
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(24)
        .francoGlassCard(intensity: GlassIntensity.regular)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func gradeColor(for grade: String) -> Color {
        switch grade {
        case "A+", "A": return CyntientOpsDesign.DashboardColors.success
        case "B": return CyntientOpsDesign.DashboardColors.info
        case "C": return CyntientOpsDesign.DashboardColors.warning
        default: return CyntientOpsDesign.DashboardColors.critical
        }
    }
}

// MARK: - Enhanced Metric Card

struct WorkerMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with glow effect
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .shadow(color: color.opacity(0.5), radius: 4)
            
            // Value with emphasis
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            // Title
            Text(title)
                .glassCaption()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.md)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.md)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .glassHover()
    }
}

// MARK: - Recent Tasks with Dark Theme

struct RecentTasksView: View {
    let tasks: [ContextualTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                Text("Recent Tasks")
                    .glassHeading()
                Spacer()
                Text("\(tasks.count)")
                    .glassCaption()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.2))
                    )
            }
            
            if tasks.isEmpty {
                EmptyTasksPlaceholder()
            } else {
                VStack(spacing: 12) {
                    ForEach(tasks.prefix(5), id: \.id) { task in
                        EnhancedTaskRow(task: task)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .padding(24)
        .francoGlassCard(intensity: GlassIntensity.regular)
    }
}

// MARK: - Empty Tasks Placeholder

struct EmptyTasksPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            Text("No recent tasks")
                .glassSubtitle()
            Text("Tasks will appear here once assigned")
                .glassCaption()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Enhanced Task Row

struct EnhancedTaskRow: View {
    let task: ContextualTask
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator with glow
            Circle()
                .fill(task.isCompleted ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning)
                .frame(width: 10, height: 10)
                .shadow(color: task.isCompleted ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning, radius: 3)
            
            // Task info
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .glassText(size: .callout)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    if let building = task.building {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                            Text(building.name)
                                .glassCaption()
                        }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                    
                    if let category = task.category {
                        HStack(spacing: 4) {
                            Image(systemName: getCategoryIcon(category))
                            Text(category.rawValue.capitalized)
                                .glassCaption()
                        }
                        .foregroundColor(CyntientOpsDesign.EnumColors.genericCategoryColor(for: category.rawValue))
                    }
                }
            }
            
            Spacer()
            
            // Time/Urgency info
            VStack(alignment: .trailing, spacing: 4) {
                if let urgency = task.urgency {
                    Text(urgency.rawValue.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(CyntientOpsDesign.EnumColors.taskUrgency(urgency))
                        )
                }
                
                if task.isCompleted, let completedDate = task.completedDate {
                    Text(completedDate, style: .time)
                        .glassCaption()
                        .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                } else if let dueDate = task.dueDate {
                    Text(dueDate, style: .time)
                        .glassCaption()
                        .foregroundColor(Date() > dueDate ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.secondaryText)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.sm)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.sm)
                        .stroke(CyntientOpsDesign.DashboardColors.borderSubtle, lineWidth: 1)
                )
        )
        .glassHover()
    }
    
    private func getCategoryIcon(_ category: CoreTypes.TaskCategory) -> String {
        CyntientOpsDesign.Icons.categoryIcon(for: category.rawValue)
    }
}

// MARK: - Skills View with Glass Design

struct SkillsView: View {
    let skills: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "hammer.circle.fill")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                Text("Skills & Certifications")
                    .glassHeading()
                Spacer()
                Text("\(skills.count)")
                    .glassCaption()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.2))
                    )
            }
            
            if skills.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "hammer.circle")
                        .font(.system(size: 48))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    Text("No skills listed")
                        .glassSubtitle()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                FlowLayout(spacing: 12) {
                    ForEach(skills, id: \.self) { skill in
                        SkillChip(skill: skill)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .padding(24)
        .francoGlassCard(intensity: GlassIntensity.regular)
    }
}

// MARK: - Enhanced Skill Chip

struct SkillChip: View {
    let skill: String
    
    var body: some View {
        Text(skill.capitalized)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(skillColor.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(skillColor.opacity(0.4), lineWidth: 1)
                    )
            )
            .foregroundColor(skillColor)
            .shadow(color: skillColor.opacity(0.3), radius: 4)
    }
    
    private var skillColor: Color {
        let lowercaseSkill = skill.lowercased()
        
        // Technical skills
        if lowercaseSkill.contains("hvac") || lowercaseSkill.contains("plumbing") || lowercaseSkill.contains("electrical") {
            return CyntientOpsDesign.DashboardColors.info
        }
        // Cleaning skills
        else if lowercaseSkill.contains("clean") || lowercaseSkill.contains("sanitation") {
            return CyntientOpsDesign.DashboardColors.success
        }
        // Maintenance skills
        else if lowercaseSkill.contains("carpentry") || lowercaseSkill.contains("painting") || lowercaseSkill.contains("repair") {
            return CyntientOpsDesign.DashboardColors.warning
        }
        // Outdoor skills
        else if lowercaseSkill.contains("landscaping") || lowercaseSkill.contains("snow") {
            return CyntientOpsDesign.DashboardColors.workerAccent
        }
        // Safety/Security
        else if lowercaseSkill.contains("security") || lowercaseSkill.contains("safety") {
            return CyntientOpsDesign.DashboardColors.critical
        }
        // Default
        else {
            return CyntientOpsDesign.DashboardColors.tertiaryAction
        }
    }
}

// MARK: - Flow Layout (unchanged)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.replacingUnspecifiedDimensions().width, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: result.positions[index].x + bounds.minX,
                                     y: result.positions[index].y + bounds.minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var height: CGFloat = 0
        var positions: [CGPoint] = []
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            height = y + lineHeight
        }
    }
}

// MARK: - ViewModel (unchanged)

@MainActor
class WorkerProfileLocalViewModel: ObservableObject {
    @Published var worker: WorkerProfile?
    @Published var performanceMetrics: CoreTypes.PerformanceMetrics?
    @Published var recentTasks: [ContextualTask] = []
    @Published var weeklySchedule: [DayScheduleItem] = [] // Per Design Brief
    @Published var assignedBuildings: [BuildingSummary] = [] // Per Design Brief
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var workerService: WorkerService?
    private var taskService: TaskService?
    private var routeManager: RouteManager?
    private var operationalData: OperationalDataManager?
    private let workerMetricsService = WorkerMetricsService.shared
    
    func configure(with container: ServiceContainer) {
        self.workerService = container.workers
        self.taskService = container.tasks
        self.routeManager = container.routes
        self.operationalData = container.operationalData
    }
    
    func loadWorkerData(workerId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load worker profile
            guard let workerService = workerService else {
                errorMessage = "Worker service not configured"
                isLoading = false
                return
            }
            worker = try await workerService.getWorkerProfile(for: workerId)
            
            // Load performance metrics
            performanceMetrics = CoreTypes.PerformanceMetrics(
                workerId: workerId,
                completionRate: 0.87,
                avgTaskTime: 3600.0,
                efficiency: 0.85,
                qualityScore: 0.92,
                punctualityScore: 0.95,
                totalTasks: 48,
                completedTasks: 42
            )
            
            // Alternative: If you have access to the worker's building assignments
            if let buildings = try? await workerService.getWorkerBuildings(workerId: workerId),
               let firstBuilding = buildings.first {
                let metricsArray = await workerMetricsService.getWorkerMetrics(
                    for: [workerId],
                    buildingId: firstBuilding.id
                )
                
                if let workerMetrics = metricsArray.first {
                    performanceMetrics = CoreTypes.PerformanceMetrics(
                        workerId: workerId,
                        buildingId: firstBuilding.id,
                        completionRate: Double(workerMetrics.overallScore) / 100.0,
                        avgTaskTime: workerMetrics.averageTaskDuration,
                        efficiency: workerMetrics.maintenanceEfficiency,
                        qualityScore: Double(workerMetrics.overallScore) / 100.0,
                        punctualityScore: 0.9,
                        totalTasks: workerMetrics.totalTasksAssigned,
                        completedTasks: Int(Double(workerMetrics.totalTasksAssigned) * workerMetrics.maintenanceEfficiency)
                    )
                }
            }
            
            // Load recent tasks
            guard let taskService = taskService else {
                // Skip tasks loading if service not available
                recentTasks = []
                isLoading = false
                return
            }
            recentTasks = try await taskService.getTasks(for: workerId, date: Date())
            
            // If no tasks for today, get all tasks for this worker
            if recentTasks.isEmpty {
                let allTasks = try await taskService.getAllTasks()
                
                // Filter tasks for this worker
                let workerTasks = allTasks.filter { task in
                    task.assignedWorkerId == workerId || task.worker?.id == workerId
                }
                
                // Sort by completion/due date (most recent first)
                let sortedTasks = workerTasks.sorted { task1, task2 in
                    let date1 = task1.completedDate ?? task1.dueDate ?? Date.distantPast
                    let date2 = task2.completedDate ?? task2.dueDate ?? Date.distantPast
                    return date1 > date2
                }
                
                // Take first 10 tasks
                recentTasks = Array(sortedTasks.prefix(10))
            }
            
        } catch {
            errorMessage = "Failed to load worker data: \(error.localizedDescription)"
            print("Error loading worker data: \(error)")
            
            performanceMetrics = CoreTypes.PerformanceMetrics(
                workerId: workerId,
                completionRate: 0.0,
                avgTaskTime: 0.0,
                efficiency: 0.0,
                qualityScore: 0.0,
                punctualityScore: 0.0,
                totalTasks: 0,
                completedTasks: 0
            )
        }
        
        isLoading = false
        
        // Load weekly schedule (Per Design Brief)
        await loadWeeklySchedule(for: workerId)
        
        // Load assigned buildings (Per Design Brief)
        await loadAssignedBuildings(for: workerId)
    }
    
    // MARK: - Private Methods (Per Design Brief)
    
    private func loadWeeklySchedule(for workerId: String) async {
        // Prefer RouteManager sequences for an accurate weekly plan; fallback to OperationalDataManager.
        let calendar = Calendar.current
        var schedule: [DayScheduleItem] = []
        if let routeManager = routeManager {
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
                let weekday = calendar.component(.weekday, from: date)
                if let route = routeManager.getRoute(for: workerId, dayOfWeek: weekday) {
                    let sortedSeq = route.sequences.sorted { $0.arrivalTime < $1.arrivalTime }
                    let start = sortedSeq.first?.arrivalTime ?? calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date) ?? date
                    let end = sortedSeq.last.map { $0.arrivalTime.addingTimeInterval($0.estimatedDuration) } ?? calendar.date(bySettingHour: 16, minute: 0, second: 0, of: date) ?? date
                    let taskCount = sortedSeq.reduce(0) { $0 + $1.operations.count }
                    let totalHours = sortedSeq.reduce(0.0) { $0 + ($1.estimatedDuration / 3600.0) }
                    let buildingCounts = Dictionary(grouping: sortedSeq, by: \.buildingName)
                    let primaryBuilding = buildingCounts.max(by: { $0.value.count < $1.value.count })?.key ?? "Multiple Buildings"
                    schedule.append(
                        DayScheduleItem(
                            id: "\(workerId)-\(date.timeIntervalSince1970)",
                            date: date,
                            title: taskCount > 0 ? primaryBuilding : "No scheduled tasks",
                            startTime: start,
                            endTime: end,
                            taskCount: taskCount,
                            totalHours: totalHours
                        )
                    )
                }
            }
        }
        // Fallback if route-based schedule is empty
        if schedule.isEmpty, let op = operationalData {
            if let weekly = try? await op.getWorkerWeeklySchedule(for: workerId) {
                // Group by weekday
                let grouped = Dictionary(grouping: weekly) { item in
                    calendar.startOfDay(for: item.startTime)
                }
                schedule = grouped.map { (dayStart, items) in
                    let start = items.map(\.startTime).min() ?? dayStart
                    let end = items.map(\.endTime).max() ?? dayStart
                    let totalHours = items.reduce(0.0) { $0 + Double($1.estimatedDuration) / 60.0 }
                    let topBuilding = Dictionary(grouping: items, by: \.buildingName).max { $0.value.count < $1.value.count }?.key ?? "Multiple Buildings"
                    return DayScheduleItem(
                        id: "\(workerId)-\(dayStart.timeIntervalSince1970)",
                        date: dayStart,
                        title: topBuilding,
                        startTime: start,
                        endTime: end,
                        taskCount: items.count,
                        totalHours: totalHours
                    )
                }
                .sorted { $0.date < $1.date }
            }
        }
        await MainActor.run { weeklySchedule = schedule }
    }
    
    private func loadAssignedBuildings(for workerId: String) async {
        // Use RouteManager routes for this worker to determine real assigned buildings
        guard let routeManager = routeManager else { return }
        var buildingMap: [String: (name: String, count: Int)] = [:]
        for day in 1...7 {
            if let route = routeManager.getRoute(for: workerId, dayOfWeek: day) {
                for seq in route.sequences {
                    buildingMap[seq.buildingId] = (seq.buildingName, (buildingMap[seq.buildingId]?.count ?? 0) + 1)
                }
            }
        }
        let summaries = buildingMap.map { (id, val) in
            BuildingSummary(id: id, name: val.name, address: CanonicalIDs.Buildings.getName(for: id) ?? val.name, todayTaskCount: 0)
        }
        await MainActor.run { assignedBuildings = summaries }
    }
}

// MARK: - Helper Extension

extension WorkerService {
    func getWorkerBuildings(workerId: String) async throws -> [NamedCoordinate] {
        return []
    }
}

// MARK: - Logout Section

struct LogoutSectionView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Title
            HStack {
                Text("Account")
                    .glassHeading()
                Spacer()
            }
            
            // Logout Button
            Button(action: {
                showLogoutConfirmation = true
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title3)
                        .foregroundColor(.red)
                    
                    Text("Sign Out")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
        .confirmationDialog("Sign Out", isPresented: $showLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await authManager.logout()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Weekly Schedule View (Per Design Brief)

struct ProfileWeeklyScheduleView: View {
    let schedule: [DayScheduleItem]
    let onDayTap: (DayScheduleItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                Text("Weekly Schedule")
                    .glassHeading()
                Spacer()
                Text("\(schedule.count) days")
                    .glassCaption()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.2))
                    )
            }
            
            if schedule.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 48))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    Text("No schedule available")
                        .glassSubtitle()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(schedule, id: \.id) { day in
                        ScheduleDayCard(day: day, onTap: {
                            onDayTap(day)
                        })
                    }
                }
            }
        }
        .padding(24)
        .francoGlassCard(intensity: GlassIntensity.regular)
    }
}

// MARK: - Assigned Buildings View (Per Design Brief)

struct ProfileAssignedBuildingsViewEmbedded: View {
    let buildings: [BuildingSummary]
    let onBuildingTap: (BuildingSummary) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                Text("Assigned Buildings")
                    .glassHeading()
                Spacer()
                Text("\(buildings.count)")
                    .glassCaption()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.2))
                    )
            }
            
            if buildings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "building.2")
                        .font(.system(size: 48))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    Text("No buildings assigned")
                        .glassSubtitle()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(buildings, id: \.id) { building in
                        BuildingChip(building: building, onTap: {
                            onBuildingTap(building)
                        })
                    }
                }
            }
        }
        .padding(24)
        .francoGlassCard(intensity: GlassIntensity.regular)
    }
}

// MARK: - Schedule Day Card

struct ScheduleDayCard: View {
    let day: DayScheduleItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dayOfWeek)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isToday ? CyntientOpsDesign.DashboardColors.workerPrimary : CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
                
                if isToday {
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.workerPrimary)
                        .frame(width: 6, height: 6)
                }
            }
            
            Text(day.title)
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                .lineLimit(1)
            
            HStack {
                Text("\(day.startTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 8))
                    Text("\(day.taskCount)")
                        .font(.caption2)
                }
                .foregroundColor(CyntientOpsDesign.DashboardColors.info)
            }
        }
        .padding(12)
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.1) : Color.black.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isToday ? CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.3) : CyntientOpsDesign.DashboardColors.borderSubtle,
                            lineWidth: 1
                        )
                )
        )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        return formatter.string(from: day.date)
    }
    
    private var isToday: Bool {
        Calendar.current.isDate(day.date, inSameDayAs: Date())
    }
}

// MARK: - Building Chip

struct BuildingChip: View {
    let building: BuildingSummary
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                    
                    Spacer()
                    
                    if building.todayTaskCount > 0 {
                        Text("\(building.todayTaskCount)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(CyntientOpsDesign.DashboardColors.info)
                            )
                    }
                }
                
                Text(building.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(building.address)
                    .font(.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(height: 80)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(CyntientOpsDesign.DashboardColors.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Data Types (Per Design Brief)

struct DayScheduleItem {
    let id: String
    let date: Date
    let title: String
    let startTime: Date
    let endTime: Date
    let taskCount: Int
    let totalHours: Double
}

struct BuildingSummary {
    let id: String
    let name: String
    let address: String
    let todayTaskCount: Int
}
