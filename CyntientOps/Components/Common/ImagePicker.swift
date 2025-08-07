//
//  ImagePicker.swift
//  CyntientOps v6.0
//
//  📸 PHOTO MANAGEMENT: Unified image handling for Phase 3
//  🖼️ GALLERY: Building photo organization with evidence tracking
//  📍 GEOTAGGING: Location-aware photos for compliance
//  ✅ PHASE 3 READY: Integrated with PhotoEvidenceService
//
//  Note: Renamed components to avoid conflicts:
//  - BuildingPhoto → FrancoBuildingPhoto
//  - PhotoGridItem → FrancoPhotoGridItem
//  - BuildingPhotoGallery → FrancoBuildingPhotoGallery
//

import SwiftUI
import PhotosUI
import CoreLocation
import Combine

// MARK: - Photo Category (Using unique name to avoid conflicts)

enum PhotoCategory: String, CaseIterable {
    case all = "All"
    case exterior = "Exterior"
    case interior = "Interior"
    case utilities = "Utilities"
    case issues = "Issues"
    case before = "Before"
    case after = "After"
    case equipment = "Equipment"
    case compliance = "Compliance"
    case general = "General"
    
    var icon: String {
        switch self {
        case .all: return "square.grid.3x3"
        case .exterior: return "building.2"
        case .interior: return "door.left.hand.open"
        case .utilities: return "wrench"
        case .issues: return "exclamationmark.triangle"
        case .before: return "arrow.left.square"
        case .after: return "arrow.right.square"
        case .equipment: return "hammer"
        case .compliance: return "checkmark.shield"
        case .general: return "photo"
        }
    }
    
    var displayName: String { self.rawValue }
}

// Use PhotoCategory consistently throughout the file
typealias FrancoPhotoCategory = PhotoCategory

// MARK: - Basic Image Picker (Renamed to avoid conflict)

struct FrancoImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: ((UIImage) -> Void)?
    var sourceType: UIImagePickerController.SourceType = .camera
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        
        if sourceType == .camera {
            picker.showsCameraControls = true
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: FrancoImagePicker
        
        init(_ parent: FrancoImagePicker) {
            self.parent = parent
        }
        
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

// MARK: - Photo Picker (Multiple Selection)

struct FrancoPhotoPicker: View {
    @Binding var selectedImages: [UIImage]
    @State private var selectedItems: [PhotosPickerItem] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 10,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Select Photos")
                            .font(.headline)
                        
                        Text("Choose up to 10 photos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .onChange(of: selectedItems) { oldValue, newValue in
                    Task {
                        var newImages: [UIImage] = []
                        for item in selectedItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .disabled(selectedImages.isEmpty)
                }
            }
        }
    }
}

// MARK: - Building Photo Gallery (Renamed to avoid conflict)

struct FrancoBuildingPhotoGallery: View {
    let buildingId: String
    @StateObject private var viewModel = FrancoPhotoGalleryViewModel()
    @State private var selectedCategory = PhotoCategory.all
    @State private var showingFullScreen = false
    @State private var selectedPhoto: FrancoBuildingPhoto?
    @State private var showingAddPhoto = false
    
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PhotoCategory.allCases, id: \.self) { category in
                        FrancoCategoryPill(
                            category: category,
                            isSelected: selectedCategory == category,
                            count: viewModel.photoCount(for: category)
                        ) {
                            withAnimation {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            
            // Photo grid
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading photos...")
                    .padding()
                Spacer()
            } else if viewModel.filteredPhotos(for: selectedCategory).isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No Photos Yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(selectedCategory == .all ? "Add photos to document this building" : "No photos in this category")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(viewModel.filteredPhotos(for: selectedCategory)) { photo in
                            FrancoPhotoGridItem(photo: photo) {
                                selectedPhoto = photo
                                showingFullScreen = true
                            }
                        }
                    }
                }
            }
            
            // Add photo button
            VStack {
                Button(action: { showingAddPhoto = true }) {
                    Label("Add Photo", systemImage: "camera.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
            .background(.thinMaterial)
        }
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPhotos(for: buildingId)
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            FrancoPhotoDetailView(photo: photo)
        }
        .sheet(isPresented: $showingAddPhoto) {
            FrancoBuildingPhotoCaptureView(
                buildingId: buildingId
            ) { image, category, notes in
                await viewModel.savePhoto(image, buildingId: buildingId, category: category, notes: notes)
            }
        }
    }
}

// MARK: - Building Photo Capture View

struct FrancoBuildingPhotoCaptureView: View {
    let buildingId: String
    let onCapture: (UIImage, PhotoCategory, String) async -> Void
    
