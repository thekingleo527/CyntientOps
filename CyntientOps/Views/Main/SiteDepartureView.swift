//
//  SiteDepartureView.swift
//  CyntientOps
//
//  Site departure checklist and verification view
//

import SwiftUI

public struct SiteDepartureView: View {
    @StateObject var viewModel: SiteDepartureViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPhotoCapture = false
    @State private var showEmergencyConfirmation = false
    
    public var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.opacity(0.9).ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else if let checklist = viewModel.checklist {
                    checklistContent(checklist)
                }
            }
            .navigationTitle("Leaving \(viewModel.currentBuilding.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    emergencyDepartureButton
                }
            })
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadChecklist()
        }
        .sheet(isPresented: $showPhotoCapture) {
            FrancoImagePicker(
                image: $viewModel.capturedPhoto,
                sourceType: .camera
            )
        }
        .alert("Emergency Departure", isPresented: $showEmergencyConfirmation) {
            Button("Confirm Emergency", role: .destructive) {
                Task {
                    if await viewModel.finalizeDeparture(method: .emergency) {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will log an emergency departure without completing the checklist. Use only in genuine emergencies.")
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Preparing departure checklist...")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Unable to load checklist")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                Task {
                    await viewModel.loadChecklist()
                }
            }
            .buttonStyle(DepartureGlassButtonStyle())
        }
        .padding()
    }
    
    // MARK: - Checklist Content
    
    private func checklistContent(_ checklist: DepartureChecklist) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary card
                summaryCard(checklist)
                
                // Photo requirement (if applicable)
                if viewModel.requiresPhoto {
                    photoRequirementCard
                }
                
                // Incomplete tasks checklist
                if !checklist.incompleteTasks.isEmpty {
                    incompleteTasksSection(checklist.incompleteTasks)
                }
                
                // Next destination selector
                if !viewModel.availableBuildings.isEmpty {
                    nextDestinationSection
                }
                
                // Notes section
                notesSection
                
                // Departure button
                departureButton
            }
            .padding()
        }
    }
    
    // MARK: - Summary Card
    
    private func summaryCard(_ checklist: DepartureChecklist) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Time at Location", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(formatTime(checklist.timeSpentMinutes ?? 0))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Label("Tasks Complete", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(checklist.completedTasks.count) of \(checklist.allTasks.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(checklist.incompleteTasks.isEmpty ? .green : .orange)
                }
            }
            
            if checklist.photoCount > 0 {
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.blue)
                    Text("\(checklist.photoCount) photos captured")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Photo Requirement Card
    
    private var photoRequirementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Departure Photo Required", systemImage: "camera.fill")
                .font(.headline)
                .foregroundColor(.orange)
            
            if let photo = viewModel.capturedPhoto {
                // Show captured photo
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        HStack {
                            Spacer()
                            VStack {
                                Button(action: { viewModel.capturedPhoto = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(8)
                                Spacer()
                            }
                        }
                    )
            } else {
                Button(action: { showPhotoCapture = true }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Take Departure Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Incomplete Tasks Section
    
    private func incompleteTasksSection(_ tasks: [CoreTypes.ContextualTask]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Acknowledge Incomplete Tasks", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.yellow)
            
            Text("Please confirm the following tasks will remain incomplete:")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    ChecklistItemRow(
                        task: task,
                        isChecked: viewModel.checkmarkStates[task.id] ?? false,
                        onToggle: {
                            viewModel.checkmarkStates[task.id]?.toggle()
                        }
                    )
                }
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.yellow.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Next Destination Section
    
    private var nextDestinationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Next Destination", systemImage: "location.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.availableBuildings, id: \.id) { building in
                        NextDestinationCard(
                            building: building,
                            isSelected: viewModel.selectedNextDestination?.id == building.id,
                            onTap: {
                                viewModel.selectedNextDestination = building
                            }
                        )
                    }
                    
                    // End of day option
                    EndOfDayCard(
                        isSelected: viewModel.selectedNextDestination == nil,
                        onTap: {
                            viewModel.selectedNextDestination = nil
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Departure Notes (Optional)", systemImage: "note.text")
                .font(.headline)
                .foregroundColor(.white)
            
            TextEditor(text: $viewModel.departureNotes)
                .frame(height: 100)
                .padding(8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Departure Button
    
    private var departureButton: some View {
        Button(action: {
            Task {
                if await viewModel.finalizeDeparture() {
                    dismiss()
                }
            }
        }) {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right.square.fill")
                    Text("Confirm Departure")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canDepart ? Color.green : Color.gray)
            .cornerRadius(16)
        }
        .disabled(!viewModel.canDepart)
    }
    
    // MARK: - Emergency Button
    
    private var emergencyDepartureButton: some View {
        Button(action: { showEmergencyConfirmation = true }) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
        }
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}

// MARK: - Supporting Views

struct ChecklistItemRow: View {
    let task: CoreTypes.ContextualTask
    let isChecked: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isChecked ? .green : .white.opacity(0.4))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .strikethrough(isChecked)
                    
                    if let urgency = task.urgency,
                       urgency == .high || urgency == .critical || urgency == .emergency {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text(urgency.rawValue.capitalized)
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NextDestinationCard: View {
    let building: CoreTypes.NamedCoordinate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                
                Text(building.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 100)
            }
            .padding()
            .background(isSelected ? Color.blue : Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EndOfDayCard: View {
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                
                Text("End of Day")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                    .frame(width: 100)
            }
            .padding()
            .background(isSelected ? Color.purple : Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Glass button style for consistency
struct DepartureGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.1 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
