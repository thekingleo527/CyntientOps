//
//  QuickNoteSheet.swift
//  CyntientOps
//
//  Quick worker note with optional photo evidence, logged to AdminOperationalIntelligence
//  and persisted via WorkerDashboardViewModel.addDailyNote.
//

import SwiftUI
import PhotosUI

struct QuickNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WorkerDashboardViewModel

    @State private var noteText: String = ""
    @State private var category: WorkerDashboardViewModel.NoteCategory = .general
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Category selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category").font(.caption).foregroundColor(.secondary)
                        WrapCategoryPicker(category: $category)
                    }

                    // Note text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note").font(.caption).foregroundColor(.secondary)
                        TextEditor(text: $noteText)
                            .frame(minHeight: 120)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                    }

                    // Photo evidence
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo Evidence (optional)").font(.caption).foregroundColor(.secondary)
                        HStack(spacing: 12) {
                            PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                                Label("Select Photo", systemImage: "photo.fill.on.rectangle.fill")
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                            if let data = photoData, let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipped()
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2)))
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Quick Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveNote) {
                        if isSaving { ProgressView() } else { Text("Save").bold() }
                    }
                    .disabled(isSaving || noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: selectedPhoto) { newValue in
                Task { @MainActor in
                    guard let item = newValue else { return }
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func saveNote() {
        isSaving = true
        Task {
            let photoEvidence = photoData?.base64EncodedString()
            await viewModel.addDailyNote(
                noteText: noteText,
                category: category,
                photoEvidence: photoEvidence,
                location: nil
            )
            isSaving = false
            dismiss()
        }
    }
}

private struct WrapCategoryPicker: View {
    @Binding var category: WorkerDashboardViewModel.NoteCategory
    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(WorkerDashboardViewModel.NoteCategory.allCases, id: \.self) { cat in
                Button(action: { category = cat }) {
                    HStack(spacing: 8) {
                        Image(systemName: cat.icon)
                        Text(cat.rawValue)
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(cat == category ? cat.color.opacity(0.2) : Color.gray.opacity(0.15))
                    .foregroundColor(cat == category ? cat.color : .secondary)
                    .cornerRadius(8)
                }
            }
        }
    }
}