    @State private var capturedImage: UIImage?
    @State private var category = PhotoCategory.general
    @State private var notes = ""
    @State private var showingCamera = true
    @StateObject private var locationManager = LocationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            if let image = capturedImage {
                // Review captured image
                VStack(spacing: 0) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .background(Color.black)
                    
                    Form {
                        Section("Details") {
                            Picker("Category", selection: $category) {
                                ForEach(PhotoCategory.allCases, id: \.self) { cat in
                                    if cat != .all {
                                        Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                                    }
                                }
                            }
                            
                            TextField("Notes (optional)", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                        }
                        
                        Section {
                            Button("Save Photo") {
                                Task {
                                    await onCapture(image, category, notes)
                                    dismiss()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                            
                            Button("Retake", role: .destructive) {
                                capturedImage = nil
                                showingCamera = true
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .navigationTitle("Add Photo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
            } else if showingCamera {
                FrancoImagePicker(
                    image: $capturedImage,
                    onImagePicked: { image in
                        capturedImage = image
                        showingCamera = false
                    },
                    sourceType: .camera
                )
                .ignoresSafeArea()
            }
        }
        .onAppear {
            locationManager.requestSingleUpdate()
        }
    }
}

// MARK: - Category Pill

struct FrancoCategoryPill: View {
    let category: PhotoCategory
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                
                Text(category.displayName)
                    .font(.subheadline)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.blue.opacity(0.3))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
        }
    }
}

// MARK: - Photo Grid Item (Renamed)

struct FrancoPhotoGridItem: View {
    let photo: FrancoBuildingPhoto
    let onTap: () -> Void
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .aspectRatio(1, contentMode: .fill)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                
                // Overlay badges
                VStack {
                    HStack {
                        if photo.hasIssue {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        if photo.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                    }
                    
                    Spacer()
                }
                .padding(4)
            }
        }
        .buttonStyle(.plain)
        .task {
            thumbnail = await FrancoPhotoStorageService.shared.loadThumbnail(for: photo.id)
        }
    }
}

// MARK: - Photo Detail View

struct FrancoPhotoDetailView: View {
    let photo: FrancoBuildingPhoto
    @State private var fullImage: UIImage?
    @State private var showingActions = false
    @State private var isZoomed = false
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = fullImage {
                    FrancoPhotoZoomView(image: image, isZoomed: $isZoomed)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                // Overlay info
                if !isZoomed {
                    VStack {
                        // Top bar
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            Button(action: { showingActions = true }) {
                                Image(systemName: "ellipsis")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Photo info
                        FrancoPhotoInfoOverlay(photo: photo)
                    }
                }
            }
            .navigationBarHidden(true)
            .statusBar(hidden: true)
        }
        .task {
            fullImage = await FrancoPhotoStorageService.shared.loadFullImage(for: photo.id)
        }
        .confirmationDialog("Photo Actions", isPresented: $showingActions) {
            Button("Share") { sharePhoto() }
            Button("Download") { downloadPhoto() }
            if !photo.hasIssue {
                Button("Mark as Issue") { markAsIssue() }
            }
            Button("Delete", role: .destructive) { deletePhoto() }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func sharePhoto() {
        guard let image = fullImage else { return }
        
        let av = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(av, animated: true)
        }
    }
    
    private func downloadPhoto() {
        guard let image = fullImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    private func markAsIssue() {
        Task {
            await FrancoPhotoStorageService.shared.markPhotoAsIssue(photo.id)
        }
    }
    
    private func deletePhoto() {
        Task {
            await FrancoPhotoStorageService.shared.deletePhoto(photo.id)
            dismiss()
        }
    }
}

// MARK: - Photo Zoom View

struct FrancoPhotoZoomView: View {
    let image: UIImage
    @Binding var isZoomed: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = lastScale * value
                        isZoomed = scale > 1.1
                    }
                    .onEnded { _ in
                        lastScale = scale
                        
                        withAnimation(.spring()) {
                            if scale < 1 {
                                scale = 1
                                lastScale = 1
                                offset = .zero
                                lastOffset = .zero
                                isZoomed = false
                            }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        if scale > 1 {
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    if scale > 1 {
                        scale = 1
                        lastScale = 1
                        offset = .zero
                        lastOffset = .zero
                        isZoomed = false
                    } else {
                        scale = 2
                        lastScale = 2
                        isZoomed = true
                    }
                }
            }
    }
}

// MARK: - Photo Info Overlay

