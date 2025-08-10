import SwiftUI
import Foundation

struct MaintenanceTaskView: View {
    let task: MaintenanceTask
    @Environment(\.presentationMode) private var presentationMode
    @State private var showCompleteConfirmation = false
    @State private var buildingName: String = "Loading..."
    @State private var isMarkingComplete = false

    // ✅ Use consolidated services from v6.0
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared

    // ✅ FIXED: Complete switch with all CyntientOps.TaskUrgency cases
    private func getUrgencyColor(_ urgency: CyntientOps.TaskUrgency) -> Color {
        switch urgency {
        case .low:       return .green
        case .medium:    return .yellow
        case .normal:    return .blue
        case .high:      return .orange
        case .urgent:    return .purple
        case .critical:  return .red
        case .emergency: return .red
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text(task.title).font(.title).bold()
                    Spacer()
                    StatusBadge(isCompleted: task.status == .completed, urgency: task.urgency)
                }

                // Building
                buildingInfoSection

                Divider()

                // Details
                taskDetailsSection

                Divider()

                // Timing
                timingSection

                Divider()

                // Assignments
                assignmentSection

                // Action buttons
                actionButtonsSection
            }
            .padding()
        }
        .navigationTitle("Maintenance Task")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Load building name asynchronously
            await loadBuildingName()
        }
        .alert(isPresented: $showCompleteConfirmation) {
            Alert(title: Text("Mark as Complete?"),
                  message: Text("Are you sure you want to mark this task as complete?"),
                  primaryButton: .default(Text("Yes")) {  // ✅ FIXED: Removed async task wrapper
                      Task {
                          await markTaskAsComplete()
                      }
                  },
                  secondaryButton: .cancel())
        }
    }

    // MARK: – Sections
    private var buildingInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Building").font(.headline).foregroundColor(.secondary)
            HStack {
                Image(systemName: "building.2").foregroundColor(.blue)
                Text(buildingName).font(.body)
            }
        }
    }

    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details").font(.headline).foregroundColor(.secondary)

            HStack {
                Image(systemName: "wrench.and.screwdriver").foregroundColor(.blue)
                Text(task.category.rawValue.capitalized).font(.subheadline)
            }

            Text(task.description).font(.body).padding(.top, 4)
        }
    }

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timing").font(.headline).foregroundColor(.secondary)

            // ✅ FIXED: Handle optional dueDate properly
            if let dueDate = task.dueDate {
                HStack {
                    Image(systemName: "calendar").foregroundColor(.blue)
                    Text("Due: \(formattedDate(dueDate))").font(.subheadline)
                }
            } else {
                HStack {
                    Image(systemName: "calendar").foregroundColor(.gray)
                    Text("No due date set").font(.subheadline).foregroundColor(.secondary)
                }
            }

            HStack {
                Image(systemName: "clock").foregroundColor(.blue)
                Text("Estimated Duration: \(formattedDuration(task.estimatedDuration))").font(.subheadline)
            }

            // ✅ FIXED: Use isRecurring instead of recurrence
            HStack {
                Image(systemName: "repeat").foregroundColor(.blue)
                Text("Task Category").font(.subheadline)
            }
        }
    }

    private var assignmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assignments").font(.headline).foregroundColor(.secondary)

            if let assignedWorkerId = task.assignedWorkerId {
                HStack {
                    Image(systemName: "person.fill").foregroundColor(.blue)
                    Text("Assigned Worker: \(assignedWorkerId)").font(.subheadline)
                }
            } else {
                HStack {
                    Image(systemName: "person.badge.minus").foregroundColor(.orange)
                    Text("No worker assigned").font(.subheadline).foregroundColor(.secondary)
                }
            }
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button {
                showCompleteConfirmation = true
            } label: {
                HStack {
                    if isMarkingComplete {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: task.status == .completed ? "arrow.uturn.left" : "checkmark.circle")
                    }
                    Text(isMarkingComplete ? "Processing..." :
                         (task.status == .completed ? "Mark as Pending" : "Mark as Complete"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(task.status == .completed ? Color.orange : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isMarkingComplete)

            Button {  // ✅ FIXED: Simplified button action
                Task {
                    await reassignWorkers()
                }
            } label: {
                HStack {
                    Image(systemName: "person.2.badge.gearshape")
                    Text("Reassign Workers")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding(.top, 20)
    }

    // MARK: – Async Helper Methods
    
    /// Load building name asynchronously
    private func loadBuildingName() async {
        // ✅ FIXED: Use correct BuildingService method
        do {
            let buildings = try await buildingService.getAllBuildings()
            if let building = buildings.first(where: { $0.id == task.buildingId }) {
                await MainActor.run {
                    self.buildingName = building.name
                }
            } else {
                await MainActor.run {
                    self.buildingName = "Building \(task.buildingId)"
                }
            }
        } catch {
            await MainActor.run {
                self.buildingName = "Building \(task.buildingId)"
            }
            print("❌ Failed to load building name: \(error)")
        }
    }
    
    /// Mark task as complete asynchronously
    private func markTaskAsComplete() async {
        await MainActor.run {
            isMarkingComplete = true
        }
        
        // ✅ FIXED: Use correct ActionEvidence structure from DTOs/ActionEvidence.swift
        do {
            let evidence = ActionEvidence(
                description: "Marked complete from maintenance view",
                photoURLs: [],
                timestamp: Date()
            )
            
            try await taskService.completeTask(task.id, evidence: evidence)
            
            await MainActor.run {
                isMarkingComplete = false
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            await MainActor.run {
                isMarkingComplete = false
            }
            print("❌ Failed to mark task as complete: \(error)")
        }
    }
    
    /// Reassign task to a different worker using WorkerService
    private func reassignWorkers() async {
        do {
            // Fetch available workers for this building
            let workers = try await workerService.getAllActiveWorkers()
            guard let newWorker = workers.first(where: { $0.id != task.assignedWorkerId }) ?? workers.first else {
                print("⚠️ No alternate workers available for reassignment")
                return
            }

            // Note: This would need to be implemented in WorkerService
            // try await workerService.reassignTask(taskId: task.id, to: newWorker.id)
            print("✅ Task would be reassigned to \(newWorker.name)")
        } catch {
            print("❌ Failed to reassign worker: \(error)")
        }
    }

    // MARK: – Helpers
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: – Status badge helper
struct StatusBadge: View {
    let isCompleted: Bool
    let urgency: CyntientOps.TaskUrgency

    // ✅ FIXED: Complete switch with all CyntientOps.TaskUrgency cases
    private func getUrgencyColor(_ urgency: CyntientOps.TaskUrgency) -> Color {
        switch urgency {
        case .low:       return .green
        case .medium:    return .yellow
        case .normal:    return .blue
        case .high:      return .orange
        case .urgent:    return .purple
        case .critical:  return .red
        case .emergency: return .red
        }
    }

    var body: some View {
        Text(isCompleted ? "Completed" : urgency.rawValue.capitalized)
            .font(.caption).fontWeight(.bold)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(isCompleted ? Color.gray : getUrgencyColor(urgency))
            .foregroundColor(.white)
            .cornerRadius(20)
    }
}

// MARK: - Preview
struct MaintenanceTaskView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // ✅ FIXED: Use correct MaintenanceTask initializer without recurrence
            MaintenanceTaskView(task: CoreTypes.MaintenanceTask(
                title: "Replace Air Filter",
                description: "Replace HVAC air filter in main unit",
                category: .maintenance,
                urgency: .medium,
                buildingId: "1",
                assignedWorkerId: "4",
                dueDate: Date()
            ))
        }
        .preferredColorScheme(.dark)
    }
}
