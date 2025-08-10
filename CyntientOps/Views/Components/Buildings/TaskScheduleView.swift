//
//  TaskScheduleView.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: Removed type alias redeclarations
//  ✅ FIXED: Added explicit type annotations where needed
//  ✅ FIXED: Fixed binding issues in FilterView
//  ✅ FIXED: Simplified complex expressions
//  ✅ FIXED: All compilation errors resolved
//

import SwiftUI

struct TaskScheduleView: View {
    let buildingID: String
    
    @State private var selectedDate: Date = Date()
    @State private var calendar = Calendar.current
    @State private var monthDates: [Date] = []
    @State private var visibleMonth: Date = Date()
    @State private var weekDays: [String] = []
    @State private var tasks: [CoreTypes.ContextualTask] = []
    @State private var isLoading = true
    @State private var showTaskDetail: CoreTypes.ContextualTask? = nil
    @State private var showAddTask = false
    @State private var selectedView: ScheduleView = .month
    @State private var showFilterOptions = false
    @State private var filterOptions = FilterOptions()
    @State private var currentBuilding: CoreTypes.NamedCoordinate?
    
    enum ScheduleView {
        case week
        case month
    }
    
    struct FilterOptions {
        var showCompleted = true
        var categories: Set<CoreTypes.TaskCategory> = Set(CoreTypes.TaskCategory.allCases)
        var urgencies: Set<CoreTypes.TaskUrgency> = Set(CoreTypes.TaskUrgency.allCases)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Calendar header with month and controls
            calendarHeader
            
            // Week or month selector
            viewSelector
            
            // Weekday header
            weekdayHeader
            
            // Calendar body (week or month view)
            if selectedView == .month {
                monthView
            } else {
                weekView
            }
            
            // Task list for selected date
            taskListSection
        }
        .navigationTitle("Task Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showAddTask = true }) {
                        Label("Add Task", systemImage: "plus")
                    }
                    
                    Button(action: { showFilterOptions = true }) {
                        Label("Filter Tasks", systemImage: "line.horizontal.3.decrease.circle")
                    }
                    
