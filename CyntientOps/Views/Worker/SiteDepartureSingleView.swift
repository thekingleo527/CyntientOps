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
                } else if let s = viewModel.section {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text(s.buildingName).font(.headline)
                            Text("Today").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(viewModel.checklistCountDone)/\(viewModel.checklistCountTotal)")
                                .font(.title3).bold()
                            Text("Checklist").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    // Tasks pill
                    HStack {
                        Text("All assigned tasks complete")
                            .font(.subheadline)
                        Spacer()
                        if viewModel.allTasksComplete {
                            Label("Done", systemImage: "checkmark.seal.fill").foregroundColor(.green)
                        } else {
                            Button("Mark Complete") {
                                Task { try? await viewModel.markAllTasksComplete() }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))

                    // Photos pill
                    HStack {
                        Text("Task photo uploaded (today)")
                            .font(.subheadline)
                        Spacer()
                        if viewModel.photosComplete {
                            Label("Done", systemImage: "checkmark.seal.fill").foregroundColor(.green)
                        } else {
                            Button(action: { showingCamera = true }) { Label("Upload", systemImage: "camera") }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))

                    // Clock-out
                    Button {
                        Task {
                            if viewModel.canClockOut() {
                                onSubmitted()
                            }
                        }
                    } label: {
                        HStack { Spacer(); Text(buttonTitle).bold(); Spacer() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canClockOut())
                } else if let err = viewModel.errorMessage {
                    Text(err).foregroundColor(.red)
                }
            }
            .padding()
        }
#if os(iOS)
        .sheet(isPresented: $showingCamera) {
            CyntientOpsImagePicker(
                image: .constant(nil),
                onImagePicked: { image in
                    Task { try? await viewModel.attachPhoto(image); showingCamera = false }
                },
                sourceType: .camera
            )
        }
#endif
        .onAppear { Task { await viewModel.hydrate() } }
    }
}
