//
//  BuildingRoutineComponents.swift
//  CyntientOps v6.0
//
//  📅 ROUTINES: Daily/Weekly/Monthly task management
//  ✅ COMPLETION: Real-time progress tracking
//  🔄 TEMPLATES: Automated task generation from templates
//

import SwiftUI
import Combine

// MARK: - Daily Routines Card

struct DailyRoutinesCard: View {
    let buildingId: String
    let workerId: String?
    @State private var routines: [DailyRoutineTask] = []
    @State private var isLoading = true
    @State private var selectedTimeFilter: TimeOfDay = .all
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    enum TimeOfDay: String, CaseIterable {
        case all = "All Day"
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        
        var icon: String {
            switch self {
            case .all: return "clock"
            case .morning: return "sunrise.fill"
            case .afternoon: return "sun.max.fill"
            case .evening: return "sunset.fill"
            }
        }
        
        func matches(hour: Int) -> Bool {
            switch self {
            case .all: return true
            case .morning: return hour >= 6 && hour < 12
            case .afternoon: return hour >= 12 && hour < 17
            case .evening: return hour >= 17 || hour < 6
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with time filter
            HStack {
                Label("Daily Routines", systemImage: "calendar.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Completion stats
                if !routines.isEmpty {
                    Text("\(completedCount) of \(routines.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Time filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimeOfDay.allCases, id: \.self) { timeOfDay in
                        TimeFilterPill(
                            timeOfDay: timeOfDay,
                            isSelected: selectedTimeFilter == timeOfDay,
                            action: { selectedTimeFilter = timeOfDay }
                        )
                    }
                }
            }
            
            // Routines list
            if isLoading {
                ProgressView("Loading routines...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if filteredRoutines.isEmpty {
                EmptyRoutinesView(timeFilter: selectedTimeFilter)
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredRoutines) { routine in
                        RoutineChecklistRow(
                            routine: routine,
                            onToggle: { toggleRoutineCompletion(routine) },
                            onViewDetails: { viewRoutineDetails(routine) }
                        )
                    }
                }
            }
            
            // Progress bar
            if !routines.isEmpty {
                RoutineProgressBar(
                    completed: completedCount,
                    total: routines.count
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .task {
            await loadDailyRoutines()
        }
        .onReceive(dashboardSync.crossDashboardUpdates) { update in
            if update.buildingId == buildingId &&
               (update.type == .taskCompleted || update.type == .taskUpdated) {
                Task { await loadDailyRoutines() }
            }
        }
    }
    
    private var filteredRoutines: [DailyRoutineTask] {
        routines.filter { routine in
            selectedTimeFilter == .all ||
            selectedTimeFilter.matches(hour: routine.scheduledHour ?? 12)
        }
    }
    
    private var completedCount: Int {
        routines.filter { $0.isCompleted }.count
    }
    
    private func loadDailyRoutines() async {
        do {
            let today = Date()
            let dateString = ISO8601DateFormatter.string(
                from: today,
                timeZone: .current,
                formatOptions: [.withFullDate]
            )
            
            // Query routine tasks for today from GRDB
            let rows = try await GRDBManager.shared.query("""
                SELECT rt.*, wt.name as worker_name, b.name as building_name
                FROM routine_tasks rt
                LEFT JOIN workers wt ON rt.worker_id = wt.id
                LEFT JOIN buildings b ON rt.building_id = b.id
                WHERE rt.building_id = ?
                AND rt.scheduled_date = ?
                AND rt.frequency = 'daily'
                \(workerId != nil ? "AND rt.worker_id = ?" : "")
                ORDER BY rt.scheduled_hour, rt.priority DESC
            """, workerId != nil ? [buildingId, dateString, workerId!] : [buildingId, dateString])
            
            routines = rows.compactMap { row in
                DailyRoutineTask(from: row)
            }
            
            isLoading = false
            
        } catch {
            print("❌ Error loading daily routines: \(error)")
            isLoading = false
        }
    }
    
    private func toggleRoutineCompletion(_ routine: DailyRoutineTask) {
        Task {
            do {
                if routine.isCompleted {
                    // Mark as incomplete
                    try await GRDBManager.shared.execute("""
                        UPDATE routine_tasks 
                        SET status = 'pending', completed_at = NULL
                        WHERE id = ?
                    """, [routine.id])
                } else {
                    // Mark as complete
                    let completionId = UUID().uuidString
                    let now = Date()
                    
                    // Update task status
                    try await GRDBManager.shared.execute("""
                        UPDATE routine_tasks 
                        SET status = 'completed', completed_at = ?
                        WHERE id = ?
                    """, [now.ISO8601Format(), routine.id])
                    
                    // Create completion record
                    try await GRDBManager.shared.execute("""
                        INSERT INTO task_completions
                        (id, task_id, worker_id, building_id, completed_at, created_at)
                        VALUES (?, ?, ?, ?, ?, ?)
                    """, [
                        completionId,
                        routine.id,
                        workerId ?? "unknown",
                        buildingId,
                        now.ISO8601Format(),
                        now.ISO8601Format()
                    ])
                }
                
                // Broadcast update
                let update = CoreTypes.DashboardUpdate(
                    source: .worker,
                    type: routine.isCompleted ? .taskUpdated : .taskCompleted,
                    buildingId: buildingId,
                    workerId: workerId ?? "unknown",
                    data: [
                        "taskId": routine.id,
                        "taskName": routine.title,
                        "routineType": "daily"
                    ]
                )
                dashboardSync.broadcastWorkerUpdate(update)
                
                // Reload routines
                await loadDailyRoutines()
                
            } catch {
                print("❌ Error toggling routine completion: \(error)")
            }
        }
    }
    
    private func viewRoutineDetails(_ routine: DailyRoutineTask) {
        // Navigate to task detail view
        // This would be handled by the parent view
    }
}

// MARK: - Weekly Routines Card

struct WeeklyRoutinesCard: View {
    let buildingId: String
    let workerId: String?
    @State private var routines: [WeeklyRoutineTask] = []
    @State private var isLoading = true
    @State private var selectedWeek = 0 // 0 = current week, -1 = last week, 1 = next week
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with week navigation
            HStack {
                Label("Weekly Routines", systemImage: "calendar.badge.clock")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Week navigation
                HStack(spacing: 12) {
                    Button(action: { selectedWeek -= 1 }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                    
                    Text(weekTitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button(action: { selectedWeek += 1 }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                    }
                    .disabled(selectedWeek >= 2) // Limit future weeks
                }
            }
            
            // Week calendar view
            WeekCalendarView(
                routines: routines,
                selectedWeek: selectedWeek,
                onDaySelected: { date in
                    // Filter routines for selected day
                }
            )
            
            // Routines list grouped by day
            if isLoading {
                ProgressView("Loading weekly routines...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if routines.isEmpty {
                Text("No weekly routines scheduled")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .multilineTextAlignment(.center)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(groupedRoutinesByDay, id: \.key) { day, dayRoutines in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(day)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                            
                            ForEach(dayRoutines) { routine in
                                WeeklyRoutineRow(
                                    routine: routine,
                                    onToggle: { toggleRoutineCompletion(routine) }
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .task {
            await loadWeeklyRoutines()
        }
    }
    
    private var weekTitle: String {
        switch selectedWeek {
        case -1: return "Last Week"
        case 0: return "This Week"
        case 1: return "Next Week"
        default: return "\(selectedWeek > 0 ? "+" : "")\(selectedWeek) weeks"
        }
    }
    
    private var groupedRoutinesByDay: [(key: String, value: [WeeklyRoutineTask])] {
        Dictionary(grouping: routines) { routine in
            routine.dayOfWeek
        }
        .sorted { first, second in
            let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            let firstIndex = days.firstIndex(of: first.key) ?? 7
            let secondIndex = days.firstIndex(of: second.key) ?? 7
            return firstIndex < secondIndex
        }
    }
    
    private func loadWeeklyRoutines() async {
        // Implementation similar to daily routines but filtering for weekly frequency
        isLoading = false
    }
    
    private func toggleRoutineCompletion(_ routine: WeeklyRoutineTask) {
        // Similar to daily routine completion
    }
}

// MARK: - Monthly Routines Card

struct MonthlyRoutinesCard: View {
    let buildingId: String
    let workerId: String?
    @State private var routines: [MonthlyRoutineTask] = []
    @State private var isLoading = true
    @State private var selectedMonth = Date()
    @State private var showingScheduleEditor = false
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with month picker
            HStack {
                Label("Monthly Routines", systemImage: "calendar.badge.exclamationmark")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Month picker
                MonthPicker(selectedMonth: $selectedMonth)
            }
            
            // Monthly calendar grid
            RoutineScheduleCalendar(
                month: selectedMonth,
                routines: routines,
                onDateSelected: { date in
                    // Show routines for selected date
                }
            )
            
            // Upcoming monthly tasks
            if isLoading {
                ProgressView("Loading monthly routines...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if upcomingRoutines.isEmpty {
                Text("No monthly routines scheduled")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .multilineTextAlignment(.center)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Upcoming This Month")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.6))
                    
                    ForEach(upcomingRoutines) { routine in
                        MonthlyRoutineRow(
                            routine: routine,
                            onSchedule: { showScheduleEditor(for: routine) },
                            onComplete: { completeRoutine(routine) }
                        )
                    }
                }
            }
            
            // Add routine button (temporarily disabled - admin role check needs proper implementation)
            // TODO: Add proper user role checking with AuthManager or similar service
            /*
            Button(action: { showingScheduleEditor = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Monthly Routine")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            */
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .task {
            await loadMonthlyRoutines()
        }
        .sheet(isPresented: $showingScheduleEditor) {
            AddRoutineSheet(
                buildingId: buildingId,
                frequency: .monthly,
                onSave: { newRoutine in
                    Task { await loadMonthlyRoutines() }
                }
            )
        }
    }
    
    private var upcomingRoutines: [MonthlyRoutineTask] {
        routines.filter { !$0.isCompleted }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .prefix(5)
            .map { $0 }
    }
    
    private func loadMonthlyRoutines() async {
        // Load monthly routines from GRDB
        isLoading = false
    }
    
    private func showScheduleEditor(for routine: MonthlyRoutineTask) {
        // Show reschedule sheet
    }
    
    private func completeRoutine(_ routine: MonthlyRoutineTask) {
        // Mark routine as complete
    }
}

// MARK: - Time of Day Section

struct TimeOfDaySection: View {
    let timeOfDay: String
    let icon: String
    let routines: [DailyRoutineTask]
    let onToggle: (DailyRoutineTask) -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Label(timeOfDay, systemImage: icon)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // Completion count
                Text("\(completedCount)/\(routines.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                // Expand/collapse
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.03))
            .cornerRadius(8)
            
            if isExpanded {
                ForEach(routines) { routine in
                    RoutineChecklistRow(
                        routine: routine,
                        onToggle: { onToggle(routine) },
                        onViewDetails: { }
                    )
                }
            }
        }
    }
    
    private var completedCount: Int {
        routines.filter { $0.isCompleted }.count
    }
}

// MARK: - Individual Routine Components

struct RoutineChecklistRow: View {
    let routine: DailyRoutineTask
    let onToggle: () -> Void
    let onViewDetails: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: routine.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(routine.isCompleted ? .green : .white.opacity(0.5))
            }
            
            // Task info
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                    .strikethrough(routine.isCompleted)
                
                HStack(spacing: 8) {
                    // Time
                    if let time = routine.scheduledTime {
                        Label(time, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Category
                    Text(routine.category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor(routine.category).opacity(0.2))
                        .foregroundColor(categoryColor(routine.category))
                        .cornerRadius(4)
                    
                    // Priority
                    if routine.priority == "high" {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Detail button
            Button(action: onViewDetails) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(routine.isCompleted ? Color.green.opacity(0.05) : Color.clear)
        .cornerRadius(8)
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "cleaning": return .blue
        case "maintenance": return .orange
        case "sanitation": return .green
        case "inspection": return .purple
        default: return .gray
        }
    }
}

// MARK: - Schedule Components

struct RoutineScheduleCalendar: View {
    let month: Date
    let routines: [MonthlyRoutineTask]
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    @State private var selectedDate: Date?
    
    var body: some View {
        VStack(spacing: 8) {
            // Days of week header
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            let days = generateDays(for: month)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: selectedDate == date,
                            hasRoutines: hasRoutines(on: date),
                            routineCount: routineCount(on: date),
                            onTap: {
                                selectedDate = date
                                onDateSelected(date)
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    
    private func generateDays(for month: Date) -> [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: month),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        // Fill remaining days to complete the grid
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func hasRoutines(on date: Date) -> Bool {
        routines.contains { routine in
            calendar.isDate(routine.scheduledDate, inSameDayAs: date)
        }
    }
    
    private func routineCount(on date: Date) -> Int {
        routines.filter { routine in
            calendar.isDate(routine.scheduledDate, inSameDayAs: date)
        }.count
    }
}

struct RecurringTaskEditor: View {
    @Binding var frequency: String
    @Binding var daysOfWeek: Set<String>
    @Binding var dayOfMonth: Int?
    @Binding var startTime: Date
    @Binding var endTime: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Frequency picker
            Picker("Frequency", selection: $frequency) {
                Text("Daily").tag("daily")
                Text("Weekly").tag("weekly")
                Text("Bi-Weekly").tag("bi-weekly")
                Text("Monthly").tag("monthly")
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Days of week (for weekly/bi-weekly)
            if frequency == "weekly" || frequency == "bi-weekly" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Days of Week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                            DayToggle(
                                day: day,
                                isSelected: daysOfWeek.contains(day),
                                onToggle: {
                                    if daysOfWeek.contains(day) {
                                        daysOfWeek.remove(day)
                                    } else {
                                        daysOfWeek.insert(day)
                                    }
                                }
                            )
                        }
                    }
                }
            }
            
            // Day of month (for monthly)
            if frequency == "monthly" {
                Stepper("Day of month: \(dayOfMonth ?? 1)", value: Binding(
                    get: { dayOfMonth ?? 1 },
                    set: { dayOfMonth = $0 }
                ), in: 1...31)
            }
            
            // Time range
            VStack(alignment: .leading, spacing: 8) {
                Text("Time Window")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    
                    Text("to")
                        .foregroundColor(.secondary)
                    
                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TimeFilterPill: View {
    let timeOfDay: DailyRoutinesCard.TimeOfDay
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: timeOfDay.icon)
                    .font(.caption)
                Text(timeOfDay.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
            )
        }
    }
}

struct EmptyRoutinesView: View {
    let timeFilter: DailyRoutinesCard.TimeOfDay
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: timeFilter.icon)
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.3))
            
            Text("No \(timeFilter.rawValue.lowercased()) routines")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }
}

struct RoutineProgressBar: View {
    let completed: Int
    let total: Int
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
    
    private var progressColor: Color {
        switch progress {
        case 0..<0.5: return .red
        case 0.5..<0.8: return .orange
        case 0.8..<1.0: return .yellow
        case 1.0: return .green
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Today's Progress")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(progressColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

struct AddRoutineSheet: View {
    let buildingId: String
    let frequency: CoreTypes.TaskFrequency
    let onSave: (RoutineTemplate) -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var category = "Cleaning"
    @State private var priority = "normal"
    @State private var estimatedDuration = 30
    @State private var requiresPhoto = false
    @State private var selectedWorker: String?
    @State private var recurringSettings = RecurringSettings()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Task Name", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $category) {
                        ForEach(["Cleaning", "Maintenance", "Sanitation", "Inspection"], id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        Text("Low").tag("low")
                        Text("Normal").tag("normal")
                        Text("High").tag("high")
                        Text("Critical").tag("critical")
                    }
                }
                
                Section(header: Text("Schedule")) {
                    RecurringTaskEditor(
                        frequency: .constant(frequency.rawValue),
                        daysOfWeek: $recurringSettings.daysOfWeek,
                        dayOfMonth: $recurringSettings.dayOfMonth,
                        startTime: $recurringSettings.startTime,
                        endTime: $recurringSettings.endTime
                    )
                    .disabled(true) // Frequency is fixed based on context
                }
                
                Section(header: Text("Requirements")) {
                    Stepper("Duration: \(estimatedDuration) min",
                           value: $estimatedDuration,
                           in: 5...480,
                           step: 5)
                    
                    Toggle("Requires Photo Evidence", isOn: $requiresPhoto)
                    
                    // Worker assignment picker
                    // TODO: Load workers for building
                }
                
                Section {
                    Text("This routine will be created for \(frequency.rawValue.lowercased()) execution")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add \(frequency.rawValue.capitalized) Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRoutine()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveRoutine() {
        let template = RoutineTemplate(
            id: UUID().uuidString,
            title: title,
            description: description,
            category: category,
            frequency: frequency,
            priority: priority,
            estimatedDuration: estimatedDuration,
            requiresPhoto: requiresPhoto,
            buildingId: buildingId,
            workerId: selectedWorker,
            recurringSettings: recurringSettings
        )
        
        onSave(template)
        dismiss()
    }
}

// MARK: - Supporting Components

struct WeekCalendarView: View {
    let routines: [WeeklyRoutineTask]
    let selectedWeek: Int
    let onDaySelected: (Date) -> Void
    
    var body: some View {
        // Implementation of week view
        EmptyView()
    }
}

struct WeeklyRoutineRow: View {
    let routine: WeeklyRoutineTask
    let onToggle: () -> Void
    
    var body: some View {
        // Implementation similar to RoutineChecklistRow
        EmptyView()
    }
}

struct MonthlyRoutineRow: View {
    let routine: MonthlyRoutineTask
    let onSchedule: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        // Implementation for monthly routine display
        EmptyView()
    }
}

struct MonthPicker: View {
    @Binding var selectedMonth: Date
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: { addMonth(-1) }) {
                Image(systemName: "chevron.left")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Text(selectedMonth, format: .dateTime.month(.wide).year())
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Button(action: { addMonth(1) }) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private func addMonth(_ value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasRoutines: Bool
    let routineCount: Int
    let onTap: () -> Void
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
                    )
                
                VStack(spacing: 2) {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.subheadline)
                        .fontWeight(isToday ? .bold : .regular)
                        .foregroundColor(textColor)
                    
                    if hasRoutines {
                        HStack(spacing: 2) {
                            ForEach(0..<min(routineCount, 3), id: \.self) { _ in
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }
            }
            .frame(height: 36)
        }
    }
    
    private var backgroundColor: Color {
        if isSelected { return Color.blue.opacity(0.3) }
        if isToday { return Color.blue.opacity(0.1) }
        if hasRoutines { return Color.white.opacity(0.05) }
        return Color.clear
    }
    
    private var borderColor: Color {
        if isSelected { return .blue }
        if isToday { return .blue.opacity(0.5) }
        return .clear
    }
    
    private var textColor: Color {
        if isToday { return .blue }
        return .white.opacity(0.9)
    }
}

struct DayToggle: View {
    let day: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            Text(day)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .gray)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
        }
    }
}

