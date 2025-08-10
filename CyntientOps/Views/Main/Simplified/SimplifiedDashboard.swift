//
//  SimplifiedDashboard.swift
//  CyntientOps v6.0
//
//  ✅ UPDATED: Dark Elegance theme with accessibility focus
//  ✅ HIGH CONTRAST: Maintains readability for simplified interface users
//  ✅ GLASS MORPHISM: Subtle effects that don't compromise clarity
//  ✅ INTEGRATED: Uses UnifiedTaskDetailView with simplified mode
//

import SwiftUI

struct SimplifiedDashboard: View {
    
    // The ViewModel is the single source of truth for all dashboard data.
    @ObservedObject var viewModel: WorkerDashboardViewModel
    
    // State for navigating to the task detail view.
    @State private var selectedTask: CoreTypes.ContextualTask?
    @State private var showClockInSheet = false
    @State private var animateClockButton = false
    
    var body: some View {
        ZStack {
            // Dark elegant background with subtle gradient
            CyntientOpsDesign.DashboardGradients.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with worker info and glass effect
                headerView
                    .animatedGlassAppear(delay: 0.1)
                
                // Main content area
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Current Building Card with glass
                        currentBuildingCard
                            .animatedGlassAppear(delay: 0.2)
                        
                        // Today's Tasks Section with enhanced styling
                        tasksSection
                            .animatedGlassAppear(delay: 0.3)
                        
                        // Add spacing for bottom button
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            
            // Floating clock in/out button with glass effect
            VStack {
                Spacer()
                clockInOutButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedTask) { task in
            NavigationView {
                UnifiedTaskDetailView(task: task, mode: .simplified)
            }
        }
        .sheet(isPresented: $showClockInSheet) {
            SimplifiedClockInSheet(
                buildings: viewModel.assignedBuildings,
                onSelectBuilding: { building in
                    Task {
                        await viewModel.clockIn(at: building)
                        showClockInSheet = false
                    }
                }
            )
        }
        .onAppear {
            Task {
                await viewModel.refreshData()
            }
            // Animate clock button on appear
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
                animateClockButton = true
            }
        }
    }
    
    // MARK: - Header View with Glass Effect
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Text(greeting)
                .glassSubtitle()
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            Text(viewModel.workerProfile?.name ?? "Worker")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .shadow(color: CyntientOpsDesign.DashboardColors.primaryText.opacity(0.3), radius: 2)
            
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isClockedIn ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.inactive)
                    .frame(width: 12, height: 12)
                    .shadow(color: viewModel.isClockedIn ? CyntientOpsDesign.DashboardColors.success : .clear, radius: 4)
                
                Text(viewModel.isClockedIn ? "Clocked In" : "Not Clocked In")
                    .glassText(size: .callout)
                    .foregroundColor(viewModel.isClockedIn ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.secondaryText)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            .ultraThinMaterial
                .opacity(0.5)
        )
    }
    
    // MARK: - Current Building Card
    
    @ViewBuilder
    private var currentBuildingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                    .shadow(color: CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.5), radius: 4)
                
                Text("Current Building")
                    .glassHeading()
            }
            
            if viewModel.isClockedIn, let building = viewModel.currentBuilding {
                VStack(alignment: .leading, spacing: 8) {
                    Text(building.name)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    if !building.address.isEmpty {
                        Text(building.address)
                            .glassSubtitle()
                            .lineLimit(2)
                    }
                }
                .padding(.top, 4)
            } else {
                Text("Tap the green button below to clock in")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .padding(.vertical, 8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.lg)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Tasks Section
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "checklist")
                    .font(.title2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                    .shadow(color: CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.5), radius: 4)
                
                Text("Today's Tasks")
                    .glassHeading()
                
                Spacer()
                
                // Task count badge
                if !viewModel.todaysTasks.isEmpty {
                    Text("\(viewModel.todaysTasks.filter { !$0.isCompleted }.count) left")
                        .glassCaption()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.2))
                        )
                }
            }
            
            if viewModel.todaysTasks.isEmpty {
                SimplifiedEmptyTasksView()
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.todaysTasks.prefix(5), id: \.id) { task in
                        SimplifiedTaskRow(
                            task: task,
                            onTap: { selectedTask = task },
                            onComplete: {
                                Task {
                                    await viewModel.completeTask(task)
                                }
                            }
                        )
                        .transition(.slide.combined(with: .opacity))
                    }
                    
                    if viewModel.todaysTasks.count > 5 {
                        NavigationLink(destination: TaskListView(tasks: viewModel.todaysTasks)) {
                            HStack {
                                Text("View All \(viewModel.todaysTasks.count) Tasks")
                                    .glassText()
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.md)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.lg)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Clock In/Out Button
    
    private var clockInOutButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                if viewModel.isClockedIn {
                    Task {
                        await viewModel.clockOut()
                    }
                } else {
                    // Show building selection for clock in
                    if viewModel.assignedBuildings.count == 1 {
                        // Auto clock in if only one building
                        Task {
                            await viewModel.clockIn(at: viewModel.assignedBuildings[0])
                        }
                    } else {
                        showClockInSheet = true
                    }
                }
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: viewModel.isClockedIn ? "arrow.right.square.fill" : "arrow.left.square.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                
                Text(viewModel.isClockedIn ? "Clock Out" : "Clock In")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.xl)
                    .fill(
                        LinearGradient(
                            colors: viewModel.isClockedIn ?
                                [CyntientOpsDesign.DashboardColors.critical, CyntientOpsDesign.DashboardColors.critical.opacity(0.8)] :
                                [CyntientOpsDesign.DashboardColors.success, CyntientOpsDesign.DashboardColors.success.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: (viewModel.isClockedIn ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.success).opacity(0.4),
                        radius: 15,
                        y: 8
                    )
            )
            .scaleEffect(animateClockButton ? 1.0 : 0.9)
            .opacity(animateClockButton ? 1.0 : 0.0)
        }
        .shadow(
            color: (viewModel.isClockedIn ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.success).opacity(0.3),
            radius: 10,
            y: 5
        )
    }
    
    // MARK: - Computed Properties
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        default:
            return "Good Evening"
        }
    }
}

