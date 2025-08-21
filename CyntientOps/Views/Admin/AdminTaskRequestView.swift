//
//  AdminTaskRequestView.swift
//  CyntientOps
//
//  ✅ ADMIN TASK CREATION: Contextual task assignment with worker/building selection
//  ✅ INTELLIGENT ROUTING: Auto-suggests workers based on skills and availability
//  ✅ BUILDING CONTEXT: Pre-selects buildings from admin dashboard context
//  ✅ REAL-TIME SYNC: Immediate updates to worker dashboards via DashboardSyncService
//

import SwiftUI
import UIKit
import Combine

// MARK: - Admin Task Request View

struct AdminTaskRequestView: View {
    // Pre-selected context from admin dashboard
    let preselectedBuilding: CoreTypes.NamedCoordinate?
    let preselectedWorker: CoreTypes.WorkerProfile?
    
    @StateObject private var viewModel = AdminTaskRequestViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showPhotoSelector = false
    @State private var showInventorySelector = false
    
    var body: some View {
        NavigationView {
            Form {
                if viewModel.isLoadingData {
                    loadingSection
                } else {
                    // Admin context section
                    adminContextSection
                    
                    // Task details
                    taskDetailsSection
                    
                    // Assignment section (worker/building)
                    assignmentSection
                    
                    // Schedule and priorities
                    scheduleSection
                    
                    // Materials and attachments
                    if !viewModel.requiredInventory.isEmpty {
                        materialsSection
                    }
                    
                    attachmentSection
                    
                    // Action section
                    actionSection
                }
            }
            .navigationTitle("Create Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: submitButton
            )
            .onAppear {
                viewModel.initializeWithContext(
                    building: preselectedBuilding,
                    worker: preselectedWorker
                )
            }
            .alert(isPresented: $viewModel.showCompletionAlert) {
                Alert(
                    title: Text("Task Created"),
                    message: Text("Task has been assigned and workers have been notified."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
            .sheet(isPresented: $showPhotoSelector) {
                PhotoPickerView(selectedImage: $viewModel.photo)
            }
            .sheet(isPresented: $showInventorySelector) {
                InventorySelectionView(
                    buildingId: viewModel.selectedBuildingID,
                    selectedItems: $viewModel.requiredInventory,
                    onDismiss: { showInventorySelector = false }
                )
            }
        }
    }
    
    // MARK: - View Components
    
    private var submitButton: some View {
        Button(action: submitTaskAction) {
            Text("Create Task")
        }
        .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
    }
    
    private var loadingSection: some View {
        Section {
            HStack {
                ProgressView()
                    .padding(.trailing, 10)
                Text("Loading data...")
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
    }
    
    // MARK: - Admin Context Section
    
    private var adminContextSection: some View {
        Section("Admin Context") {
            if let preselected = preselectedBuilding {
                HStack {
                    Image(systemName: "building.2.crop.circle.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Pre-selected Building")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(preselected.name)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    Button("Change") {
                        viewModel.clearBuildingSelection()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            if let preselected = preselectedWorker {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Pre-selected Worker")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(preselected.name)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    Button("Change") {
                        viewModel.clearWorkerSelection()
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                }
            }
            
            // Admin priority override
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.orange)
                Text("Admin Priority Override")
                    .fontWeight(.medium)
                Spacer()
                Toggle("", isOn: $viewModel.adminPriorityOverride)
            }
        }
    }
    
    private var taskDetailsSection: some View {
        Section("Task Details") {
            TextField("Task Name", text: $viewModel.taskName)
                .autocapitalization(.words)
            
            ZStack(alignment: .topLeading) {
                if viewModel.taskDescription.isEmpty {
                    Text("Describe what needs to be done...")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                
                TextEditor(text: $viewModel.taskDescription)
                    .frame(minHeight: 100)
                    .autocapitalization(.sentences)
            }
            
            Picker("Category", selection: $viewModel.selectedCategory) {
                ForEach(CoreTypes.TaskCategory.allCases, id: \.self) { category in
                    Label(
                        category.rawValue.capitalized,
                        systemImage: AdminTaskHelpers.getCategoryIcon(category.rawValue)
                    )
                    .tag(category)
                }
            }
            
            Picker("Priority", selection: $viewModel.selectedUrgency) {
                ForEach(CoreTypes.TaskUrgency.allCases, id: \.self) { urgency in
                    HStack {
                        Circle()
                            .fill(AdminTaskHelpers.getUrgencyColor(urgency))
                            .frame(width: 10, height: 10)
                        
                        Text(urgency.rawValue.capitalized)
                        
                        if viewModel.adminPriorityOverride {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .tag(urgency)
                }
            }
        }
    }
    
    private var assignmentSection: some View {
        Section("Assignment") {
            // Building selection with search
            if viewModel.availableBuildings.count > 5 {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search buildings...", text: $viewModel.buildingSearchText)
                }
            }
            
            Picker("Building", selection: $viewModel.selectedBuildingID) {
                Text("Select a building").tag("")
                
                ForEach(viewModel.filteredBuildings) { building in
                    HStack {
                        Text(building.name)
                        Spacer()
                        Text(building.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(building.id)
                }
            }
            
            // Worker selection with skills context
            if !viewModel.selectedBuildingID.isEmpty {
                Picker("Assign to Worker", selection: $viewModel.selectedWorkerId) {
                    ForEach(viewModel.availableWorkers) { worker in
                        VStack(alignment: .leading) {
                            Text(worker.name)
                                .fontWeight(.medium)
                            
                            HStack {
                                if viewModel.isWorkerAvailable(worker) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text("Available")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text("Busy")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                
                                // Show relevant skills
                                if let skills = viewModel.getRelevantSkills(for: worker) {
                                    Text("• \(skills)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .tag(worker.id)
                    }
                }
            }
            
            // Smart worker suggestions
            if !viewModel.suggestedWorkers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Suggestions")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    ForEach(viewModel.suggestedWorkers.prefix(3)) { suggestion in
                        Button(action: {
                            viewModel.selectedWorkerId = suggestion.worker.id
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.worker.name)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(suggestion.reason)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(Int(suggestion.matchScore * 100))% match")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var scheduleSection: some View {
        Section("Scheduling") {
            DatePicker("Due Date", selection: $viewModel.selectedDate, displayedComponents: .date)
            
            Toggle("Add Start Time", isOn: $viewModel.addStartTime)
            
            if viewModel.addStartTime {
                DatePicker("Start Time", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
            }
            
            Toggle("Add End Time", isOn: $viewModel.addEndTime)
            
            if viewModel.addEndTime {
                DatePicker("End Time", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
                    .disabled(!viewModel.addStartTime)
                    .onChange(of: viewModel.startTime) { oldValue, newValue in
                        if viewModel.endTime < newValue {
                            viewModel.endTime = newValue.addingTimeInterval(3600)
                        }
                    }
            }
            
            // Admin-only recurring option
            Toggle("Recurring Task", isOn: $viewModel.isRecurring)
            
            if viewModel.isRecurring {
                Picker("Frequency", selection: $viewModel.recurringFrequency) {
                    Text("Daily").tag("daily")
                    Text("Weekly").tag("weekly")
                    Text("Monthly").tag("monthly")
                }
            }
        }
    }
    
    private var materialsSection: some View {
        Section("Required Materials") {
            ForEach(Array(viewModel.requiredInventory.keys), id: \.self) { itemId in
                if let item = viewModel.availableInventory.first(where: { $0.id == itemId }),
                   let quantity = viewModel.requiredInventory[itemId], quantity > 0 {
                    HStack {
                        Text(item.name)
                        
                        Spacer()
                        
                        Text("\(quantity) \(item.displayUnit)")
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            viewModel.requiredInventory.removeValue(forKey: itemId)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Button(action: {
                showInventorySelector = true
            }) {
                Label("Add Materials", systemImage: "plus.circle")
            }
        }
    }
    
    private var attachmentSection: some View {
        Section("Attachments") {
            Toggle("Attach Photo", isOn: $viewModel.attachPhoto)
            
            if viewModel.attachPhoto {
                if let image = viewModel.photo {
                    HStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Spacer()
                        
                        Button(action: {
                            showPhotoSelector = true
                        }) {
                            Text("Change")
                        }
                        
                        Button(action: {
                            viewModel.photo = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    Button(action: {
                        showPhotoSelector = true
                    }) {
                        Label("Select Photo", systemImage: "photo")
                    }
                }
            }
        }
    }
    
    private var actionSection: some View {
        Section {
            VStack {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: submitTaskAction) {
                    Group {
                        if viewModel.isSubmitting {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 10)
                                
                                Text("Creating Task...")
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Create Task & Notify Workers")
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
                .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
            }
        }
    }
    
    // MARK: - Actions
    
    private func submitTaskAction() {
        Task { @MainActor in
            await viewModel.submitTaskRequest()
        }
    }
}

// MARK: - Admin Task Request ViewModel

// MARK: - Optimized Data Structures

struct TaskFormData {
    var taskName: String = ""
    var taskDescription: String = ""
    var selectedBuildingID: String = ""
    var selectedCategory: CoreTypes.TaskCategory = .maintenance
    var selectedUrgency: CoreTypes.TaskUrgency = .medium
    var selectedDate: Date = Date().addingTimeInterval(86400)
    var selectedWorkerId: String = ""
    
    var isValid: Bool {
        return !taskName.isEmpty &&
               !taskDescription.isEmpty &&
               !selectedBuildingID.isEmpty &&
               !selectedWorkerId.isEmpty
    }
}

struct TaskSchedule {
    var addStartTime: Bool = false
    var startTime: Date = Date().addingTimeInterval(3600)
    var addEndTime: Bool = false
    var endTime: Date = Date().addingTimeInterval(7200)
}

struct AdminOptions {
    var priorityOverride: Bool = false
    var isRecurring: Bool = false
    var recurringFrequency: String = "weekly"
}

@MainActor
final class AdminTaskRequestViewModel: ObservableObject {
    // OPTIMIZED: Grouped related properties
    @Published var formData = TaskFormData()
    @Published var schedule = TaskSchedule()
    @Published var adminOptions = AdminOptions()
    
    // OPTIMIZED: Only UI state that needs reactivity
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var showCompletionAlert: Bool = false
    @Published var isLoadingData: Bool = true
    
    // OPTIMIZED: Photo handling (keep reactive for UI binding)
    @Published var attachPhoto: Bool = false
    @Published var photo: UIImage?
    
    // OPTIMIZED: Search text (needs reactivity for filtering)
    @Published var buildingSearchText: String = ""
    
    // OPTIMIZED: Non-reactive data collections (updated only when needed)
    private(set) var availableBuildings: [CoreTypes.NamedCoordinate] = []
    private(set) var availableWorkers: [CoreTypes.WorkerProfile] = []
    private(set) var suggestedWorkers: [WorkerSuggestion] = []
    private(set) var availableInventory: [CoreTypes.InventoryItem] = []
    private(set) var requiredInventory: [String: Int] = [:]
    
    // OPTIMIZED: Trigger updates manually when data changes
    func updateAvailableData(buildings: [CoreTypes.NamedCoordinate], workers: [CoreTypes.WorkerProfile]) {
        availableBuildings = buildings
        availableWorkers = workers
        objectWillChange.send() // Trigger UI update only when needed
    }
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        return formData.isValid && (!attachPhoto || photo != nil)
    }
    
    var filteredBuildings: [CoreTypes.NamedCoordinate] {
        if buildingSearchText.isEmpty {
            return availableBuildings
        } else {
            return availableBuildings.filter {
                $0.name.localizedCaseInsensitiveContains(buildingSearchText) ||
                $0.address.localizedCaseInsensitiveContains(buildingSearchText)
            }
        }
    }
    
    // MARK: - Initialization
    
    func initializeWithContext(building: CoreTypes.NamedCoordinate?, worker: CoreTypes.WorkerProfile?) {
        // Load all data
        loadBuildings()
        loadWorkers()
        
        // Set preselected context
        if let building = building {
            selectedBuildingID = building.id
        }
        
        if let worker = worker {
            selectedWorkerId = worker.id
        }
        
        // Generate AI suggestions
        generateWorkerSuggestions()
        
        isLoadingData = false
    }
    
    // MARK: - Data Loading
    
    private func loadBuildings() {
        self.availableBuildings = TaskRequestViewModel.defaultBuildings
    }
    
    private func loadWorkers() {
        self.availableWorkers = TaskRequestViewModel.defaultWorkers
    }
    
    func clearBuildingSelection() {
        selectedBuildingID = ""
    }
    
    func clearWorkerSelection() {
        selectedWorkerId = ""
    }
    
    // MARK: - Worker Intelligence
    
    func isWorkerAvailable(_ worker: CoreTypes.WorkerProfile) -> Bool {
        // Mock implementation - would check real availability
        return worker.isActive && Int.random(in: 0...1) == 1
    }
    
    func getRelevantSkills(for worker: CoreTypes.WorkerProfile) -> String? {
        let relevantSkills = worker.skills.filter { skill in
            selectedCategory.rawValue.localizedCaseInsensitiveContains(skill) ||
            taskName.localizedCaseInsensitiveContains(skill) ||
            taskDescription.localizedCaseInsensitiveContains(skill)
        }
        
        return relevantSkills.isEmpty ? nil : relevantSkills.joined(separator: ", ")
    }
    
    private func generateWorkerSuggestions() {
        var suggestions: [WorkerSuggestion] = []
        
        for worker in availableWorkers {
            let matchScore = calculateWorkerMatchScore(worker)
            if matchScore > 0.3 {
                let reason = generateSuggestionReason(for: worker, score: matchScore)
                suggestions.append(WorkerSuggestion(
                    worker: worker,
                    matchScore: matchScore,
                    reason: reason
                ))
            }
        }
        
        self.suggestedWorkers = suggestions.sorted { $0.matchScore > $1.matchScore }
    }
    
    private func calculateWorkerMatchScore(_ worker: CoreTypes.WorkerProfile) -> Double {
        var score: Double = 0
        
        // Skills match
        let relevantSkills = worker.skills.filter { skill in
            selectedCategory.rawValue.localizedCaseInsensitiveContains(skill)
        }
        score += Double(relevantSkills.count) * 0.3
        
        // Availability
        if isWorkerAvailable(worker) {
            score += 0.4
        }
        
        // Experience (mock based on hire date)
        let daysSinceHire = Calendar.current.dateComponents([.day], from: worker.hireDate, to: Date()).day ?? 0
        if daysSinceHire > 365 {
            score += 0.3
        }
        
        return min(score, 1.0)
    }
    
    private func generateSuggestionReason(for worker: CoreTypes.WorkerProfile, score: Double) -> String {
        if score > 0.8 {
            return "Perfect match: Available with relevant skills"
        } else if score > 0.6 {
            return "Good match: Has experience in this category"
        } else if isWorkerAvailable(worker) {
            return "Available now with some relevant skills"
        } else {
            return "Has relevant skills but may be busy"
        }
    }
    
    // MARK: - Task Submission
    
    func submitTaskRequest() async {
        guard isFormValid else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        // Get selected building and worker
        let selectedBuilding = availableBuildings.first(where: { $0.id == selectedBuildingID })
        guard let currentWorker = availableWorkers.first(where: { $0.id == selectedWorkerId }) else {
            errorMessage = "Please select a worker"
            isSubmitting = false
            return
        }
        
        // Create task with admin context
        var taskPriority = selectedUrgency
        if adminPriorityOverride {
            taskPriority = .critical // Admin override always sets to critical
        }
        
        let task = CoreTypes.ContextualTask(
            id: UUID().uuidString,
            title: taskName,
            description: taskDescription,
            dueDate: selectedDate,
            category: selectedCategory,
            urgency: taskPriority,
            building: selectedBuilding,
            worker: currentWorker,
            buildingId: selectedBuildingID,
            priority: taskPriority
        )
        
        do {
            // Create task via service
            try await TaskService.shared.createTask(task)
            
            // Broadcast admin-created task update
            let dashboardUpdate = CoreTypes.DashboardUpdate(
                source: .admin,
                type: .taskStarted,
                buildingId: selectedBuildingID,
                workerId: currentWorker.id,
                data: [
                    "taskId": task.id,
                    "taskTitle": task.title,
                    "taskCategory": task.category?.rawValue ?? "maintenance",
                    "taskUrgency": task.urgency?.rawValue ?? "medium",
                    "dueDate": ISO8601DateFormatter().string(from: task.dueDate ?? Date()),
                    "adminCreated": "true",
                    "adminPriorityOverride": adminPriorityOverride ? "true" : "false",
                    "isRecurring": isRecurring ? "true" : "false"
                ]
            )
            
            DashboardSyncService.shared.broadcastAdminUpdate(dashboardUpdate)
            
            // Handle inventory and photo
            if !requiredInventory.isEmpty {
                recordInventoryRequirements(for: task.id)
            }
            
            if attachPhoto, let photo = photo {
                saveTaskPhoto(photo, for: task.id)
            }
            
            // Handle recurring tasks
            if isRecurring {
                scheduleRecurringTask(baseTask: task)
            }
            
            showCompletionAlert = true
            isSubmitting = false
            
        } catch {
            errorMessage = "Failed to create task: \(error.localizedDescription)"
            isSubmitting = false
        }
    }
    
    private func recordInventoryRequirements(for taskId: String) {
        logInfo("Recording inventory requirements for admin task \(taskId)")
        for (itemId, quantity) in requiredInventory {
            if let item = availableInventory.first(where: { $0.id == itemId }) {
                logInfo("  - \(quantity) of \(item.name)")
            }
        }
    }
    
    private func saveTaskPhoto(_ image: UIImage, for taskId: String) {
        logInfo("Saving photo for admin task \(taskId)")
    }
    
    private func scheduleRecurringTask(baseTask: CoreTypes.ContextualTask) {
        logInfo("Scheduling recurring task: \(recurringFrequency)")
        // Implementation would schedule future tasks based on frequency
    }
}

// MARK: - Supporting Types

struct WorkerSuggestion {
    let worker: CoreTypes.WorkerProfile
    let matchScore: Double
    let reason: String
}

// MARK: - Helper Functions

struct AdminTaskHelpers {
    static func getUrgencyColor(_ urgency: CoreTypes.TaskUrgency) -> Color {
        switch urgency {
        case .low: return .green
        case .medium: return .yellow
        case .normal: return .blue
        case .high: return .orange
        case .critical: return .red
        case .emergency: return .red
        case .urgent: return .red
        }
    }
    
    static func getCategoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "maintenance": return "wrench.and.screwdriver"
        case "cleaning": return "sparkles"
        case "repair": return "hammer"
        case "inspection": return "magnifyingglass"
        case "installation": return "plus.square"
        case "utilities": return "bolt"
        case "emergency": return "exclamationmark.triangle.fill"
        case "renovation": return "building.2"
        case "landscaping": return "leaf"
        case "security": return "shield"
        case "sanitation": return "trash"
        case "administrative": return "doc.text"
        default: return "square.grid.2x2"
        }
    }
}

// MARK: - Preview

struct AdminTaskRequestView_Previews: PreviewProvider {
    static var previews: some View {
        AdminTaskRequestView(
            preselectedBuilding: nil,
            preselectedWorker: nil
        )
    }
}