struct FrancoPhotoInfoOverlay: View {
    let photo: FrancoBuildingPhoto
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(photo.category.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(photo.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let worker = photo.uploadedBy {
                        Text("By \(worker)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if photo.hasLocation {
                        Label("GPS", systemImage: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            if let notes = photo.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
            }
            
            if photo.taskId != nil {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.caption)
                    Text("Task Evidence")
                        .font(.caption)
                }
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - View Model (Renamed)

@MainActor
class FrancoPhotoGalleryViewModel: ObservableObject {
    @Published var photos: [FrancoBuildingPhoto] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let locationManager = LocationManager.shared
    
    init() {
        locationManager.requestSingleUpdate()
    }
    
    func loadPhotos(for buildingId: String) async {
        isLoading = true
        
        do {
            photos = try await FrancoPhotoStorageService.shared.loadPhotos(for: buildingId)
        } catch {
            self.error = error
            print("❌ Failed to load photos: \(error)")
        }
        
        isLoading = false
    }
    
    func savePhoto(_ image: UIImage, buildingId: String, category: PhotoCategory = .general, notes: String? = nil) async {
        do {
            let metadata = FrancoBuildingPhotoMetadata(
                buildingId: buildingId,
                category: category,
                notes: notes,
                location: locationManager.location,
                taskId: nil,
                workerId: NewAuthManager.shared.workerId,
                timestamp: Date()
            )
            
            let photo = try await FrancoPhotoStorageService.shared.savePhoto(image, metadata: metadata)
            photos.insert(photo, at: 0)
        } catch {
            self.error = error
            print("❌ Failed to save photo: \(error)")
        }
    }
    
    func photoCount(for category: PhotoCategory) -> Int {
        if category == .all {
            return photos.count
        }
        return photos.filter { $0.category == category }.count
    }
    
    func filteredPhotos(for category: PhotoCategory) -> [FrancoBuildingPhoto] {
        if category == .all {
            return photos.sorted { $0.timestamp > $1.timestamp }
        }
        return photos.filter { $0.category == category }.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Data Models (Renamed to avoid conflicts)

struct FrancoBuildingPhoto: Identifiable, Hashable {
    let id: String
    let buildingId: String
    let category: PhotoCategory
    let timestamp: Date
    let uploadedBy: String?
    let notes: String?
    let localPath: String
    let remotePath: String?
    let thumbnailPath: String?
    let hasIssue: Bool
    let isVerified: Bool
    let hasLocation: Bool
    let location: CLLocation?
    let taskId: String?
    let fileSize: Int?
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implement Equatable
    static func == (lhs: FrancoBuildingPhoto, rhs: FrancoBuildingPhoto) -> Bool {
        lhs.id == rhs.id
    }
}

struct FrancoBuildingPhotoMetadata {
    let buildingId: String
    let category: PhotoCategory
    let notes: String?
    let location: CLLocation?
    let taskId: String?
    let workerId: String?
    let timestamp: Date
}

// MARK: - Photo Storage Service (Phase 3 Integration - Renamed)

actor FrancoPhotoStorageService {
    static let shared = FrancoPhotoStorageService()
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private let grdbManager = GRDBManager.shared
    private let compressionQuality: CGFloat = 0.7
    private let thumbnailSize = CGSize(width: 400, height: 400)
    
    func loadPhotos(for buildingId: String) async throws -> [FrancoBuildingPhoto] {
        // Implementation would go here
        return []
    }
    
    func savePhoto(_ image: UIImage, metadata: FrancoBuildingPhotoMetadata) async throws -> FrancoBuildingPhoto {
        // Implementation would go here
        // Placeholder return
        return FrancoBuildingPhoto(
            id: UUID().uuidString,
            buildingId: metadata.buildingId,
            category: metadata.category,
            timestamp: Date(),
            uploadedBy: metadata.workerId,
            notes: metadata.notes,
            localPath: "",
            remotePath: nil,
            thumbnailPath: nil,
            hasIssue: false,
            isVerified: false,
            hasLocation: metadata.location != nil,
            location: metadata.location,
            taskId: metadata.taskId,
            fileSize: nil
        )
    }
    
    func loadThumbnail(for photoId: String) async -> UIImage? {
        // Implementation would go here
        return nil
    }
    
    func loadFullImage(for photoId: String) async -> UIImage? {
        // Implementation would go here
        return nil
    }
    
    func markPhotoAsIssue(_ photoId: String) async {
        // Implementation would go here
    }
    
    func deletePhoto(_ photoId: String) async {
        // Implementation would go here
    }
}

// MARK: - Error Types

enum FrancoPhotoError: LocalizedError {
    case compressionFailed
    case saveFailed
    case loadFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .saveFailed:
            return "Failed to save photo"
        case .loadFailed:
            return "Failed to load photo"
        case .deleteFailed:
            return "Failed to delete photo"
        }
    }
}
