//
//  ImagePicker.swift
//  CyntientOps v6.0
//
//  Basic image pickers. Gallery components live under:
//  Views/Components/Buildings/Supporting/BuildingPhotoComponents.swift
//

import SwiftUI
import PhotosUI

// MARK: - Basic Image Picker (single image)

struct CyntientOpsImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: ((UIImage) -> Void)?
    var sourceType: UIImagePickerController.SourceType = .camera
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CyntientOpsImagePicker
        init(_ parent: CyntientOpsImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImagePicked?(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Photo Picker (multiple selection)

struct PhotoPicker: View {
    @Binding var selectedImages: [UIImage]
    @State private var selectedItems: [PhotosPickerItem] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images, photoLibrary: .shared()) {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("Select Photos").font(.headline)
                        Text("Choose up to 10 photos").font(.subheadline).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .onChange(of: selectedItems) { _, _ in
                    Task {
                        var newImages: [UIImage] = []
                        for item in selectedItems {
                            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                                newImages.append(image)
                            }
                        }
                        selectedImages = newImages
                    }
                }
            }
            .navigationTitle("Choose Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() }.fontWeight(.semibold).disabled(selectedImages.isEmpty) }
            }
        }
    }
}

