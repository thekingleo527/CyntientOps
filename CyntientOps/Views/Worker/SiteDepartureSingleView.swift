//
//  SiteDepartureSingleView.swift
//  CyntientOps
//
//  Single-site departure content with optional photos (up to 3) and notes.
//

import SwiftUI

struct SiteDepartureSingleView: View {
    @ObservedObject var viewModel: SiteDepartureViewModel
    let buttonTitle: String
    let onSubmitted: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingCamera = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else if let checklist = viewModel.checklist {

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Tasks Completed").font(.caption).foregroundColor(.secondary)
                            Text("\(checklist.completedTasks.count)/\(checklist.allTasks.count)").font(.headline)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Photos").font(.caption).foregroundColor(.secondary)
                            Text("\(viewModel.capturedPhotos.count)/3").font(.headline)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    if !checklist.incompleteTasks.isEmpty {
                        Text("Completion").font(.headline)
                        Text("Confirm remaining items").font(.subheadline).foregroundColor(.secondary)
                        ForEach(checklist.incompleteTasks, id: \.id) { task in
                            Toggle(isOn: Binding(
                                get: { viewModel.checkmarkStates[task.id] ?? false },
                                set: { viewModel.checkmarkStates[task.id] = $0 }
                            )) {
                                VStack(alignment: .leading) {
                                    Text(task.title).font(.subheadline)
                                    if let b = task.building?.name { Text(b).font(.caption).foregroundColor(.secondary) }
                                }
                            }
#if os(iOS)
                            .toggleStyle(SwitchToggleStyle())
#else
                            .toggleStyle(.checkbox)
#endif
                        }
                    }

                    // Equipment section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Equipment").font(.headline)
                        Text("Secured & logged?").font(.subheadline).foregroundColor(.secondary)
                        Toggle("All equipment secured", isOn: Binding(
                            get: { viewModel.checkmarkStates["equip_secured"] ?? false },
                            set: { viewModel.checkmarkStates["equip_secured"] = $0 }
                        ))
                    }

                    // Cleanliness section with photo requirement affordance
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cleanliness").font(.headline)
                        Text("Trash area / lobby photos").font(.subheadline).foregroundColor(.secondary)
                    }

                    // Photos up to 10
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Photos (optional)").font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Button(action: { showingCamera = true }) { Label("Add", systemImage: "camera") }
                                .disabled(viewModel.capturedPhotos.count >= 10)
                        }
                        HStack(spacing: 8) {
                            ForEach(Array(viewModel.capturedPhotos.enumerated()), id: \.offset) { idx, img in
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipped()
                                    .cornerRadius(6)
                            }
                            if viewModel.capturedPhotos.isEmpty {
                                Text("Up to 10 photos").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }

                    // Docs/Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Docs").font(.headline)
                        Toggle("Notes uploaded", isOn: Binding(
                            get: { !viewModel.departureNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
                            set: { _ in }
                        ))
                        Text("Daily Log Notes").font(.caption).foregroundColor(.secondary)
                        TextEditor(text: $viewModel.departureNotes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }

                    Button {
                        Task {
                            let ok = await viewModel.finalizeDeparture(method: .normal)
                            if ok { onSubmitted() }
                        }
                    } label: {
                        HStack { Spacer(); Text(buttonTitle).bold(); Spacer() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canDepart)
                } else if let error = viewModel.error {
                    Text(error.localizedDescription).foregroundColor(.red)
                }
            }
            .padding()
        }
#if os(iOS)
        .sheet(isPresented: $showingCamera) {
            CyntientOpsImagePicker(
                image: .constant(nil),
                onImagePicked: { image in
                    if viewModel.capturedPhotos.count < 10 { viewModel.capturedPhotos.append(image) }
                    showingCamera = false
                },
                sourceType: .camera
            )
        }
#endif
        .onAppear { Task { await viewModel.loadChecklist() } }
    }
}
