import SwiftUI

struct ClientBulkAssignmentSheet: View {
    let workers: [CoreTypes.WorkerSummary]
    let buildings: [CoreTypes.NamedCoordinate]
    let capabilities: [CoreTypes.WorkerCapability]
    let container: ServiceContainer
    
    @State private var selectedWorkers: Set<String> = []
    @State private var selectedTask: CoreTypes.BulkTaskType = .inspection
    @State private var assignments: [CoreTypes.BulkAssignment] = []
    @State private var isGeneratingAssignments = false
    @State private var requirementFilter: CoreTypes.CapabilityRequirement = .any
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Bulk Assignment Controls
                assignmentControlsSection
                
                // Worker Selection Grid
                workerSelectionSection
                
                // Task Type and Requirements
                taskRequirementsSection
                
                // Generated Assignments
                if !assignments.isEmpty {
                    generatedAssignmentsSection
                }
                
                // Capability Match Analysis
                capabilityAnalysisSection
                
                // Assignment Actions
                assignmentActionsSection
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .onChange(of: selectedWorkers) { _ in
            Task { await generateBulkAssignments() }
        }
        .onChange(of: selectedTask) { _ in
            Task { await generateBulkAssignments() }
        }
    }
    
    private var assignmentControlsSection: some View {
        VStack(spacing: 16) {
            Text("Intelligent Bulk Assignment")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Task Type Picker
            Picker("Task Type", selection: $selectedTask) {
                ForEach(CoreTypes.BulkTaskType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            // Requirement Filter
            Picker("Requirements", selection: $requirementFilter) {
                ForEach(CoreTypes.CapabilityRequirement.allCases, id: \.self) { req in
                    Text(req.rawValue).tag(req)
                }
            }
            .pickerStyle(.menu)
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var workerSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Workers")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(selectedWorkers.count == workers.count ? "Deselect All" : "Select All") {
                    if selectedWorkers.count == workers.count {
                        selectedWorkers.removeAll()
                    } else {
                        selectedWorkers = Set(workers.map { $0.id })
                    }
                }
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(workers, id: \.id) { worker in
                    Button(action: {
                        if selectedWorkers.contains(worker.id) {
                            selectedWorkers.remove(worker.id)
                        } else {
                            selectedWorkers.insert(worker.id)
                        }
                    }) {
                        WorkerSelectionCard(
                            worker: worker,
                            isSelected: selectedWorkers.contains(worker.id),
                            matchesRequirements: workerMatchesRequirements(worker)
                        )
                    }
                }
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var taskRequirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Requirements")
                .font(.headline)
                .foregroundColor(.white)
            
            // Show required capabilities for selected task type
            let requiredCapabilities = getRequiredCapabilities(for: selectedTask)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(requiredCapabilities, id: \.self) { capability in
                    Text(capability)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CyntientOpsDesign.DashboardColors.info.opacity(0.2))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var generatedAssignmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Generated Assignments")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isGeneratingAssignments {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            ForEach(assignments, id: \.id) { assignment in
                BulkAssignmentCard(assignment: assignment)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var capabilityAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Capability Analysis")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(capabilities, id: \.name) { capability in
                CapabilityMatchRow(
                    capability: capability,
                    selectedWorkers: selectedWorkers,
                    allWorkers: workers
                )
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var assignmentActionsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("Preview Assignments") {
                    Task { await generateBulkAssignments() }
                }
                .buttonStyle(.bordered)
                .disabled(selectedWorkers.isEmpty)
                
                Button("Apply Assignments") {
                    Task { await applyBulkAssignments() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(assignments.isEmpty)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func workerMatchesRequirements(_ worker: CoreTypes.WorkerSummary) -> Bool {
        let requiredCaps = getRequiredCapabilities(for: selectedTask)
        let workerCaps = Set(worker.capabilities)
        
        switch requirementFilter {
        case .any:
            return !workerCaps.intersection(Set(requiredCaps)).isEmpty
        case .all:
            return Set(requiredCaps).isSubset(of: workerCaps)
        case .none:
            return true
        }
    }
    
    private func getRequiredCapabilities(for taskType: CoreTypes.BulkTaskType) -> [String] {
        switch taskType {
        case .inspection:
            return ["Safety Inspection", "Documentation", "Building Systems"]
        case .maintenance:
            return ["General Maintenance", "Plumbing", "Electrical", "HVAC"]
        case .cleaning:
            return ["Cleaning", "Waste Management", "Floor Care"]
        case .security:
            return ["Security", "Access Control", "Emergency Response"]
        case .compliance:
            return ["Compliance Inspection", "Documentation", "Regulatory Knowledge"]
        }
    }
    
    private func generateBulkAssignments() async {
        isGeneratingAssignments = true
        
        // Use OperationalDataManager to create intelligent assignments
        // Based on worker capabilities, building requirements, and optimization algorithms
        
        let selectedWorkerData = workers.filter { selectedWorkers.contains($0.id) }
        let requiredCaps = getRequiredCapabilities(for: selectedTask)
        
        let newAssignments = selectedWorkerData.compactMap { worker in
            // Find best building match for this worker
            let optimalBuilding = buildings.first { building in
                // Find routines for this building from container
                let buildingRoutines = container.operationalData.getRoutinesForBuilding(building.id)
                let buildingCaps = Set(buildingRoutines.flatMap { $0.requiredCapabilities })
                return !buildingCaps.intersection(Set(worker.capabilities)).isEmpty
            }
            
            guard let building = optimalBuilding else { return nil }
            
            return CoreTypes.BulkAssignment(
                id: UUID().uuidString,
                workerId: worker.id,
                workerName: worker.name,
                taskType: selectedTask,
                buildingId: building.id,
                buildingName: building.name,
                estimatedDuration: calculateTaskDuration(selectedTask),
                capabilityMatch: calculateCapabilityMatch(worker, requiredCaps),
                priority: calculateAssignmentPriority(building.id, selectedTask)
            )
        }
        
        await MainActor.run {
            self.assignments = newAssignments.sorted { $0.priority > $1.priority }
            self.isGeneratingAssignments = false
        }
    }
    
    private func calculateTaskDuration(_ taskType: CoreTypes.BulkTaskType) -> TimeInterval {
        switch taskType {
        case .inspection: return 3600 * 2 // 2 hours
        case .maintenance: return 3600 * 4 // 4 hours
        case .cleaning: return 3600 * 3 // 3 hours
        case .security: return 3600 * 8 // 8 hours
        case .compliance: return 3600 * 1.5 // 1.5 hours
        }
    }
    
    private func calculateCapabilityMatch(_ worker: CoreTypes.WorkerSummary, _ requiredCaps: [String]) -> Double {
        let workerCaps = Set(worker.capabilities)
        let required = Set(requiredCaps)
        let overlap = workerCaps.intersection(required)
        return Double(overlap.count) / Double(required.count)
    }
    
    private func calculateAssignmentPriority(_ buildingId: String, _ taskType: CoreTypes.BulkTaskType) -> Int {
        // Calculate priority based on building urgency and task type
        return Int.random(in: 1...10) // Placeholder - implement with real priority logic
    }
    
    private func applyBulkAssignments() async {
        // Apply all assignments to OperationalDataManager
        for assignment in assignments {
            // Implementation would create tasks in OperationalDataManager
        }
    }
}

// MARK: - Supporting Views

struct WorkerSelectionCard: View {
    let worker: CoreTypes.WorkerSummary
    let isSelected: Bool
    let matchesRequirements: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(worker.isActive ? .green : .red)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(getInitials(worker.name))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            Text(worker.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(2)
            
            HStack(spacing: 4) {
                Image(systemName: matchesRequirements ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(matchesRequirements ? .green : .red)
                    .font(.caption2)
                
                Text(worker.role)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(isSelected ? 
                   CyntientOpsDesign.DashboardColors.clientPrimary.opacity(0.3) :
                   CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? CyntientOpsDesign.DashboardColors.clientPrimary : Color.clear, lineWidth: 2)
        )
    }
    
    private func getInitials(_ name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

struct BulkAssignmentCard: View {
    let assignment: CoreTypes.BulkAssignment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(assignment.workerName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Priority \(assignment.priority)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(getPriorityColor(assignment.priority).opacity(0.2))
                    .foregroundColor(getPriorityColor(assignment.priority))
                    .clipShape(Capsule())
            }
            
            Text("\(assignment.taskType.displayName) at \(assignment.buildingName)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Duration: \(formatDuration(assignment.estimatedDuration))")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("Match: \(Int(assignment.capabilityMatch * 100))%")
                    .font(.caption)
                    .foregroundColor(assignment.capabilityMatch > 0.8 ? .green : .orange)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func getPriorityColor(_ priority: Int) -> Color {
        if priority >= 8 { return .red }
        else if priority >= 6 { return .orange }
        else if priority >= 4 { return .yellow }
        else { return .green }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct CapabilityMatchRow: View {
    let capability: CoreTypes.WorkerCapability
    let selectedWorkers: Set<String>
    let allWorkers: [CoreTypes.WorkerSummary]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(capability.name)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text("\(capability.workers) workers available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(selectedWorkersWithCapability) selected")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
                
                Text(capability.demandLevel.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(getDemandColor(capability.demandLevel).opacity(0.2))
                    .foregroundColor(getDemandColor(capability.demandLevel))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
    }
    
    private var selectedWorkersWithCapability: Int {
        return allWorkers.filter { worker in
            selectedWorkers.contains(worker.id) && worker.capabilities.contains(capability.name)
        }.count
    }
    
    private func getDemandColor(_ demand: CoreTypes.DemandLevel) -> Color {
        switch demand {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}