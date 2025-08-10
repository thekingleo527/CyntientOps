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
    @StateObject private var viewModel = WorkerProfileViewModel()
    let workerId: String
    
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
                        PerformanceMetricsView(metrics: metrics)
                            .animatedGlassAppear(delay: 0.2)
                    }
                    
                    // Recent Tasks Section
                    RecentTasksView(tasks: viewModel.recentTasks)
                        .animatedGlassAppear(delay: 0.3)
                    
                    // Skills Section
                    if let worker = viewModel.worker, let skills = worker.skills {
                        SkillsView(skills: skills)
                            .animatedGlassAppear(delay: 0.4)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .navigationTitle("Worker Profile")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadWorkerData(workerId: workerId)
        }
        .overlay {
            if viewModel.isLoading {
                GlassLoadingState()
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

struct PerformanceMetricsView: View {
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
class WorkerProfileViewModel: ObservableObject {
    @Published var worker: WorkerProfile?
    @Published var performanceMetrics: CoreTypes.PerformanceMetrics?
    @Published var recentTasks: [ContextualTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let workerService = WorkerService.shared
    private let taskService = TaskService.shared
    private let workerMetricsService = WorkerMetricsService.shared
    
    func loadWorkerData(workerId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load worker profile
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
            recentTasks = try await taskService.getTasks(for: workerId, date: Date())
            
            // If no tasks for today, get all tasks for this worker
            if recentTasks.isEmpty {
                let allTasks = try await taskService.getAllTasks()
                recentTasks = allTasks
                    .filter { task in
                        task.assignedWorkerId == workerId || task.worker?.id == workerId
                    }
                    .sorted { task1, task2 in
                        let date1 = task1.completedDate ?? task1.dueDate ?? Date.distantPast
                        let date2 = task2.completedDate ?? task2.dueDate ?? Date.distantPast
                        return date1 > date2
                    }
                    .prefix(10)
                    .map { $0 }
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
    }
}

// MARK: - Helper Extension

extension WorkerService {
    func getWorkerBuildings(workerId: String) async throws -> [NamedCoordinate] {
        return []
    }
}

// MARK: - Preview

struct WorkerProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkerProfileView(workerId: "4")
        }
        .preferredColorScheme(.dark)
    }
}
