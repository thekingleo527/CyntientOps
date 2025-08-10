
//  BuildingPhotoComponents.swift
//  CyntientOps v6.0
//
//  📸 PHOTOS: Evidence capture and management
//  🏷️ METADATA: GPS, timestamp, worker tracking
//  🔍 VERIFICATION: Compliance photo validation
//

import SwiftUI
import PhotosUI
import MapKit

// MARK: - Building Photo Gallery

struct BuildingPhotoGallery: View {
    let buildingId: String
    @State private var photos: [BuildingPhoto] = []
    @State private var selectedCategory: PhotoCategory = .all
    @State private var isGridView = true
    @State private var selectedPhoto: BuildingPhoto?
    @State private var showingPhotoDetail = false
    @State private var isLoading = true
    
    enum PhotoCategory: String, CaseIterable {
        case all = "All"
        case compliance = "Compliance"
        case maintenance = "Maintenance"
        case issues = "Issues"
        case spaces = "Spaces"
        case beforeAfter = "Before/After"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Photo Gallery", systemImage: "photo.stack")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // View toggle
                Button(action: { withAnimation { isGridView.toggle() } }) {
                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Stats
                Text("\(filteredPhotos.count) photos")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Category filter
            PhotoCategoryFilter(
                selectedCategory: $selectedCategory,
                photoCounts: getPhotoCounts()
            )
            
            // Photo grid/list
            if isLoading {
                ProgressView("Loading photos...")
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if filteredPhotos.isEmpty {
                EmptyPhotoGalleryView(category: selectedCategory)
            } else {
                if isGridView {
                    PhotoGridView(
                        photos: filteredPhotos,
                        onPhotoTap: { photo in
                            selectedPhoto = photo
                            showingPhotoDetail = true
                        }
                    )
                } else {
                    PhotoListView(
                        photos: filteredPhotos,
                        onPhotoTap: { photo in
                            selectedPhoto = photo
                            showingPhotoDetail = true
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .task {
            await loadPhotos()
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailSheet(photo: photo, buildingId: buildingId)
        }
    }
    
    private var filteredPhotos: [BuildingPhoto] {
        if selectedCategory == .all {
            return photos
        }
        return photos.filter { $0.category == selectedCategory.rawValue }
    }
    
    private func getPhotoCounts() -> [PhotoCategory: Int] {
        var counts: [PhotoCategory: Int] = [:]
        counts[.all] = photos.count
        
        for category in PhotoCategory.allCases where category != .all {
            counts[category] = photos.filter { $0.category == category.rawValue }.count
        }
        
        return counts
    }
    
    private func loadPhotos() async {
        do {
            let rows = try await GRDBManager.shared.query("""
                SELECT pe.*, tc.worker_id, w.name as worker_name
                FROM photo_evidence pe
                LEFT JOIN task_completions tc ON pe.completion_id = tc.id
                LEFT JOIN workers w ON tc.worker_id = w.id
                WHERE tc.building_id = ?
                ORDER BY pe.created_at DESC
                LIMIT 100
            """, [buildingId])
            
            photos = rows.compactMap { BuildingPhoto(from: $0) }
            isLoading = false
            
        } catch {
            print("❌ Error loading photos: \(error)")
            isLoading = false
        }
    }
}

// MARK: - Photo Category Filter

struct PhotoCategoryFilter: View {
    @Binding var selectedCategory: BuildingPhotoGallery.PhotoCategory
    let photoCounts: [BuildingPhotoGallery.PhotoCategory: Int]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BuildingPhotoGallery.PhotoCategory.allCases, id: \.self) { category in
                    PhotoCategoryChip(
                        category: category,
                        count: photoCounts[category] ?? 0,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
        }
    }
}

// MARK: - Space Photo Card

struct SpacePhotoCard: View {
    let space: BuildingSpace
    let photos: [BuildingPhoto]
    @State private var currentPhotoIndex = 0
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Photo carousel
            ZStack {
                if photos.isEmpty {
                    // Placeholder
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 120)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: space.icon)
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("No photos")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                } else {
                    TabView(selection: $currentPhotoIndex) {
                        ForEach(photos.indices, id: \.self) { index in
                            if let image = photos[index].thumbnail {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .clipped()
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 120)
                    .cornerRadius(12)
                    
                    // Photo counter
                    if photos.count > 1 {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("\(currentPhotoIndex + 1)/\(photos.count)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(8)
                                    .padding(8)
                            }
                        }
                    }
                }
            }
            .onTapGesture(perform: onTap)
            
            // Space info
            VStack(alignment: .leading, spacing: 4) {
                Text(space.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                HStack {
                    if let lastUpdated = space.lastPhotoDate {
                        Label(lastUpdated.formatted(date: .abbreviated, time: .omitted), 
                              systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    if space.requiresWeeklyPhoto && space.isPhotoOverdue {
                        Label("Update needed", systemImage: "exclamationmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Photo Comparison View

struct PhotoComparisonView: View {
    let beforePhoto: BuildingPhoto
    let afterPhoto: BuildingPhoto
    @State private var showingBefore = true
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Before & After", systemImage: "arrow.left.arrow.right")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Toggle
                Picker("View", selection: $showingBefore) {
                    Text("Before").tag(true)
                    Text("After").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }
            
            // Comparison view
            GeometryReader { geometry in
                ZStack {
                    // After photo (bottom layer)
                    if let afterImage = afterPhoto.fullImage {
                        Image(uiImage: afterImage)
                            .resizable()
                            .scaledToFit()
                    }
                    
                    // Before photo (top layer with mask)
                    if let beforeImage = beforePhoto.fullImage {
                        Image(uiImage: beforeImage)
                            .resizable()
                            .scaledToFit()
                            .mask(
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .frame(width: geometry.size.width * 0.5 + dragOffset)
                                    Color.clear
                                }
                            )
                    }
                    
                    // Divider line
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2)
                        .offset(x: dragOffset)
                        .shadow(radius: 2)
                    
                    // Drag handle
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundColor(.black)
                        )
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = max(-geometry.size.width/2, 
                                                   min(geometry.size.width/2, value.translation.width))
                                }
                        )
                }
            }
            .frame(height: 300)
            .cornerRadius(12)
            
            // Photo details
            HStack(spacing: 20) {
                PhotoComparisonDetail(
                    title: "Before",
                    photo: beforePhoto,
                    isHighlighted: showingBefore
                )
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.white.opacity(0.6))
                
                PhotoComparisonDetail(
                    title: "After",
                    photo: afterPhoto,
                    isHighlighted: !showingBefore
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Photo Annotation Tool

struct PhotoAnnotationTool: View {
    let photo: BuildingPhoto
    @State private var annotations: [PhotoAnnotation] = []
    @State private var isDrawing = false
    @State private var currentPath = Path()
    @State private var selectedTool = AnnotationTool.arrow
    @State private var selectedColor = Color.red
    @State private var showingTextInput = false
    @State private var textPosition = CGPoint.zero
    @State private var annotationText = ""
    
    enum AnnotationTool: String, CaseIterable {
        case arrow = "Arrow"
        case circle = "Circle"
        case text = "Text"
        case freehand = "Draw"
        
        var icon: String {
            switch self {
            case .arrow: return "arrow.up.left"
            case .circle: return "circle"
            case .text: return "textformat"
            case .freehand: return "pencil"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Toolbar
            HStack {
                // Tool selector
                ForEach(AnnotationTool.allCases, id: \.self) { tool in
                    Button(action: { selectedTool = tool }) {
                        Image(systemName: tool.icon)
                            .foregroundColor(selectedTool == tool ? .white : .white.opacity(0.6))
                            .frame(width: 44, height: 44)
                            .background(selectedTool == tool ? Color.blue : Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // Color picker
                ForEach([Color.red, Color.yellow, Color.green, Color.blue], id: \.self) { color in
                    Button(action: { selectedColor = color }) {
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                            )
                    }
                }
                
                Spacer()
                
                // Actions
                Button("Clear") {
                    annotations.removeAll()
                }
                .foregroundColor(.white.opacity(0.8))
                
                Button("Save") {
                    saveAnnotatedPhoto()
                }
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color.black.opacity(0.5))
            .cornerRadius(12)
            
            // Photo with annotations
            GeometryReader { geometry in
                ZStack {
                    // Base photo
                    if let image = photo.fullImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }
                    
                    // Annotations layer
                    Canvas { context, size in
                        for annotation in annotations {
                            drawAnnotation(annotation, in: context)
                        }
                        
                        // Current drawing
                        if isDrawing {
                            context.stroke(currentPath, with: .color(selectedColor), lineWidth: 3)
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                handleDrawing(value, in: geometry.size)
                            }
                            .onEnded { value in
                                finishDrawing(value, in: geometry.size)
                            }
                    )
                    .onTapGesture { location in
                        if selectedTool == .text {
                            textPosition = location
                            showingTextInput = true
                        }
                    }
                }
            }
            .background(Color.black)
            .cornerRadius(12)
        }
        .sheet(isPresented: $showingTextInput) {
            TextAnnotationInput(text: $annotationText) { text in
                addTextAnnotation(text: text, at: textPosition)
            }
        }
    }
    
    private func handleDrawing(_ value: DragGesture.Value, in size: CGSize) {
        if !isDrawing {
            isDrawing = true
            currentPath = Path()
            currentPath.move(to: value.startLocation)
        }
        
        switch selectedTool {
        case .freehand:
            currentPath.addLine(to: value.location)
        case .arrow:
            currentPath = Path { path in
                path.move(to: value.startLocation)
                path.addLine(to: value.location)
                // Add arrowhead
                let angle = atan2(value.location.y - value.startLocation.y,
                                value.location.x - value.startLocation.x)
                let arrowLength: CGFloat = 15
                let arrowAngle: CGFloat = .pi / 6
                
                path.move(to: value.location)
                path.addLine(to: CGPoint(
                    x: value.location.x - arrowLength * cos(angle - arrowAngle),
                    y: value.location.y - arrowLength * sin(angle - arrowAngle)
                ))
                
                path.move(to: value.location)
                path.addLine(to: CGPoint(
                    x: value.location.x - arrowLength * cos(angle + arrowAngle),
                    y: value.location.y - arrowLength * sin(angle + arrowAngle)
                ))
            }
        case .circle:
            let radius = hypot(value.location.x - value.startLocation.x,
                             value.location.y - value.startLocation.y)
            currentPath = Path { path in
                path.addEllipse(in: CGRect(
                    x: value.startLocation.x - radius,
                    y: value.startLocation.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
            }
        case .text:
            break
        }
    }
    
    private func finishDrawing(_ value: DragGesture.Value, in size: CGSize) {
        if isDrawing {
            let annotation = PhotoAnnotation(
                id: UUID().uuidString,
                type: selectedTool.rawValue,
                path: currentPath,
                color: selectedColor,
                startPoint: value.startLocation,
                endPoint: value.location,
                text: nil
            )
            annotations.append(annotation)
            isDrawing = false
            currentPath = Path()
        }
    }
    
    private func addTextAnnotation(text: String, at position: CGPoint) {
        let annotation = PhotoAnnotation(
            id: UUID().uuidString,
            type: AnnotationTool.text.rawValue,
            path: Path(),
            color: selectedColor,
            startPoint: position,
            endPoint: position,
            text: text
        )
        annotations.append(annotation)
    }
    
    private func drawAnnotation(_ annotation: PhotoAnnotation, in context: GraphicsContext) {
        if annotation.type == AnnotationTool.text.rawValue, let text = annotation.text {
            context.draw(Text(text)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(annotation.color),
                at: annotation.startPoint)
        } else {
            context.stroke(annotation.path, with: .color(annotation.color), lineWidth: 3)
        }
    }
    
    private func saveAnnotatedPhoto() {
        // Save annotated photo
        print("Saving annotated photo with \(annotations.count) annotations")
    }
}

// MARK: - Photo Metadata View

struct PhotoMetadataView: View {
    let photo: BuildingPhoto
    @State private var showingMap = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Photo Details", systemImage: "info.circle")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                // Basic info
                MetadataRow(label: "Taken By", value: photo.workerName ?? "Unknown")
                MetadataRow(label: "Date", value: photo.timestamp.formatted(date: .complete, time: .standard))
                MetadataRow(label: "Category", value: photo.category.capitalized)
                
                if let taskName = photo.taskName {
                    MetadataRow(label: "Task", value: taskName)
                }
                
                // Technical details
                if let fileSize = photo.fileSize {
                    MetadataRow(label: "Size", value: formatFileSize(fileSize))
                }
                
                MetadataRow(label: "Dimensions", value: "\(photo.width ?? 0) × \(photo.height ?? 0)")
                
                // Location
                if let location = photo.location {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Location:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Spacer()
                            
                            Button(action: { showingMap = true }) {
                                Label("View on Map", systemImage: "map")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text("\(location.latitude), \(location.longitude)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
                
                // Upload status
                HStack {
                    Text("Upload Status:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    if photo.isUploaded {
                        Label("Uploaded", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label("Pending", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .sheet(isPresented: $showingMap) {
            if let location = photo.location {
                PhotoLocationMapView(
                    coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ),
                    photoTitle: photo.taskName ?? "Photo Location"
                )
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Bulk Photo Uploader

struct BulkPhotoUploader: View {
    let buildingId: String
    @State private var selectedImages: [UIImage] = []
    @State private var selectedCategory = "general"
    @State private var uploadProgress: Double = 0
    @State private var isUploading = false
    @State private var uploadResults: [UploadResult] = []
    @State private var showingImagePicker = false
    @State private var notes = ""
    
    struct UploadResult: Identifiable {
        let id = UUID()
        let imageName: String
        let success: Bool
        let error: String?
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Label("Bulk Photo Upload", systemImage: "square.stack.3d.up")
                .font(.headline)
                .foregroundColor(.white)
            
            // Image selection
            if selectedImages.isEmpty {
                Button(action: { showingImagePicker = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        Text("Select Photos")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            } else {
                // Selected images preview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(selectedImages.count) photos selected")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Change") {
                            showingImagePicker = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedImages.indices, id: \.self) { index in
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            
            // Category selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Picker("Category", selection: $selectedCategory) {
                    Text("General").tag("general")
                    Text("Compliance").tag("compliance")
                    Text("Maintenance").tag("maintenance")
                    Text("Issues").tag("issues")
                    Text("Spaces").tag("spaces")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (optional)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Add notes about these photos...", text: $notes, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(2...4)
            }
            
            // Upload button
            if !isUploading {
                Button(action: startUpload) {
                    HStack {
                        Image(systemName: "cloud.upload")
                        Text("Upload Photos")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedImages.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(selectedImages.isEmpty)
            } else {
                // Upload progress
                VStack(spacing: 12) {
                    HStack {
                        Text("Uploading...")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(Int(uploadProgress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    ProgressView(value: uploadProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                }
            }
            
            // Results
            if !uploadResults.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upload Results")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.6))
                    
                    ForEach(uploadResults) { result in
                        HStack {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.success ? .green : .red)
                            
                            Text(result.imageName)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            if let error = result.error {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.03))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .sheet(isPresented: $showingImagePicker) {
            MultipleImagePicker(selectedImages: $selectedImages, limit: 10)
        }
    }
    
    private func startUpload() {
        isUploading = true
        uploadProgress = 0
        uploadResults = []
        
        Task {
            for (index, image) in selectedImages.enumerated() {
                // Compress and upload each image
                await uploadImage(image, index: index)
                uploadProgress = Double(index + 1) / Double(selectedImages.count)
            }
            
            isUploading = false
            
            // Clear successfully uploaded images
            if uploadResults.allSatisfy({ $0.success }) {
                selectedImages.removeAll()
            }
        }
    }
    
    private func uploadImage(_ image: UIImage, index: Int) async {
        // Simulate upload
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let success = Bool.random() // Simulate success/failure
        let result = UploadResult(
            imageName: "Photo \(index + 1)",
            success: success,
            error: success ? nil : "Network error"
        )
        
        uploadResults.append(result)
    }
}

// MARK: - Photo Compliance Verifier

struct PhotoComplianceVerifier: View {
    let buildingId: String
    let complianceType: CompliancePhotoType
    @State private var requiredPhotos: [RequiredPhoto] = []
    @State private var capturedPhotos: [String: BuildingPhoto] = [:]
    @State private var showingPhotoCapture = false
    @State private var selectedRequirement: RequiredPhoto?
    
    enum CompliancePhotoType: String, CaseIterable {
        case dailySanitation = "Daily Sanitation"
        case weeklyInspection = "Weekly Inspection"
        case monthlyCompliance = "Monthly Compliance"
        case incidentReport = "Incident Report"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label(complianceType.rawValue, systemImage: "checkmark.shield")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Progress
                Text("\(capturedCount) of \(requiredPhotos.count)")
                    .font(.caption)
                    .foregroundColor(isComplete ? .green : .orange)
            }
            
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
            
            // Required photos list
            VStack(spacing: 12) {
                ForEach(requiredPhotos) { requirement in
                    RequiredPhotoRow(
                        requirement: requirement,
                        capturedPhoto: capturedPhotos[requirement.id],
                        onCapture: {
                            selectedRequirement = requirement
                            showingPhotoCapture = true
                        },
                        onView: { photo in
                            // View captured photo
                        }
                    )
                }
            }
            
            // Submit button
            if isComplete {
                Button(action: submitCompliance) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Submit Compliance Report")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .onAppear {
            loadRequiredPhotos()
        }
        .sheet(isPresented: $showingPhotoCapture) {
            if let requirement = selectedRequirement {
                BuildingPhotoCaptureView(
                    requirement: requirement,
                    buildingId: buildingId,
                    onCapture: { photo in
                        capturedPhotos[requirement.id] = photo
                    }
                )
            }
        }
    }
    
    private var capturedCount: Int {
        capturedPhotos.count
    }
    
    private var progress: Double {
        guard !requiredPhotos.isEmpty else { return 0 }
        return Double(capturedCount) / Double(requiredPhotos.count)
    }
    
    private var progressColor: Color {
        switch progress {
        case 0..<0.5: return .red
        case 0.5..<0.8: return .orange
        case 0.8..<1.0: return .yellow
        case 1.0: return .green
        default: return .gray
        }
    }
    
    private var isComplete: Bool {
        !requiredPhotos.isEmpty && capturedCount == requiredPhotos.count
    }
    
    private func loadRequiredPhotos() {
        // Load requirements based on compliance type
        switch complianceType {
        case .dailySanitation:
            requiredPhotos = [
                RequiredPhoto(id: "entrance", title: "Building Entrance", description: "Clear view of main entrance"),
                RequiredPhoto(id: "sidewalk", title: "Sidewalk", description: "18 inches from curb"),
                RequiredPhoto(id: "trash", title: "Trash Area", description: "All bins properly stored")
            ]
        case .weeklyInspection:
            requiredPhotos = [
                RequiredPhoto(id: "lobby", title: "Lobby", description: "Overall cleanliness"),
                RequiredPhoto(id: "stairwells", title: "Stairwells", description: "All floors"),
                RequiredPhoto(id: "mechanical", title: "Mechanical Room", description: "Equipment status")
            ]
        default:
            requiredPhotos = []
        }
    }
    
    private func submitCompliance() {
        // Submit compliance report with all photos
        print("Submitting compliance report with \(capturedPhotos.count) photos")
    }
}

// MARK: - Supporting Views

struct PhotoGridView: View {
    let photos: [BuildingPhoto]
    let onPhotoTap: (BuildingPhoto) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(photos) { photo in
                    PhotoGridItem(photo: photo)
                        .onTapGesture {
                            onPhotoTap(photo)
                        }
                }
            }
        }
    }
}

struct PhotoListView: View {
    let photos: [BuildingPhoto]
    let onPhotoTap: (BuildingPhoto) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(photos) { photo in
                    PhotoListItem(photo: photo)
                        .onTapGesture {
                            onPhotoTap(photo)
                        }
                }
            }
        }
    }
}

struct PhotoGridItem: View {
    let photo: BuildingPhoto
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let thumbnail = photo.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
            }
            
            // Gradient overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.6)],
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Metadata
            VStack(alignment: .leading, spacing: 2) {
                if let workerName = photo.workerName {
                    Text(workerName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                Text(photo.timestamp, format: .dateTime.day().month())
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(6)
        }
        .cornerRadius(8)
    }
}

struct PhotoListItem: View {
    let photo: BuildingPhoto
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let thumbnail = photo.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                if let taskName = photo.taskName {
                    Text(taskName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                Text(photo.category.capitalized)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 8) {
                    if let workerName = photo.workerName {
                        Label(workerName, systemImage: "person.fill")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Label(photo.timestamp.formatted(date: .abbreviated, time: .shortened), 
                          systemImage: "calendar")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Upload status
            Image(systemName: photo.isUploaded ? "checkmark.circle.fill" : "arrow.up.circle")
                .foregroundColor(photo.isUploaded ? .green : .orange)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct PhotoCategoryChip: View {
    let category: BuildingPhotoGallery.PhotoCategory
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
            )
        }
    }
}

struct EmptyPhotoGalleryView: View {
    let category: BuildingPhotoGallery.PhotoCategory
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No \(category.rawValue.lowercased()) photos")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            Text("Photos will appear here as workers complete tasks")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

struct PhotoComparisonDetail: View {
    let title: String
    let photo: BuildingPhoto
    let isHighlighted: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(isHighlighted ? .semibold : .regular)
                .foregroundColor(isHighlighted ? .white : .white.opacity(0.6))
            
            VStack(alignment: .leading, spacing: 4) {
                if let workerName = photo.workerName {
                    Text(workerName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text(photo.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isHighlighted ? Color.white.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

struct PhotoLocationMapView: View {
    let coordinate: CLLocationCoordinate2D
    let photoTitle: String
    @State private var region: MKCoordinateRegion
    
    init(coordinate: CLLocationCoordinate2D, photoTitle: String) {
        self.coordinate = coordinate
        self.photoTitle = photoTitle
        self._region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: [coordinate]) { location in
                MapAnnotation(coordinate: coordinate) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.blue)
                            .background(Circle().fill(Color.white).frame(width: 30, height: 30))
                        Text(photoTitle)
                            .font(.caption)
                            .padding(4)
                            .background(Color.white)
                            .cornerRadius(4)
                    }
                }
            }
            .navigationTitle("Photo Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { }
                }
            }
        }
    }
}

struct RequiredPhotoRow: View {
    let requirement: RequiredPhoto
    let capturedPhoto: BuildingPhoto?
    let onCapture: () -> Void
    let onView: (BuildingPhoto) -> Void
    
    var body: some View {
        HStack {
            // Status icon
            Image(systemName: capturedPhoto != nil ? "checkmark.circle.fill" : "circle")
                .foregroundColor(capturedPhoto != nil ? .green : .gray)
            
            // Requirement details
            VStack(alignment: .leading, spacing: 4) {
                Text(requirement.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(requirement.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Action button
            if let photo = capturedPhoto {
                Button(action: { onView(photo) }) {
                    if let thumbnail = photo.thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            } else {
                Button(action: onCapture) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.blue)
                        .frame(width: 60, height: 60)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct TextAnnotationInput: View {
    @Binding var text: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter annotation text", text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Add Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onSave(text)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(text.isEmpty)
                }
            }
        }
    }
}

struct PhotoDetailSheet: View {
    let photo: BuildingPhoto
    let buildingId: String
    @State private var showingAnnotationTool = false
    @State private var showingShareSheet = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Full photo
                    if let fullImage = photo.fullImage {
                        Image(uiImage: fullImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                    }
                    
                    // Actions
                    HStack(spacing: 12) {
                        Button(action: { showingAnnotationTool = true }) {
                            Label("Annotate", systemImage: "pencil.tip.crop.circle")
                                .font(.subheadline)
                        }
                        
                        Button(action: { showingShareSheet = true }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.subheadline)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Metadata
                    PhotoMetadataView(photo: photo)
                }
                .padding()
            }
            .navigationTitle("Photo Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingAnnotationTool) {
            PhotoAnnotationTool(photo: photo)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = photo.fullImage {
                ShareSheet(items: [image])
            }
        }
    }
}

// MARK: - Data Models

struct BuildingPhoto: Identifiable {
    let id: String
    let buildingId: String
    let category: String
    let timestamp: Date
    let workerName: String?
    let workerId: String?
    let taskName: String?
    let taskId: String?
    let localPath: String
    let remoteUrl: String?
    let thumbnail: UIImage?
    let fullImage: UIImage?
    let fileSize: Int?
    let width: Int?
    let height: Int?
    let location: PhotoLocation?
    let isUploaded: Bool
    let metadata: [String: Any]?
    
    init(from row: [String: Any]) {
        self.id = row["id"] as? String ?? UUID().uuidString
        self.buildingId = row["building_id"] as? String ?? ""
        self.category = row["category"] as? String ?? "general"
        self.timestamp = ISO8601DateFormatter().date(from: row["created_at"] as? String ?? "") ?? Date()
        self.workerName = row["worker_name"] as? String
        self.workerId = row["worker_id"] as? String
        self.taskName = row["task_name"] as? String
        self.taskId = row["task_id"] as? String
        self.localPath = row["local_path"] as? String ?? ""
        self.remoteUrl = row["remote_url"] as? String
        self.fileSize = row["file_size"] as? Int
        self.width = row["width"] as? Int
        self.height = row["height"] as? Int
        
        if let lat = row["location_lat"] as? Double,
           let lon = row["location_lon"] as? Double {
            self.location = PhotoLocation(latitude: lat, longitude: lon)
        } else {
            self.location = nil
        }
        
        self.isUploaded = row["remote_url"] != nil
        self.metadata = row["metadata"] as? [String: Any]
        
        // Load images from local path
        if let image = UIImage(contentsOfFile: localPath) {
            self.fullImage = image
            self.thumbnail = image.preparingThumbnail(of: CGSize(width: 200, height: 200))
        } else {
            self.fullImage = nil
            self.thumbnail = nil
        }
    }
}

struct PhotoLocation {
    let latitude: Double
    let longitude: Double
}

extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude),\(longitude)"
    }
}

struct BuildingSpace: Identifiable {
    let id: String
    let name: String
    let icon: String
    let lastPhotoDate: Date?
    let requiresWeeklyPhoto: Bool
    let isPhotoOverdue: Bool
}

struct PhotoAnnotation: Identifiable {
    let id: String
    let type: String
    let path: Path
    let color: Color
    let startPoint: CGPoint
    let endPoint: CGPoint
    let text: String?
}

struct RequiredPhoto: Identifiable {
    let id: String
    let title: String
    let description: String
}

// MARK: - Helper Views

struct MultipleImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    let limit: Int
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = limit
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultipleImagePicker
        
        init(_ parent: MultipleImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            parent.selectedImages = []
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.selectedImages.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct BuildingPhotoCaptureView: View {
    let requirement: RequiredPhoto
    let buildingId: String
    let onCapture: (BuildingPhoto) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Text("Camera capture view for: \(requirement.title)")
            .onAppear {
                // In real implementation, would show camera
                // For now, create mock photo
                let mockPhoto = BuildingPhoto(from: [
                    "id": UUID().uuidString,
                    "building_id": buildingId,
                    "category": "compliance",
                    "created_at": Date().ISO8601Format(),
                    "task_name": requirement.title
                ])
                onCapture(mockPhoto)
                dismiss()
            }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