                    Button(action: { refreshData() }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            setupCalendar()
            loadTasks()
            loadBuildingInfo()
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            loadTasksForSelectedDate()
        }
        .onChange(of: visibleMonth) { oldValue, newValue in
            updateMonthDates()
        }
        .sheet(item: $showTaskDetail) { task in
            NavigationView {
                UnifiedTaskDetailView(task: task, mode: .worker)
            }
        }
        .sheet(isPresented: $showAddTask) {
            // ✅ FIXED: Use existing TaskFormView with correct constructor
            TaskFormView(buildingID: buildingID) { (newTask: CoreTypes.MaintenanceTask) in
                // Convert MaintenanceTask to CoreTypes.ContextualTask if needed
                let contextualTask = CoreTypes.ContextualTask(
                    id: UUID().uuidString,
                    title: newTask.title,
                    description: newTask.description,
                    status: .pending,
                    completedAt: nil,
                    dueDate: newTask.dueDate,
                    category: newTask.category,
                    urgency: newTask.urgency,
                    building: currentBuilding,
                    worker: getCurrentWorker(),
                    buildingId: buildingID,
                    priority: newTask.urgency
                )
                tasks.append(contextualTask)
                showAddTask = false
            }
        }
        .sheet(isPresented: $showFilterOptions) {
            FilterView(options: $filterOptions)
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadBuildingInfo() {
        Task {
            do {
                let buildings = try await BuildingService.shared.getAllBuildings()
                if let building = buildings.first(where: { $0.id == buildingID }) {
                    await MainActor.run {
                        self.currentBuilding = building
                    }
                }
            } catch {
                print("Failed to load building info: \(error)")
            }
        }
    }
    
    private func getCurrentWorker() -> CoreTypes.WorkerProfile? {
        guard let workerId = NewAuthManager.shared.workerId else { return nil }
        let workerName = NewAuthManager.shared.currentWorkerName
        
        return CoreTypes.WorkerProfile(
            id: workerId,
            name: workerName,
            email: "",
            phoneNumber: "",
            role: .worker,
            skills: [],
            certifications: [],
            hireDate: Date(),
            isActive: true,
            profileImageUrl: nil
        )
    }
    
    private func taskStatusColor(_ task: CoreTypes.ContextualTask) -> Color {
        if task.isCompleted {
            return .gray
        } else {
            return CyntientOpsDesign.EnumColors.taskUrgency(task.urgency ?? .medium)
        }
    }
    
    private func taskStatusText(_ task: CoreTypes.ContextualTask) -> String {
        if task.isCompleted {
            return "Completed"
        } else if isPastDue(task) {
            return "Overdue"
        } else {
            return "Pending"
        }
    }
    
    private func isPastDue(_ task: CoreTypes.ContextualTask) -> Bool {
        guard let dueDate = task.dueDate else { return false }
        return !task.isCompleted && dueDate < Date()
    }
    
    // MARK: - Calendar Header
    
    private var calendarHeader: some View {
        HStack {
            Text(monthYearString(from: visibleMonth))
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            HStack {
                Button(action: { navigateMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .padding(8)
                }
                
                Button(action: {
                    selectedDate = Date()
                    visibleMonth = Date()
                    updateMonthDates()
                }) {
                    Text("Today")
                        .font(.callout)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: { navigateMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .padding(8)
                }
            }
        }
        .padding()
    }
    
    // MARK: - View Selector
    
    private var viewSelector: some View {
        Picker("View", selection: $selectedView) {
            Text("Week").tag(ScheduleView.week)
            Text("Month").tag(ScheduleView.month)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Weekday Header
    
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Month View
    
    private var monthView: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                ForEach(monthDates, id: \.self) { date in
                    dateCell(date)
                }
            }
        }
        .padding(.horizontal, 2)
    }
    
    // MARK: - Week View
    
    private var weekView: some View {
        let weekDates = getWeekDates(for: selectedDate)
        
        return HStack(spacing: 0) {
            ForEach(weekDates, id: \.self) { date in
                dateCell(date)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 2)
    }
    
    // MARK: - Date Cell
    
    private func dateCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let isCurrentMonth = calendar.component(.month, from: date) == calendar.component(.month, from: visibleMonth)
        let tasksForDate = getTasksForDate(date)
        
        return Button(action: {
            selectedDate = date
            if !isCurrentMonth {
                visibleMonth = date
                updateMonthDates()
            }
        }) {
            VStack(spacing: 4) {
                let dayNumber = calendar.component(.day, from: date)
                let fontSize: CGFloat = selectedView == .week ? 20 : 16
                let fontWeight: Font.Weight = (isSelected || isToday) ? .bold : .regular
                
                let textColor = getTextColor(isCurrentMonth: isCurrentMonth, isSelected: isSelected, isToday: isToday)
                
                Text("\(dayNumber)")
                    .font(.system(size: fontSize))
                    .fontWeight(fontWeight)
                    .foregroundColor(textColor)
                
                // ✅ FIXED: Simplified task indicators
                if selectedView == .week {
                    weekViewTaskIndicators(tasksForDate)
                } else {
                    monthViewTaskIndicators(tasksForDate)
                }
            }
            .frame(height: selectedView == .week ? 80 : 50)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(8)
            .padding(2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // ✅ FIXED: Separated complex view into smaller functions
    private func weekViewTaskIndicators(_ tasksForDate: [CoreTypes.ContextualTask]) -> some View {
        VStack(spacing: 2) {
            ForEach(Array(tasksForDate.prefix(3).enumerated()), id: \.offset) { index, task in
                Circle()
                    .fill(taskStatusColor(task))
                    .frame(width: 8, height: 8)
            }
            
            if tasksForDate.count > 3 {
                Text("+\(tasksForDate.count - 3)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 4)
    }
    
    private func monthViewTaskIndicators(_ tasksForDate: [CoreTypes.ContextualTask]) -> some View {
        Group {
            if !tasksForDate.isEmpty {
                HStack(spacing: 4) {
                    ForEach(0..<min(3, tasksForDate.count), id: \.self) { index in
                        Circle()
                            .fill(taskStatusColor(tasksForDate[index]))
                            .frame(width: 6, height: 6)
                    }
                    
                    if tasksForDate.count > 3 {
                        Text("+\(tasksForDate.count - 3)")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 2)
            }
        }
    }
    
    private func getTextColor(isCurrentMonth: Bool, isSelected: Bool, isToday: Bool) -> Color {
        if !isCurrentMonth { return .gray }
        if isSelected { return .white }
        if isToday { return .blue }
        return .primary
    }
    
    // MARK: - Task List Section
    
    private var taskListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(calendar.isDateInToday(selectedDate) ? "Today" : dateString(from: selectedDate)), \(tasksForSelectedDate.count) tasks")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showAddTask = true }) {
                    Label("Add", systemImage: "plus.circle")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            if isLoading {
                ProgressView()
                    .padding()
                    .frame(maxWidth: .infinity)
            } else if tasksForSelectedDate.isEmpty {
                emptyTasksView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tasksForSelectedDate) { task in
                            TaskRow(task: task)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    showTaskDetail = task
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(maxHeight: 300)
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyTasksView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No tasks scheduled for this date")
                .font(.callout)
                .foregroundColor(.secondary)
            
            Button(action: { showAddTask = true }) {
                Text("Add Task")
                    .font(.caption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var tasksForSelectedDate: [CoreTypes.ContextualTask] {
        getTasksForDate(selectedDate)
            .filter { task in
                if !filterOptions.showCompleted && task.isCompleted {
                    return false
                }
                
                if !filterOptions.categories.contains(task.category ?? .maintenance) {
                    return false
                }
                
                if !filterOptions.urgencies.contains(task.urgency ?? .medium) {
                    return false
                }
                
                return true
            }
            .sorted { (first: CoreTypes.ContextualTask, second: CoreTypes.ContextualTask) in
                let firstDate = first.dueDate ?? Date.distantFuture
                let secondDate = second.dueDate ?? Date.distantFuture
                
                if firstDate != secondDate {
                    return firstDate < secondDate
                }
                
                let firstPriority = urgencyPriority(first.urgency ?? .medium)
                let secondPriority = urgencyPriority(second.urgency ?? .medium)
                return firstPriority > secondPriority
            }
    }
    
    private func urgencyPriority(_ urgency: CoreTypes.TaskUrgency) -> Int {
        switch urgency {
        case .critical, .emergency: return 5
        case .urgent:               return 4
        case .high:                 return 3
        case .normal, .medium:      return 2
        case .low:                  return 1
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupCalendar() {
        weekDays = calendar.veryShortWeekdaySymbols
        calendar.firstWeekday = 1
        updateMonthDates()
    }
    
    private func updateMonthDates() {
        monthDates = getDaysInMonth(for: visibleMonth)
    }
    
    private func getDaysInMonth(for date: Date) -> [Date] {
        var dates: [Date] = []
        
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDayOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offsetDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        if offsetDays > 0 {
            for day in (1...offsetDays).reversed() {
                if let prevDate = calendar.date(byAdding: .day, value: -day, to: firstDayOfMonth) {
                    dates.append(prevDate)
                }
            }
        }
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                dates.append(date)
            }
        }
        
        let totalDays = dates.count
        let remainingDays = 42 - totalDays
        
        if remainingDays > 0 {
            for day in 0..<remainingDays {
                if let nextDate = dates.last,
                   let newDate = calendar.date(byAdding: .day, value: day + 1, to: nextDate) {
                    dates.append(newDate)
                }
            }
        }
        
        return dates
    }
    
    private func getWeekDates(for date: Date) -> [Date] {
        var weekDates: [Date] = []
        
        let weekday = calendar.component(.weekday, from: date)
        let daysToSubtract = (weekday - calendar.firstWeekday + 7) % 7
        
        if let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: date) {
            for day in 0..<7 {
                if let weekDate = calendar.date(byAdding: .day, value: day, to: startOfWeek) {
                    weekDates.append(weekDate)
                }
            }
        }
        
        return weekDates
    }
    
    private func navigateMonth(by months: Int) {
        if let newDate = calendar.date(byAdding: .month, value: months, to: visibleMonth) {
            visibleMonth = newDate
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func getTasksForDate(_ date: Date) -> [CoreTypes.ContextualTask] {
        return tasks.filter { task in
            guard let taskDate = task.dueDate else { return false }
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadTasks() {
        isLoading = true
        
        Task {
            do {
                let contextualTasks = try await TaskService.shared.getTasks(for: buildingID, date: Date())
                
                await MainActor.run {
                    self.tasks = contextualTasks
                    self.isLoading = false
                    loadTasksForSelectedDate()
                }
            } catch {
                await MainActor.run {
                    self.tasks = []
                    self.isLoading = false
                    print("❌ Failed to load tasks: \(error)")
                }
            }
        }
    }
    
    private func loadTasksForSelectedDate() {
        // This method updates the filtered tasks for the selected date
        // The actual filtering happens in the computed property tasksForSelectedDate
    }
    
    private func refreshData() {
        loadTasks()
    }
}

// MARK: - Task Row
struct TaskRow: View {
    let task: CoreTypes.ContextualTask
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : categoryIcon(task.category ?? .maintenance))
                    .foregroundColor(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(task.description ?? "No description")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 15) {
                    let categoryValue = task.category ?? .maintenance
                    Label(categoryValue.rawValue.capitalized, systemImage: categoryIcon(categoryValue))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let dueDate = task.dueDate {
                        Label(formatTime(dueDate), systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var statusColor: Color {
        if task.isCompleted {
            return .gray
        } else {
            return CyntientOpsDesign.EnumColors.taskUrgency(task.urgency ?? .medium)
        }
    }
    
    private var statusText: String {
        if task.isCompleted {
            return "Completed"
        } else if isPastDue(task) {
            return "Overdue"
        } else {
            return "Pending"
        }
    }
    
    private func isPastDue(_ task: CoreTypes.ContextualTask) -> Bool {
        guard let dueDate = task.dueDate else { return false }
        return !task.isCompleted && dueDate < Date()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func categoryIcon(_ category: CoreTypes.TaskCategory) -> String {
        switch category {
        case .cleaning:         return "sparkles"
        case .maintenance:      return "wrench.and.screwdriver"
        case .repair:          return "hammer"
        case .inspection:      return "magnifyingglass"
        case .security:        return "shield"
        case .landscaping:     return "leaf"
        case .installation:    return "plus.square"
        case .utilities:       return "bolt"
        case .emergency:       return "exclamationmark.triangle.fill"
        case .renovation:      return "building.2"
        case .sanitation:      return "trash"
        case .administrative:  return "folder"
        case .compliance:      return "checkmark.shield"
        }
    }
}

// MARK: - Filter View
struct FilterView: View {
    @Binding var options: TaskScheduleView.FilterOptions
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Status")) {
                    Toggle("Show Completed Tasks", isOn: $options.showCompleted)
                }
                
                Section(header: Text("Categories")) {
                    ForEach(CoreTypes.TaskCategory.allCases, id: \.self) { category in
                        Button(action: { toggleCategory(category) }) {
                            HStack {
                                Image(systemName: categoryIcon(category))
                                    .foregroundColor(categoryColor(category))
                                
                                Text(category.rawValue.capitalized)
                                
                                Spacer()
                                
                                if options.categories.contains(category) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Section(header: Text("Urgency")) {
                    ForEach(CoreTypes.TaskUrgency.allCases, id: \.self) { urgency in
                        Button(action: { toggleUrgency(urgency) }) {
                            HStack {
                                Circle()
                                    .fill(CyntientOpsDesign.EnumColors.taskUrgency(urgency))
                                    .frame(width: 10, height: 10)
                                
                                Text(urgency.rawValue.capitalized)
                                
                                Spacer()
                                
                                if options.urgencies.contains(urgency) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Section {
                    Button(action: {
                        options.showCompleted = true
                        options.categories = Set(CoreTypes.TaskCategory.allCases)
                        options.urgencies = Set(CoreTypes.TaskUrgency.allCases)
                    }) {
                        Text("Reset Filters")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Filter Tasks")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func toggleCategory(_ category: CoreTypes.TaskCategory) {
        if options.categories.contains(category) {
            if options.categories.count > 1 {
                options.categories.remove(category)
            }
        } else {
            options.categories.insert(category)
        }
    }
    
    private func toggleUrgency(_ urgency: CoreTypes.TaskUrgency) {
        if options.urgencies.contains(urgency) {
            if options.urgencies.count > 1 {
                options.urgencies.remove(urgency)
            }
        } else {
            options.urgencies.insert(urgency)
        }
    }
    
    private func categoryColor(_ category: CoreTypes.TaskCategory) -> Color {
        switch category {
        case .cleaning:         return .blue
        case .maintenance:      return .orange
        case .repair:          return .red
        case .inspection:      return .purple
        case .security:        return .indigo
        case .landscaping:     return .green
        case .installation:    return .teal
        case .utilities:       return .yellow
        case .emergency:       return .red
        case .renovation:      return .brown
        case .sanitation:      return .mint
        case .administrative:  return .gray
        case .compliance:      return .cyan
        }
    }
    
    private func categoryIcon(_ category: CoreTypes.TaskCategory) -> String {
        switch category {
        case .cleaning:         return "sparkles"
        case .maintenance:      return "wrench.and.screwdriver"
        case .repair:          return "hammer"
        case .inspection:      return "magnifyingglass"
        case .security:        return "shield"
        case .landscaping:     return "leaf"
        case .installation:    return "plus.square"
        case .utilities:       return "bolt"
        case .emergency:       return "exclamationmark.triangle.fill"
        case .renovation:      return "building.2"
        case .sanitation:      return "trash"
        case .administrative:  return "folder"
        case .compliance:      return "checkmark.shield"
        }
    }
}
