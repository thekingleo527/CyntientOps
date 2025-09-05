//
//  TaskRequestView.swift
//  CyntientOps
//
//  ✅ FIXED: Removed all duplicate type definitions
//  ✅ FIXED: Now properly imports from CoreTypes
//  ✅ FIXED: No type ambiguity or redeclaration errors
//  ✅ FIXED: Added CoreTypes prefix to DashboardUpdate
//

import SwiftUI
import UIKit
import Combine

// MARK: - View Model

// MARK: - Optimized Task Request Data Structures

struct WorkerTaskFormData {
    var taskName: String = ""
    var taskDescription: String = ""
    var selectedBuildingID: String = ""
    var selectedCategory: CoreTypes.TaskCategory = .maintenance
    var selectedUrgency: CoreTypes.TaskUrgency = .medium
    var selectedDate: Date = Date().addingTimeInterval(86400)
    var selectedWorkerId: String = "4"
    
    var isValid: Bool {
        return !taskName.isEmpty &&
               !taskDescription.isEmpty &&
               !selectedBuildingID.isEmpty
    }
}

struct TaskScheduleData {
    var addStartTime: Bool = false
    var startTime: Date = Date().addingTimeInterval(3600)
    var addEndTime: Bool = false
    var endTime: Date = Date().addingTimeInterval(7200)
}

@MainActor
final class TaskRequestViewModel: ObservableObject {
    // OPTIMIZED: Grouped form data
    @Published var formData = WorkerTaskFormData()
    @Published var schedule = TaskScheduleData()
    
    // OPTIMIZED: Only UI state that needs reactivity
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var showCompletionAlert: Bool = false
    @Published var isLoadingBuildings: Bool = true
    @Published var showSuggestions: Bool = false
    
    // OPTIMIZED: Photo handling (keep reactive for UI binding)
    @Published var attachPhoto: Bool = false
    @Published var photo: UIImage?
    
    // OPTIMIZED: Non-reactive data collections (updated only when needed)
    private(set) var buildingOptions: [CoreTypes.NamedCoordinate] = []
    private(set) var workerOptions: [CoreTypes.WorkerProfile] = []
    private(set) var suggestions: [TaskSuggestion] = []
    private(set) var availableInventory: [CoreTypes.InventoryItem] = []
    @Published var requiredInventory: [String: Int] = [:]
    
