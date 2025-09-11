//
//  MultiSiteDepartureSheet.swift
//  CyntientOps
//
//  NEW: Consolidated building-based departure flow with inline photos
//

import SwiftUI

struct MultiSiteDepartureSheet: View {
    let workerId: String
    let buildings: [NamedCoordinate]
    let container: ServiceContainer
    let onFinished: () -> Void

    @StateObject private var viewModel: SiteDepartureViewModel
    @Environment(\.dismiss) private var dismiss

    init(workerId: String, buildings: [NamedCoordinate], container: ServiceContainer, onFinished: @escaping () -> Void) {
        self.workerId = workerId
        self.buildings = buildings
        self.container = container
        self.onFinished = onFinished
        
        // Create a unified ViewModel for all buildings
        self._viewModel = StateObject(wrappedValue: SiteDepartureViewModel(
            workerId: workerId,
            currentBuilding: buildings.first ?? NamedCoordinate(id: "", name: "Unknown", address: "", latitude: 0.0, longitude: 0.0),
            container: container
        ))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Site Departure")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Review buildings worked today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Progress indicator
                    let completedCount = viewModel.buildingEntries.filter(\.tasksComplete).count
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(completedCount)/\(viewModel.buildingEntries.count)")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Divider()

                // Building Entries List
                if viewModel.isLoading {
                    ProgressView("Loading buildings...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.buildingEntries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "building.2")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No buildings worked today")
                            .font(.headline)
                        Text("Tasks will appear here once you start working")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach($viewModel.buildingEntries) { $entry in
                                BuildingDepartureCard(
                                    entry: $entry,
                                    onPhotoAdded: { photo in
                                        entry.photos.append(photo)
                                        viewModel.recomputeSubmitState()
                                    },
                                    onPhotoRemoved: { index in
                                        if index < entry.photos.count {
                                            entry.photos.remove(at: index)
                                            viewModel.recomputeSubmitState()
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }

                // Validation summary (blocking reasons)
                if !viewModel.canSubmit {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
                            Text("Please resolve the issues below before submitting:").font(.caption).foregroundColor(.secondary)
                        }
                        ForEach(viewModel.buildingEntries.filter { !$0.tasksComplete || ($0.requiresPhoto && $0.photos.isEmpty) }) { entry in
                            HStack(spacing: 6) {
                                Image(systemName: entry.tasksComplete ? "camera" : "checklist")
                                    .foregroundColor(.secondary)
                                Text(entry.name)
                                    .font(.caption)
                                Spacer()
                                if !entry.tasksComplete { Text("Tasks pending").font(.caption2).foregroundColor(.secondary) }
                                if entry.requiresPhoto && entry.photos.isEmpty { Text("Photo required").font(.caption2).foregroundColor(.secondary) }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)
                }

                // Submit Button
                VStack {
                    Button {
                        Task {
                            do {
                                try await viewModel.submit(workerId: workerId)
                                onFinished()
                                dismiss()
                            } catch {
                                // Handle error - could show alert
                                print("Error submitting departure: \(error)")
                            }
                        }
                    } label: {
                        HStack { 
                            Spacer(); 
                            if viewModel.isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                                Text("Submitting...")
                            } else {
                                Text("Complete Departure").bold()
                            }
                            Spacer() 
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canSubmit || viewModel.isSaving)
                    .padding()
                }
            }
            .navigationTitle("Site Departure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { 
                ToolbarItem(placement: .cancellationAction) { 
                    Button("Close") { dismiss() } 
                } 
            }
        }
        .onAppear {
            Task {
                await viewModel.load(for: workerId, on: Date())
            }
        }
    }
}

// MARK: - Building Departure Card
struct BuildingDepartureCard: View {
    @Binding var entry: BuildingDepartureEntry
    let onPhotoAdded: (UIImage) -> Void
    let onPhotoRemoved: (Int) -> Void
    
    @State private var showingCamera = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Building Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let address = entry.address {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status pill
                HStack(spacing: 4) {
                    Image(systemName: entry.tasksComplete ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(entry.tasksComplete ? .green : .secondary)
                    Text(entry.tasksComplete ? "Complete" : "Pending")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(entry.tasksComplete ? Color.green.opacity(0.1) : Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Tasks Complete Toggle
            Toggle("All assigned tasks complete", isOn: $entry.tasksComplete)
                .onChange(of: entry.tasksComplete) { _ in
                    // Trigger recompute when changed - handled by parent
                }
            
            // Photo Upload Section
            if entry.requiresPhoto || !entry.photos.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Photo Evidence")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if entry.requiresPhoto {
                            Text("REQUIRED")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        Button(action: { showingCamera = true }) {
                            Label("Add Photo", systemImage: "camera")
                                .font(.caption)
                        }
                        .disabled(entry.photos.count >= 3)
                    }
                    
                    // Photo thumbnails
                    if !entry.photos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(entry.photos.enumerated()), id: \.offset) { index, photo in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: photo)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(8)
                                            .clipped()
                                        
                                        Button {
                                            onPhotoRemoved(index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Color.white, in: Circle())
                                        }
                                        .offset(x: 4, y: -4)
                                    }
                                }
                            }
                        }
                    } else if entry.requiresPhoto {
                        Text("Photo required for departure")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            
            // Notes Section
            VStack(alignment: .leading, spacing: 6) {
                Text("Notes (Optional)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextEditor(text: Binding(
                    get: { entry.note ?? "" },
                    set: { entry.note = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 60)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .sheet(isPresented: $showingCamera) {
            CyntientOpsImagePicker(
                image: .constant(nil),
                onImagePicked: { image in
                    onPhotoAdded(image)
                    showingCamera = false
                },
                sourceType: .camera
            )
        }
    }
}
