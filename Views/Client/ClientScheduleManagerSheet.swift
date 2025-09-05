import SwiftUI

struct ClientScheduleManagerSheet: View {
    let workers: [CoreTypes.WorkerSummary]
    let buildings: [CoreTypes.NamedCoordinate]
    let routines: [CoreTypes.ClientRoutine]
    let container: ServiceContainer
    
    @State private var selectedWeek = Date()
    @State private var schedules: [CoreTypes.WeeklySchedule] = []
    @State private var conflicts: [CoreTypes.ScheduleConflict] = []
    @State private var isGeneratingSchedule = false
    @State private var viewMode: ScheduleViewMode = .week
    @State private var selectedWorker: String?
    
    enum ScheduleViewMode: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case worker = "Worker"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Schedule Controls
                scheduleControlsSection
                
                // View Mode Toggle
                viewModeSection
                
                // Schedule Conflicts Alert
                if !conflicts.isEmpty {
                    scheduleConflictsSection
                }
                
                // Main Schedule View
                switch viewMode {
                case .week:
                    weeklyScheduleSection
                case .month:
                    monthlyScheduleSection
                case .worker:
                    workerScheduleSection
                }
                
                // Schedule Optimization
                scheduleOptimizationSection
                
                // Quick Actions
                scheduleActionsSection
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .task {
            await loadScheduleData()
        }
    }
    
    private var scheduleControlsSection: some View {
        VStack(spacing: 16) {
            Text("Schedule Manager")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Week Picker
            HStack {
                Button(action: { changeWeek(-1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
                }
                
                Spacer()
                
                Text(selectedWeek.formatted(.dateTime.weekday(.wide).month().day().year()))
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { changeWeek(1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
                }
            }
            .padding(.horizontal)
            
            // Schedule Overview Stats
            HStack(spacing: 16) {
                ScheduleStatCard(title: "Workers", value: "\(workers.count)", color: .blue)
                ScheduleStatCard(title: "Shifts", value: "\(schedules.flatMap { $0.shifts }.count)", color: .green)
                ScheduleStatCard(title: "Conflicts", value: "\(conflicts.count)", color: .red)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var viewModeSection: some View {
        Picker("View Mode", selection: $viewMode) {
            ForEach(ScheduleViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewMode) { _ in
            Task { await loadScheduleData() }
        }
    }
    
    private var scheduleConflictsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text("Schedule Conflicts (\(conflicts.count))")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Auto-Resolve") {
                    Task { await autoResolveConflicts() }
                }
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
            }
            
            ForEach(conflicts.prefix(3), id: \.id) { conflict in
                ConflictCard(conflict: conflict, onResolve: { 
                    Task { await resolveConflict(conflict) }
                })
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var weeklyScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Schedule")
                .font(.headline)
                .foregroundColor(.white)
            
            // Days of the week grid
            let weekDays = getWeekDays(for: selectedWeek)
            
            ForEach(weekDays, id: \.self) { day in
                DayScheduleRow(
                    date: day,
                    schedules: getSchedulesForDay(day),
                    workers: workers,
                    onScheduleEdit: { schedule in
                        // Handle schedule edit
                    }
                )
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var monthlyScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Overview")
                .font(.headline)
                .foregroundColor(.white)
            
            // Calendar grid would go here
            Text("Calendar view implementation")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var workerScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Worker Schedule")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("Select Worker", selection: $selectedWorker) {
                    Text("All Workers").tag(String?.none)
                    ForEach(workers, id: \.id) { worker in
                        Text(worker.name).tag(String?.some(worker.id))
                    }
                }
                .pickerStyle(.menu)
            }
            
            if let workerId = selectedWorker {
                let workerSchedules = schedules.filter { schedule in
                    schedule.shifts.contains { $0.workerId == workerId }
                }
                
                ForEach(workerSchedules, id: \.id) { schedule in
                    WorkerScheduleCard(schedule: schedule, workerId: workerId)
                }
            } else {
                ForEach(workers.prefix(5), id: \.id) { worker in
                    WorkerScheduleSummary(worker: worker, schedules: schedules)
                }
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var scheduleOptimizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule Optimization")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                OptimizationMetric(
                    title: "Efficiency",
                    value: "94%",
                    change: "+5%",
                    color: .green
                )
                
                OptimizationMetric(
                    title: "Coverage",
                    value: "98%",
                    change: "+2%",
                    color: .blue
                )
                
                OptimizationMetric(
                    title: "Utilization",
                    value: "87%",
                    change: "-1%",
                    color: .orange
                )
            }
            
            Text("AI recommendations: Shift Maria to Building C for 15% efficiency gain")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                .padding(.top, 8)
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var scheduleActionsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("Generate Schedule") {
                    Task { await generateOptimalSchedule() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGeneratingSchedule)
                
                Button("Publish Changes") {
                    Task { await publishScheduleChanges() }
                }
                .buttonStyle(.bordered)
                .disabled(schedules.isEmpty)
            }
            
            if isGeneratingSchedule {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Optimizing schedules...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func loadScheduleData() async {
        isGeneratingSchedule = true
        
        // Load schedules from OperationalDataManager
        // This would integrate with real scheduling data
        
        let mockSchedules = workers.map { worker in
            CoreTypes.WeeklySchedule(
                id: UUID().uuidString,
                workerId: worker.id,
                weekStartDate: selectedWeek,
                shifts: generateShiftsForWorker(worker)
            )
        }
        
        await MainActor.run {
            self.schedules = mockSchedules
            self.conflicts = detectScheduleConflicts()
            self.isGeneratingSchedule = false
        }
    }
    
    private func generateShiftsForWorker(_ worker: CoreTypes.WorkerSummary) -> [CoreTypes.WorkerShift] {
        // Generate shifts based on worker capabilities and building needs
        return buildings.prefix(3).enumerated().map { index, building in
            CoreTypes.WorkerShift(
                id: UUID().uuidString,
                workerId: worker.id,
                buildingId: building.id,
                buildingName: building.name,
                startTime: Calendar.current.date(byAdding: .day, value: index, to: selectedWeek)!
                    .addingTimeInterval(8 * 3600), // 8 AM
                endTime: Calendar.current.date(byAdding: .day, value: index, to: selectedWeek)!
                    .addingTimeInterval(16 * 3600), // 4 PM
                routines: routines.filter { $0.buildingId == building.id }.prefix(2).map { $0 },
                status: .scheduled
            )
        }
    }
    
    private func detectScheduleConflicts() -> [CoreTypes.ScheduleConflict] {
        // Detect overlapping schedules and capability mismatches
        var detectedConflicts: [CoreTypes.ScheduleConflict] = []
        
        for schedule in schedules {
            for shift in schedule.shifts {
                // Check for time conflicts
                let overlappingShifts = schedules.flatMap { $0.shifts }.filter { otherShift in
                    otherShift.id != shift.id &&
                    otherShift.workerId == shift.workerId &&
                    shift.startTime < otherShift.endTime &&
                    shift.endTime > otherShift.startTime
                }
                
                if !overlappingShifts.isEmpty {
                    detectedConflicts.append(CoreTypes.ScheduleConflict(
                        id: UUID().uuidString,
                        type: .timeOverlap,
                        workerId: shift.workerId,
                        shiftIds: [shift.id] + overlappingShifts.map { $0.id },
                        description: "Worker has overlapping shifts",
                        severity: .high
                    ))
                }
            }
        }
        
        return detectedConflicts
    }
    
    private func getWeekDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private func getSchedulesForDay(_ date: Date) -> [CoreTypes.WorkerShift] {
        let calendar = Calendar.current
        return schedules.flatMap { $0.shifts }.filter { shift in
            calendar.isDate(shift.startTime, inSameDayAs: date)
        }
    }
    
    private func changeWeek(_ direction: Int) {
        selectedWeek = Calendar.current.date(byAdding: .weekOfYear, value: direction, to: selectedWeek) ?? selectedWeek
        Task { await loadScheduleData() }
    }
    
    private func generateOptimalSchedule() async {
        isGeneratingSchedule = true
        
        // Use OperationalDataManager to generate optimal schedule
        // Based on worker capabilities, building requirements, and historical data
        
        await MainActor.run {
            // Schedule generation would update schedules array
            self.isGeneratingSchedule = false
        }
    }
    
    private func publishScheduleChanges() async {
        // Publish schedule changes to OperationalDataManager
        for schedule in schedules {
            // Implementation would save to data manager
        }
    }
    
    private func autoResolveConflicts() async {
        // Automatically resolve scheduling conflicts using AI optimization
        for conflict in conflicts {
            await resolveConflict(conflict)
        }
    }
    
    private func resolveConflict(_ conflict: CoreTypes.ScheduleConflict) async {
        // Resolve individual conflict by reassigning or adjusting times
    }
}

// MARK: - Supporting Components

struct ScheduleStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ConflictCard: View {
    let conflict: CoreTypes.ScheduleConflict
    let onResolve: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: getSeverityIcon(conflict.severity))
                    .foregroundColor(getSeverityColor(conflict.severity))
                
                Text(conflict.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Resolve", action: onResolve)
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
            }
            
            Text(conflict.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func getSeverityIcon(_ severity: CoreTypes.ConflictSeverity) -> String {
        switch severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "info.circle"
        }
    }
    
    private func getSeverityColor(_ severity: CoreTypes.ConflictSeverity) -> Color {
        switch severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

struct DayScheduleRow: View {
    let date: Date
    let schedules: [CoreTypes.WorkerShift]
    let workers: [CoreTypes.WorkerSummary]
    let onScheduleEdit: (CoreTypes.WorkerShift) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(date.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(schedules.count) shifts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(schedules.prefix(3), id: \.id) { shift in
                ShiftCard(shift: shift, onEdit: { onScheduleEdit(shift) })
            }
            
            if schedules.count > 3 {
                Text("+ \(schedules.count - 3) more shifts")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ShiftCard: View {
    let shift: CoreTypes.WorkerShift
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(getWorkerName(shift.workerId))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(shift.buildingName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(shift.startTime.formatted(date: .omitted, time: .shortened)) - \(shift.endTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
                Button("Edit", action: onEdit)
                    .font(.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func getWorkerName(_ workerId: String) -> String {
        // Would look up worker name from container
        return "Worker \(workerId.prefix(4))"
    }
}

struct WorkerScheduleCard: View {
    let schedule: CoreTypes.WeeklySchedule
    let workerId: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let workerShifts = schedule.shifts.filter { $0.workerId == workerId }
            
            ForEach(workerShifts, id: \.id) { shift in
                HStack {
                    Text(shift.buildingName)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(shift.startTime.formatted(date: .omitted, time: .shortened)) - \(shift.endTime.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct WorkerScheduleSummary: View {
    let worker: CoreTypes.WorkerSummary
    let schedules: [CoreTypes.WeeklySchedule]
    
    var body: some View {
        HStack {
            Circle()
                .fill(worker.isActive ? .green : .red)
                .frame(width: 8, height: 8)
            
            Text(worker.name)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            let workerShifts = schedules.flatMap { $0.shifts }.filter { $0.workerId == worker.id }
            Text("\(workerShifts.count) shifts")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(calculateTotalHours(workerShifts))h")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
    
    private func calculateTotalHours(_ shifts: [CoreTypes.WorkerShift]) -> Int {
        return shifts.reduce(0) { total, shift in
            total + Int(shift.endTime.timeIntervalSince(shift.startTime) / 3600)
        }
    }
}

struct OptimizationMetric: View {
    let title: String
    let value: String
    let change: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(change)
                .font(.caption2)
                .foregroundColor(change.hasPrefix("+") ? .green : .red)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}