    // OPTIMIZED: Trigger updates manually when data changes
    func updateOptions(buildings: [CoreTypes.NamedCoordinate], workers: [CoreTypes.WorkerProfile]) {
        buildingOptions = buildings
        workerOptions = workers
        objectWillChange.send()
    }
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        return formData.isValid && (!attachPhoto || photo != nil)
    }
    
    // MARK: - Initialization
    
    // Removed non-container initializer to avoid sample data paths

    func initializeData(container: ServiceContainer) {
        Task {
            await loadBuildings(container: container)
            await loadWorkers(container: container)
            loadSuggestions()
        }
    }
    
    // MARK: - Data Loading Methods
    
    // Removed sample building loader; always use container-backed loader

    private func loadBuildings(container: ServiceContainer) async {
        do {
            let buildings = try await container.buildings.getAllBuildings()
            await MainActor.run {
                self.buildingOptions = buildings
                self.isLoadingBuildings = false
            }
        } catch {
            await MainActor.run {
                self.buildingOptions = []
                self.isLoadingBuildings = false
            }
        }
    }
    
    // Removed sample worker loader; always use container-backed loader

    private func loadWorkers(container: ServiceContainer) async {
        do {
            let workers = try await container.workers.getAllActiveWorkers()
            await MainActor.run {
                self.workerOptions = workers
                if self.formData.selectedWorkerId.isEmpty, let first = workers.first {
                    self.formData.selectedWorkerId = first.id
                }
            }
        } catch {
            await MainActor.run {
                self.workerOptions = []
            }
        }
    }
    
    private func loadSuggestions() {
        self.suggestions = Self.defaultSuggestions
        self.showSuggestions = !suggestions.isEmpty
    }
    
    func loadInventory() {
        guard !formData.selectedBuildingID.isEmpty else { return }
        self.availableInventory = Self.createSampleInventory()
    }
    
    // MARK: - Actions
    
    func applySuggestion(_ suggestion: TaskSuggestion) {
        formData.taskName = suggestion.title
        formData.taskDescription = suggestion.description
        formData.selectedBuildingID = suggestion.buildingId
        
        if let category = CoreTypes.TaskCategory(rawValue: suggestion.category) {
            formData.selectedCategory = category
        }
        
        if let urgency = CoreTypes.TaskUrgency(rawValue: suggestion.urgency) {
            formData.selectedUrgency = urgency
        }
    }
    
    @MainActor
    func submitTaskRequest() async {
        guard isFormValid else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        // Get building and worker
        let selectedBuilding = buildingOptions.first(where: { $0.id == formData.selectedBuildingID })
        guard let currentWorker = workerOptions.first(where: { $0.id == formData.selectedWorkerId }) else {
            errorMessage = "Please select a worker"
            isSubmitting = false
            return
        }
        
        // Create task
        let task = CoreTypes.ContextualTask(
            id: UUID().uuidString,
            title: formData.taskName,
            description: formData.taskDescription,
            dueDate: formData.selectedDate,
            category: formData.selectedCategory,
            urgency: formData.selectedUrgency,
            building: selectedBuilding,
            worker: currentWorker,
            buildingId: formData.selectedBuildingID,
            priority: formData.selectedUrgency
        )
        
        do {
            // Create task via database since TaskService isn't available
            try await GRDBManager.shared.execute("""
                INSERT INTO tasks (id, title, description, status, category, urgency, assignee_id, building_id, scheduled_date, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                task.id,
                task.title,
                task.description ?? "",
                task.status.rawValue,
                task.category?.rawValue ?? "maintenance",
                task.urgency?.rawValue ?? "medium",
                currentWorker.id,
                formData.selectedBuildingID,
                ISO8601DateFormatter().string(from: formData.selectedDate),
                ISO8601DateFormatter().string(from: Date())
            ])
            
            // ✅ FIXED: Added CoreTypes prefix to DashboardUpdate
            // Broadcast update
            let dashboardUpdate = CoreTypes.DashboardUpdate(
                source: .admin,
                type: .taskStarted,
                buildingId: formData.selectedBuildingID,
                workerId: currentWorker.id,
                data: [
                    "taskId": task.id,
                    "taskTitle": task.title,
                    "taskCategory": task.category?.rawValue ?? "maintenance",
                    "taskUrgency": task.urgency?.rawValue ?? "medium",
                    "dueDate": ISO8601DateFormatter().string(from: task.dueDate ?? Date())
                ]
            )
            
            // DashboardSync would broadcast the update if available
            print("Task created: \(task.title) for building \(formData.selectedBuildingID)")
            
            // Handle inventory and photo
            if !requiredInventory.isEmpty {
                recordInventoryRequirements(for: task.id)
            }
            
            if attachPhoto, let photo = photo {
                saveTaskPhoto(photo, for: task.id)
            }
            
            showCompletionAlert = true
            isSubmitting = false
            
        } catch {
            errorMessage = "Failed to create task: \(error.localizedDescription)"
            isSubmitting = false
        }
    }
    
    private func recordInventoryRequirements(for taskId: String) {
        print("Recording inventory requirements for task \(taskId)")
        for (itemId, quantity) in requiredInventory {
            if let item = availableInventory.first(where: { $0.id == itemId }) {
                print("  - \(quantity) of \(item.name)")
            }
        }
    }
    
    private func saveTaskPhoto(_ image: UIImage, for taskId: String) {
        print("Saving photo for task \(taskId)")
    }
    
    // MARK: - Static Data
    
    // Removed defaultWorkers/defaultBuildings — always load from services
    
    static let defaultSuggestions: [TaskSuggestion] = [
        TaskSuggestion(
            id: "1",
            title: "Trash Area + Sidewalk & Curb Clean",
            description: "Daily cleaning of trash area, sidewalk, and curb for building compliance.",
            category: CoreTypes.TaskCategory.sanitation.rawValue,
            urgency: CoreTypes.TaskUrgency.medium.rawValue,
            buildingId: "14"
        ),
        TaskSuggestion(
            id: "2",
            title: "Museum Entrance Sweep",
            description: "Daily sweep of museum entrance area for visitor experience.",
            category: CoreTypes.TaskCategory.cleaning.rawValue,
            urgency: CoreTypes.TaskUrgency.medium.rawValue,
            buildingId: "14"
        ),
        TaskSuggestion(
            id: "3",
            title: "DSNY Put-Out (after 20:00)",
            description: "Place trash at curb after 8 PM for DSNY collection (Sun/Tue/Thu).",
            category: CoreTypes.TaskCategory.sanitation.rawValue,
            urgency: CoreTypes.TaskUrgency.high.rawValue,
            buildingId: "14"
        ),
        TaskSuggestion(
            id: "4",
            title: "Weekly Deep Clean - Trash Area",
            description: "Comprehensive cleaning and hosing of trash area (Mon/Wed/Fri).",
            category: CoreTypes.TaskCategory.sanitation.rawValue,
            urgency: CoreTypes.TaskUrgency.medium.rawValue,
            buildingId: "14"
        ),
        TaskSuggestion(
            id: "5",
            title: "Stairwell Hose-Down",
            description: "Weekly hosing of stairwells and common areas.",
            category: CoreTypes.TaskCategory.maintenance.rawValue,
            urgency: CoreTypes.TaskUrgency.low.rawValue,
            buildingId: "13"
        )
    ]
    
    static func createSampleInventory() -> [CoreTypes.InventoryItem] {
        return [
            CoreTypes.InventoryItem(
                id: UUID().uuidString,
                name: "All-Purpose Cleaner",
                category: CoreTypes.InventoryCategory.supplies,
                currentStock: 10,
                minimumStock: 5,
                maxStock: 50,
                unit: "bottles",
                cost: 5.99,
                supplier: nil,
                location: "Storage Room A",
                lastRestocked: nil,
                status: CoreTypes.RestockStatus.inStock
            ),
            CoreTypes.InventoryItem(
                id: UUID().uuidString,
                name: "Paint Brushes",
                category: .tools,
                currentStock: 5,
                minimumStock: 2,
                maxStock: 20,
                unit: "pieces",
                cost: 3.50,
                supplier: nil,
                location: "Maintenance Workshop",
                lastRestocked: nil,
                status: .inStock
            ),
            CoreTypes.InventoryItem(
                id: UUID().uuidString,
                name: "Safety Gloves",
                category: .safety,
                currentStock: 20,
                minimumStock: 10,
                maxStock: 100,
                unit: "pairs",
                cost: 2.25,
                supplier: nil,
                location: "Safety Cabinet",
                lastRestocked: nil,
                status: .inStock
            ),
            CoreTypes.InventoryItem(
                id: UUID().uuidString,
                name: "LED Light Bulbs",
                category: .materials,
                currentStock: 15,
                minimumStock: 8,
                maxStock: 50,
                unit: "pieces",
                cost: 4.75,
                supplier: nil,
                location: "Electrical Storage",
                lastRestocked: nil,
                status: .inStock
            )
        ]
    }
}

// MARK: - Supporting Models

struct TaskSuggestion: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let category: String
    let urgency: String
    let buildingId: String
    
    static func == (lhs: TaskSuggestion, rhs: TaskSuggestion) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Main View

struct TaskRequestView: View {
    let container: ServiceContainer
    @StateObject private var viewModel = TaskRequestViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showPhotoSelector = false
    @State private var showInventorySelector = false
    
    var body: some View {
        NavigationView {
            Form {
                if viewModel.isLoadingBuildings {
                    loadingSection
                } else {
                    taskDetailsSection
                    locationSection
                    scheduleSection
                    
                    if !viewModel.requiredInventory.isEmpty {
                        materialsSection
                    }
                    
                    attachmentSection
                    actionSection
                    
                    if !viewModel.suggestions.isEmpty {
                        suggestionSection
                    }
                }
            }
            .navigationTitle("New Task Request")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: submitButton
            )
            .onAppear { viewModel.initializeData(container: container) }
            .alert(isPresented: $viewModel.showCompletionAlert) {
                Alert(
                    title: Text("Task Request Submitted"),
                    message: Text("Your request has been submitted successfully."),
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
                    buildingId: viewModel.formData.selectedBuildingID,
                    selectedItems: $viewModel.requiredInventory,
                    onDismiss: {
                        showInventorySelector = false
                    }
                )
            }
        }
    }
    
    // MARK: - View Components
    
    private var submitButton: some View {
        Button(action: {
            submitTaskAction()
        }, label: {
            Text("Submit")
        })
        .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
    }
    
    private var loadingSection: some View {
        Section {
            HStack {
                ProgressView()
                    .padding(.trailing, 10)
                Text("Loading buildings...")
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
    }
    
    private var taskDetailsSection: some View {
        Section("Task Details") {
            TextField("Task Name", text: $viewModel.formData.taskName)
                .autocapitalization(.words)
            
            ZStack(alignment: .topLeading) {
                if viewModel.formData.taskDescription.isEmpty {
                    Text("Describe what needs to be done...")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                
                TextEditor(text: $viewModel.formData.taskDescription)
                    .frame(minHeight: 100)
                    .autocapitalization(.sentences)
            }
            
            Picker("Urgency", selection: $viewModel.formData.selectedUrgency) {
                ForEach(CoreTypes.TaskUrgency.allCases, id: \.self) { urgency in
                    HStack {
                        Circle()
                            .fill(TaskRequestHelpers.getUrgencyColor(urgency))
                            .frame(width: 10, height: 10)
                        
                        Text(urgency.rawValue.capitalized)
                    }
                    .tag(urgency)
                }
            }
        }
    }
    
    private var locationSection: some View {
        Section("Assignment Details") {
            Picker("Building", selection: $viewModel.formData.selectedBuildingID) {
                Text("Select a building").tag("")
                
                ForEach(viewModel.buildingOptions) { building in
                    Text(building.name).tag(building.id)
                }
            }
            
            Picker("Assign to Worker", selection: $viewModel.formData.selectedWorkerId) {
                ForEach(viewModel.workerOptions) { worker in
                    Text(worker.name).tag(worker.id)
                }
            }
            
            if !viewModel.formData.selectedBuildingID.isEmpty {
                Picker("Category", selection: $viewModel.formData.selectedCategory) {
                    ForEach(CoreTypes.TaskCategory.allCases, id: \.self) { category in
                        Label(
                            category.rawValue.capitalized,
                            systemImage: TaskRequestHelpers.getCategoryIcon(category.rawValue)
                        )
                        .tag(category)
                    }
                }
                
                Button(action: {
                    viewModel.loadInventory()
                    showInventorySelector = true
                }) {
                    HStack {
                        Label("Required Materials", systemImage: "archivebox")
                        
                        Spacer()
                        
                        if viewModel.requiredInventory.isEmpty {
                            Text("None")
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(viewModel.requiredInventory.count) items")
                                .foregroundColor(.blue)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private var scheduleSection: some View {
        Section("Timing") {
            DatePicker("Due Date", selection: $viewModel.formData.selectedDate, displayedComponents: .date)
            
            Toggle("Add Start Time", isOn: $viewModel.schedule.addStartTime)
            
            if viewModel.schedule.addStartTime {
                DatePicker("Start Time", selection: $viewModel.schedule.startTime, displayedComponents: .hourAndMinute)
            }
            
            Toggle("Add End Time", isOn: $viewModel.schedule.addEndTime)
            
            if viewModel.schedule.addEndTime {
                DatePicker("End Time", selection: $viewModel.schedule.endTime, displayedComponents: .hourAndMinute)
                    .disabled(!viewModel.schedule.addStartTime)
                    .onChange(of: viewModel.schedule.startTime) { oldValue, newValue in
                        if viewModel.schedule.endTime < newValue {
                            viewModel.schedule.endTime = newValue.addingTimeInterval(3600)
                        }
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
                Label("Edit Materials", systemImage: "pencil")
            }
        }
    }
    
    private var attachmentSection: some View {
        Section("Attachment") {
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
                
                Button(action: {
                    submitTaskAction()
                }, label: {
                    Group {
                        if viewModel.isSubmitting {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 10)
                                
                                Text("Submitting...")
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Submit Task Request")
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                })
                .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
            }
        }
    }
    
    private var suggestionSection: some View {
        Section("Suggestions") {
            DisclosureGroup(
                isExpanded: $viewModel.showSuggestions,
                content: {
                    ForEach(viewModel.suggestions) { suggestion in
                        Button(action: {
                            viewModel.applySuggestion(suggestion)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.title)
                                    .font(.headline)
                                
                                Text(suggestion.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: TaskRequestHelpers.getCategoryIcon(suggestion.category))
                                        .foregroundColor(.blue)
                                    
                                    Text(suggestion.category.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    if let iconName = TaskRequestHelpers.getUrgencyIcon(suggestion.urgency) {
                                        Image(systemName: iconName)
                                            .foregroundColor(TaskRequestHelpers.getUrgencyColorFromString(suggestion.urgency))
                                            .padding(.leading, 8)
                                    }
                                }
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if suggestion != viewModel.suggestions.last {
                            Divider()
                        }
                    }
                },
                label: {
                    Label(
                        "Task Suggestions (\(viewModel.suggestions.count))",
                        systemImage: "lightbulb.fill"
                    )
                    .font(.headline)
                    .foregroundColor(.orange)
                }
            )
        }
    }

    // MARK: - Helper to wrap async submitTaskRequest
    private func submitTaskAction() {
        Task { @MainActor in
            await viewModel.submitTaskRequest()
        }
    }
}

// MARK: - Helper Functions

struct TaskRequestHelpers {
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
    
    static func getUrgencyIcon(_ urgency: String) -> String? {
        switch urgency.lowercased() {
        case "low": return "checkmark.circle"
        case "medium": return "exclamationmark.circle"
        case "high": return "exclamationmark.triangle"
        case "urgent": return "flame.fill"
        default: return nil
        }
    }
    
    static func getUrgencyColorFromString(_ urgency: String) -> Color {
        if let taskUrgency = CoreTypes.TaskUrgency(rawValue: urgency) {
            return getUrgencyColor(taskUrgency)
        }
        return .gray
    }
}

// MARK: - Supporting Views

struct InventorySelectionView: View {
    let buildingId: String
    @Binding var selectedItems: [String: Int]
    var onDismiss: (() -> Void)? = nil
    
    @State private var inventoryItems: [CoreTypes.InventoryItem] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var tempQuantities: [String: Int] = [:]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                searchBar
                
                if isLoading {
                    ProgressView()
                        .padding()
                } else if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            inventoryItemRow(item)
                        }
                    }
                }
            }
            .navigationTitle("Select Materials")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    for (itemId, quantity) in tempQuantities {
                        if quantity > 0 {
                            selectedItems[itemId] = quantity
                        } else {
                            selectedItems.removeValue(forKey: itemId)
                        }
                    }
                    
                    presentationMode.wrappedValue.dismiss()
                    onDismiss?()
                }
            )
            .onAppear {
                tempQuantities = selectedItems
                loadInventory()
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search inventory", text: $searchText)
                .autocapitalization(.none)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "archivebox")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No inventory items found")
                .font(.headline)
            
            if !searchText.isEmpty {
                Text("No items match your search")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Try adding some inventory items to this building")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private func inventoryItemRow(_ item: CoreTypes.InventoryItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                Text("Available: \(item.currentStock)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Button(action: {
                    decrementQuantity(for: item.id)
                }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.blue)
                }
                
                Text("\(getQuantity(for: item.id))")
                    .frame(width: 30, alignment: .center)
                
                Button(action: {
                    incrementQuantity(for: item.id)
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                }
                .disabled(getQuantity(for: item.id) >= item.currentStock)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var filteredItems: [CoreTypes.InventoryItem] {
        if searchText.isEmpty {
            return inventoryItems
        } else {
            return inventoryItems.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func getQuantity(for itemId: String) -> Int {
        return tempQuantities[itemId] ?? 0
    }
    
    private func incrementQuantity(for itemId: String) {
        let currentQuantity = getQuantity(for: itemId)
        tempQuantities[itemId] = currentQuantity + 1
    }
    
    private func decrementQuantity(for itemId: String) {
        let currentQuantity = getQuantity(for: itemId)
        if currentQuantity > 0 {
            tempQuantities[itemId] = currentQuantity - 1
        }
    }
    
    private func loadInventory() {
        isLoading = true
        self.inventoryItems = TaskRequestViewModel.createSampleInventory()
        self.isLoading = false
    }
}

// MARK: - Photo Picker

struct PhotoPickerView: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                imagePreview
                actionButtons
                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("Select Photo")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showImagePicker) {
                ImagePickerWrapper(sourceType: sourceType, selectedImage: $selectedImage)
            }
        }
    }
    
    private var imagePreview: some View {
        Group {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 100))
                    .foregroundColor(.gray)
                    .frame(maxHeight: 300)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 20) {
            Button(action: {
                sourceType = .camera
                showImagePicker = true
            }) {
                Label("Take Photo", systemImage: "camera")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Button(action: {
                sourceType = .photoLibrary
                showImagePicker = true
            }) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - UIKit Integration

struct ImagePickerWrapper: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerWrapper
        
        init(_ parent: ImagePickerWrapper) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Extensions

extension CoreTypes.InventoryItem {
    var displayUnit: String {
        switch category {
        case .tools: return "pcs"
        case .supplies: return "bottles"
        case .equipment: return "units"
        case .materials: return "pcs"
        case .safety: return "pairs"
        case .cleaning: return "items"
        case .electrical: return "pcs"
        case .plumbing: return "pcs"
        case .general: return "items"
        case .office: return "items"
        case .maintenance: return "items"
        case .building: return "items"
        case .sanitation: return "items"  
        case .seasonal: return "items"
        case .other: return "items"
        }
    }
}

 
