//
//  SiteDepartureSheet.swift
//  CyntientOps
//
//  Minimal site departure flow enforcing daily log before clock-out
//

import SwiftUI

struct SiteDepartureSheet: View {
    @ObservedObject var viewModel: SiteDepartureViewModel
    let onFinished: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle("Site Departure")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
        }
        .onAppear { Task { await viewModel.loadChecklist() } }
    }
    
    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else if let checklist = viewModel.checklist {
                    // Summary
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Tasks Completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(checklist.completedTasks.count)/\(checklist.allTasks.count)")
                                .font(.headline)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Photos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(checklist.photoCount)/\(checklist.requiredPhotoCount)")
                                .font(.headline)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    // Incomplete tasks confirmation
                    if !checklist.incompleteTasks.isEmpty {
                        Text("Confirm remaining items")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                            .toggleStyle(.checkbox)
                        }
                    }

                    // Notes (daily log)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Log Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $viewModel.departureNotes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }

                    // Finalize button
                    Button {
                        Task {
                            let ok = await viewModel.finalizeDeparture(method: .normal)
                            if ok { onFinished(); dismiss() }
                        }
                    } label: {
                        HStack { Spacer(); Text("Submit Log & Clock Out").bold(); Spacer() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canDepart)
                } else if let error = viewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
    }
}

