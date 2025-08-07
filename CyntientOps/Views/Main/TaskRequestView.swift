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

@MainActor
final class TaskRequestViewModel: ObservableObject {
    // Published properties
    @Published var taskName: String = ""
    @Published var taskDescription: String = ""
    @Published var selectedBuildingID: String = ""
    @Published var selectedCategory: CoreTypes.TaskCategory = .maintenance
    @Published var selectedUrgency: CoreTypes.TaskUrgency = .medium
    @Published var selectedDate: Date = Date().addingTimeInterval(86400)
    @Published var selectedWorkerId: String = "4"
    @Published var attachPhoto: Bool = false
    @Published var photo: UIImage?
    @Published var requiredInventory: [String: Int] = [:]
    @Published var availableInventory: [CoreTypes.InventoryItem] = []
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var showCompletionAlert: Bool = false
    
    // Data collections
    @Published var buildingOptions: [CoreTypes.NamedCoordinate] = []
    @Published var workerOptions: [CoreTypes.WorkerProfile] = []
    @Published var suggestions: [TaskSuggestion] = []
    @Published var isLoadingBuildings: Bool = true
    @Published var showSuggestions: Bool = false
    
    // Time options
    @Published var addStartTime: Bool = false
    @Published var startTime: Date = Date().addingTimeInterval(3600)
    @Published var addEndTime: Bool = false
    @Published var endTime: Date = Date().addingTimeInterval(7200)
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        return !taskName.isEmpty &&
               !taskDescription.isEmpty &&
               !selectedBuildingID.isEmpty &&
               !selectedWorkerId.isEmpty &&
               (!attachPhoto || photo != nil)
    }
    
    // MARK: - Initialization
    
    func initializeData() {
        // Load all data synchronously to avoid async issues
        loadBuildings()
        loadWorkers()
        loadSuggestions()
    }
    
    // MARK: - Data Loading Methods
    
    private func loadBuildings() {
        self.buildingOptions = Self.defaultBuildings
        self.isLoadingBuildings = false
    }
    
    private func loadWorkers() {
        self.workerOptions = Self.defaultWorkers
    }
    
    private func loadSuggestions() {
        self.suggestions = Self.defaultSuggestions
        self.showSuggestions = !suggestions.isEmpty
    }
    
    func loadInventory() {
        guard !selectedBuildingID.isEmpty else { return }
        self.availableInventory = Self.createSampleInventory()
    }
    
    // MARK: - Actions
    
    func applySuggestion(_ suggestion: TaskSuggestion) {
        taskName = suggestion.title
        taskDescription = suggestion.description
        selectedBuildingID = suggestion.buildingId
        
        if let category = CoreTypes.TaskCategory(rawValue: suggestion.category) {
            selectedCategory = category
        }
        
        if let urgency = CoreTypes.TaskUrgency(rawValue: suggestion.urgency) {
            selectedUrgency = urgency
        }
    }
    
    @MainActor
    func submitTaskRequest() async {
        guard isFormValid else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        // Get building and worker
        let selectedBuilding = buildingOptions.first(where: { $0.id == selectedBuildingID })
        guard let currentWorker = workerOptions.first(where: { $0.id == selectedWorkerId }) else {
            errorMessage = "Please select a worker"
            isSubmitting = false
            return
        }
        
        // Create task
        let task = CoreTypes.ContextualTask(
            id: UUID().uuidString,
            title: taskName,
            description: taskDescription,
            dueDate: selectedDate,
            category: selectedCategory,
            urgency: selectedUrgency,
            building: selectedBuilding,
            worker: currentWorker,
            buildingId: selectedBuildingID,
            priority: selectedUrgency
        )
        
        do {
            // Create task via service
            try await TaskService.shared.createTask(task)
            
            // ✅ FIXED: Added CoreTypes prefix to DashboardUpdate
            // Broadcast update
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
                    "dueDate": ISO8601DateFormatter().string(from: task.dueDate ?? Date())
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
    
    static let defaultBuildings: [CoreTypes.NamedCoordinate] = [
        CoreTypes.NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            address: "142-148 West 17th Street, New York, NY",
            latitude: 40.7402,
            longitude: -73.9980
        ),
        CoreTypes.NamedCoordinate(
            id: "1",
            name: "117 West 17th Street",
            address: "117 West 17th Street, New York, NY",
            latitude: 40.7410,
            longitude: -73.9958
        ),
        CoreTypes.NamedCoordinate(
            id: "3",
            name: "131 Perry Street",
            address: "131 Perry Street, New York, NY",
            latitude: 40.7350,
            longitude: -74.0045
        ),
        CoreTypes.NamedCoordinate(
            id: "5",
            name: "135-139 West 17th Street",
            address: "135-139 West 17th Street, New York, NY",
            latitude: 40.7404,
            longitude: -73.9975
        ),
        CoreTypes.NamedCoordinate(
            id: "6",
            name: "136 West 17th Street",
            address: "136 West 17th Street, New York, NY",
            latitude: 40.7403,
            longitude: -73.9976
        ),
        CoreTypes.NamedCoordinate(
            id: "13",
            name: "68 Perry Street",
            address: "68 Perry Street, New York, NY",
            latitude: 40.7355,
            longitude: -74.0032
        )
    ]
    
    static let defaultWorkers: [CoreTypes.WorkerProfile] = [
        CoreTypes.WorkerProfile(
            id: "4",
            name: "Kevin Dutan",
            email: "kevin.dutan@francomanagement.com",
            phoneNumber: "555-0104",
            role: CoreTypes.UserRole.worker,
            skills: ["Cleaning", "Sanitation", "Operations"],
            certifications: ["DSNY Compliance", "Safety Training"],
            hireDate: Date(timeIntervalSinceNow: -730 * 24 * 60 * 60),
            isActive: true,
            profileImageUrl: nil
        ),
        CoreTypes.WorkerProfile(
            id: "2",
            name: "Edwin Lema",
            email: "edwin.lema@francomanagement.com",
            phoneNumber: "555-0102",
            role: CoreTypes.UserRole.worker,
            skills: ["Cleaning", "Maintenance"],
            certifications: ["Safety Training"],
            hireDate: Date(timeIntervalSinceNow: -365 * 24 * 60 * 60),
            isActive: true,
            profileImageUrl: nil
        ),
        CoreTypes.WorkerProfile(
            id: "1",
            name: "Greg Hutson",
            email: "greg.hutson@francomanagement.com",
            phoneNumber: "555-0101",
            role: CoreTypes.UserRole.worker,
            skills: ["Building Systems", "Cleaning"],
            certifications: ["Building Specialist"],
            hireDate: Date(timeIntervalSinceNow: -1095 * 24 * 60 * 60),
            isActive: true,
            profileImageUrl: nil
        ),
        CoreTypes.WorkerProfile(
            id: "5",
            name: "Mercedes Inamagua",
            email: "mercedes.inamagua@francomanagement.com",
            phoneNumber: "555-0105",
            role: CoreTypes.UserRole.worker,
            skills: ["Deep Cleaning", "Maintenance"],
            certifications: ["Safety Training"],
            hireDate: Date(timeIntervalSinceNow: -547 * 24 * 60 * 60),
            isActive: true,
            profileImageUrl: nil
        ),
        CoreTypes.WorkerProfile(
            id: "7",
            name: "Angel Guirachocha",
            email: "angel.guirachocha@francomanagement.com",
            phoneNumber: "555-0107",
            role: CoreTypes.UserRole.worker,
            skills: ["Evening Operations", "Security"],
            certifications: ["Security License"],
            hireDate: Date(timeIntervalSinceNow: -180 * 24 * 60 * 60),
            isActive: true,
            profileImageUrl: nil
        )
    ]
    
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
            .onAppear(perform: viewModel.initializeData)
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
                    buildingId: viewModel.selectedBuildingID,
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
            
            Picker("Urgency", selection: $viewModel.selectedUrgency) {
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
            Picker("Building", selection: $viewModel.selectedBuildingID) {
                Text("Select a building").tag("")
                
                ForEach(viewModel.buildingOptions) { building in
                    Text(building.name).tag(building.id)
                }
            }
            
            Picker("Assign to Worker", selection: $viewModel.selectedWorkerId) {
                ForEach(viewModel.workerOptions) { worker in
                    Text(worker.name).tag(worker.id)
                }
            }
            
            if !viewModel.selectedBuildingID.isEmpty {
                Picker("Category", selection: $viewModel.selectedCategory) {
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

// MARK: - Preview

struct TaskRequestView_Previews: PreviewProvider {
    static var previews: some View {
        TaskRequestView()
    }
}