// MARK: - Data Models

struct DailyRoutineTask: Identifiable {
    let id: String
    let title: String
    let category: String
    let priority: String
    let scheduledHour: Int?
    let scheduledTime: String?
    let buildingName: String
    let workerName: String?
    var isCompleted: Bool
    let requiresPhoto: Bool
    let estimatedDuration: Int
    
    init(from row: [String: Any]) {
        self.id = row["id"] as? String ?? UUID().uuidString
        self.title = row["title"] as? String ?? ""
        self.category = row["category"] as? String ?? "General"
        self.priority = row["priority"] as? String ?? "normal"
        self.scheduledHour = row["scheduled_hour"] as? Int
        self.scheduledTime = row["scheduled_time"] as? String
        self.buildingName = row["building_name"] as? String ?? ""
        self.workerName = row["worker_name"] as? String
        self.isCompleted = (row["status"] as? String ?? "pending") == "completed"
        self.requiresPhoto = (row["requires_photo"] as? Int ?? 0) == 1
        self.estimatedDuration = row["estimated_duration"] as? Int ?? 15
    }
}

struct WeeklyRoutineTask: Identifiable {
    let id: String
    let title: String
    let dayOfWeek: String
    var isCompleted: Bool
}

struct MonthlyRoutineTask: Identifiable {
    let id: String
    let title: String
    let scheduledDate: Date
    var isCompleted: Bool
}

struct RoutineTemplate {
    let id: String
    let title: String
    let description: String
    let category: String
    let frequency: CoreTypes.TaskFrequency
    let priority: String
    let estimatedDuration: Int
    let requiresPhoto: Bool
    let buildingId: String
    let workerId: String?
    let recurringSettings: RecurringSettings
}

struct RecurringSettings {
    var daysOfWeek: Set<String> = []
    var dayOfMonth: Int?
    var startTime = Date()
    var endTime = Date().addingTimeInterval(3600)
}