// MARK: - Simplified Task Row

struct SimplifiedTaskRow: View {
    let task: CoreTypes.ContextualTask
    let onTap: () -> Void
    let onComplete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                // Large completion button
                Button(action: onComplete) {
                    ZStack {
                        Circle()
                            .stroke(task.isCompleted ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.secondaryText, lineWidth: 3)
                            .frame(width: 44, height: 44)
                        
                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                        }
                    }
                }
                .disabled(task.isCompleted)
                
                // Task info
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(task.isCompleted ? CyntientOpsDesign.DashboardColors.secondaryText : CyntientOpsDesign.DashboardColors.primaryText)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)
                    
                    if let building = task.building {
                        HStack(spacing: 6) {
                            Image(systemName: "building.2")
                                .font(.caption)
                            Text(building.name)
                                .font(.system(size: 16))
                        }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                }
                
                Spacer()
                
                // Urgency indicator
                if let urgency = task.urgency, urgency != .low {
                    VStack {
                        Image(systemName: urgencyIcon(urgency))
                            .font(.title2)
                            .foregroundColor(CyntientOpsDesign.EnumColors.taskUrgency(urgency))
                        
                        Text(urgency.rawValue.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(CyntientOpsDesign.EnumColors.taskUrgency(urgency))
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.lg)
                    .fill(task.isCompleted ? .ultraThinMaterial : .regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.lg)
                            .stroke(CyntientOpsDesign.DashboardColors.borderSubtle, lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private func urgencyIcon(_ urgency: CoreTypes.TaskUrgency) -> String {
        switch urgency {
        case .low, .medium:
            return "exclamationmark.circle"
        case .high, .urgent:
            return "exclamationmark.triangle.fill"
        case .critical, .emergency:
            return "exclamationmark.3"
        case .normal:
            return "circle"
        }
    }
}

// MARK: - Empty Tasks View

struct SimplifiedEmptyTasksView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                .shadow(color: CyntientOpsDesign.DashboardColors.success.opacity(0.3), radius: 10)
            
            VStack(spacing: 8) {
                Text("All Clear!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text("No tasks scheduled for today")
                    .font(.system(size: 18))
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Clock In Sheet

struct SimplifiedClockInSheet: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let onSelectBuilding: (CoreTypes.NamedCoordinate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                CyntientOpsDesign.DashboardGradients.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Select Building to Clock In")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .padding(.top)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(buildings, id: \.id) { building in
                                Button(action: {
                                    onSelectBuilding(building)
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(building.name)
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                                        
                                        if !building.address.isEmpty {
                                            Text(building.address)
                                                .font(.system(size: 16))
                                                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                                                .lineLimit(2)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.lg)
                                            .fill(.regularMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.lg)
                                                    .stroke(CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.3), lineWidth: 2)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
            }
        }
    }
}

// MARK: - Task List View

struct TaskListView: View {
    let tasks: [CoreTypes.ContextualTask]
    
    var body: some View {
        ZStack {
            CyntientOpsDesign.DashboardGradients.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(tasks, id: \.id) { task in
                        NavigationLink(destination: UnifiedTaskDetailView(task: task, mode: .simplified)) {
                            SimplifiedTaskRow(
                                task: task,
                                onTap: {},
                                onComplete: {
                                    // Handle completion
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
        .navigationTitle("All Tasks")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview

struct SimplifiedDashboard_Previews: PreviewProvider {
    static var previews: some View {
        // Preview requires ServiceContainer - placeholder for now
        Text("SimplifiedDashboard Preview")
            .foregroundColor(.white)
            .preferredColorScheme(.dark)
    }
}
