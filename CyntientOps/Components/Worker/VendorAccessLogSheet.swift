//
//  VendorAccessLogSheet.swift
//  CyntientOps v6.0
//
//  🎯 WORKER VENDOR ACCESS LOGGING INTERFACE
//  ✅ Easy vendor access logging for workers
//  ✅ Building selection for assigned buildings
//  ✅ Vendor type categorization with icons
//  ✅ Photo evidence attachment
//  ✅ Real-time sync to admin intelligence panel
//  ✅ Intuitive form interface with validation
//

import SwiftUI
import PhotosUI

struct VendorAccessLogSheet: View {
    // MARK: - Environment & Dependencies
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WorkerDashboardViewModel
    
    // MARK: - Form State
    @State private var selectedBuildingId: String = ""
    @State private var vendorName: String = ""
    @State private var vendorCompany: String = ""
    @State private var selectedVendorType: WorkerDashboardViewModel.VendorType = .dobInspector
    @State private var selectedAccessType: WorkerDashboardViewModel.VendorAccessType = .scheduled
    @State private var accessDetails: String = ""
    @State private var notes: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showingCamera: Bool = false
    @State private var signatureData: String = ""
    @State private var showingSignaturePad: Bool = false
    
    // MARK: - UI State
    @State private var isSubmitting: Bool = false
    @State private var showingSuccess: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    
    // MARK: - Validation
    private var isFormValid: Bool {
        !selectedBuildingId.isEmpty &&
        !vendorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !accessDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !signatureData.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VendorAccessHeader()
                    
                    // Form Content
                    VStack(spacing: 20) {
                        // Building Selection
                        BuildingSelectionSection()
                        
                        // Vendor Information
                        VendorInformationSection()
                        
                        // Access Details
                        AccessDetailsSection()
                        
                        // Signature Section (Required)
                        SignatureSection()
                        
                        // Photo Evidence
                        PhotoEvidenceSection()
                        
                        // Notes
                        NotesSection()
                        
                        // Submit Button
                        SubmitButton()
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Log Vendor Access")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Pre-select current building if available
            if let currentBuilding = viewModel.currentBuilding {
                selectedBuildingId = currentBuilding.id
            } else if let firstBuilding = viewModel.assignedBuildings.first {
                selectedBuildingId = firstBuilding.id
            }
        }
        .onChange(of: selectedPhoto) { newPhoto in
            Task {
                if let newPhoto = newPhoto {
                    if let data = try? await newPhoto.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraSheet { imageData in
                photoData = imageData
            }
        }
        .sheet(isPresented: $showingSignaturePad) {
            SignaturePadSheet(
                onSignatureCapture: { signature in
                    signatureData = signature
                    showingSignaturePad = false
                },
                onCancel: {
                    showingSignaturePad = false
                }
            )
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Vendor access has been logged successfully.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header Section
    private func VendorAccessHeader() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            VStack(spacing: 6) {
                Text("Log Vendor Access")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Record when you provide access to vendors, inspectors, or contractors. A signature is required for security verification.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Building Selection
    private func BuildingSelectionSection() -> some View {
        FormSection(title: "Building", icon: "building.2.fill") {
            Picker("Select Building", selection: $selectedBuildingId) {
                ForEach(viewModel.assignedBuildings, id: \.id) { building in
                    Text(building.name)
                        .tag(building.id)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Vendor Information
    private func VendorInformationSection() -> some View {
        VStack(spacing: 16) {
            // Vendor/Personnel Name
            FormSection(title: "Personnel Name", icon: "person.fill") {
                TextField("Enter vendor's full name", text: $vendorName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Company/Service Name
            FormSection(title: "Company/Service", icon: "building.2.fill") {
                TextField("Enter company name (e.g., ConEd, Spectrum, DOB)", text: $vendorCompany)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Vendor Type - Grouped by Category
            FormSection(title: "Vendor Type", icon: "tag.fill") {
                VendorCategoryGrid()
            }
            
            // Access Type
            FormSection(title: "Access Type", icon: "key.fill") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 12) {
                    ForEach(WorkerDashboardViewModel.VendorAccessType.allCases, id: \.self) { accessType in
                        AccessTypeButton(
                            accessType: accessType,
                            isSelected: selectedAccessType == accessType
                        ) {
                            selectedAccessType = accessType
                            HapticManager.shared.impact(.light)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Access Details
    private func AccessDetailsSection() -> some View {
        FormSection(title: "Access Details", icon: "doc.text.fill") {
            TextField("Describe what access was provided (e.g., apartment unit, roof access, utility room)", text: $accessDetails, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...5)
        }
    }
    
    // MARK: - Signature Section
    private func SignatureSection() -> some View {
        FormSection(title: "Vendor Signature", icon: "signature") {
            VStack(spacing: 12) {
                if !signatureData.isEmpty {
                    // Show signature confirmation
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Signature captured")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Button("Retake") {
                            signatureData = ""
                            showingSignaturePad = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // Signature capture button
                    Button(action: { showingSignaturePad = true }) {
                        VStack(spacing: 12) {
                            Image(systemName: "signature")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                            
                            VStack(spacing: 4) {
                                Text("Capture Vendor Signature")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                
                                Text("Required for security verification")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Photo Evidence
    private func PhotoEvidenceSection() -> some View {
        FormSection(title: "Photo Evidence", icon: "camera.fill", optional: true) {
            VStack(spacing: 12) {
                if let photoData = photoData,
                   let uiImage = UIImage(data: photoData) {
                    // Show selected photo
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            Button(action: { self.photoData = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(8),
                            alignment: .topTrailing
                        )
                } else {
                    // Photo selection buttons
                    HStack(spacing: 16) {
                        PhotosPickerButton()
                        CameraButton()
                    }
                }
            }
        }
    }
    
    // MARK: - Notes Section
    private func NotesSection() -> some View {
        FormSection(title: "Additional Notes", icon: "note.text", optional: true) {
            TextField("Any additional information about this vendor access", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(2...4)
        }
    }
    
    // MARK: - Submit Button
    private func SubmitButton() -> some View {
        Button(action: submitVendorAccess) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                }
                
                Text(isSubmitting ? "Logging Access..." : "Log Vendor Access")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFormValid ? Color.blue : Color.gray)
            )
            .scaleEffect(isSubmitting ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isSubmitting)
        }
        .disabled(!isFormValid || isSubmitting)
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Photo Selection Components
    
    private func PhotosPickerButton() -> some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            VStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                Text("Photo Library")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func CameraButton() -> some View {
        Button(action: { showingCamera = true }) {
            VStack(spacing: 8) {
                Image(systemName: "camera")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                Text("Take Photo")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Action Methods
    
    private func submitVendorAccess() {
        guard isFormValid else { return }
        
        isSubmitting = true
        
        Task {
            do {
                // Convert photo data to string if available
                var photoEvidence: String?
                if let photoData = photoData {
                    photoEvidence = photoData.base64EncodedString()
                }
                
                // Log vendor access
                await viewModel.logVendorAccess(
                    buildingId: selectedBuildingId,
                    vendorName: vendorName.trimmingCharacters(in: .whitespacesAndNewlines),
                    vendorCompany: vendorCompany.trimmingCharacters(in: .whitespacesAndNewlines),
                    vendorType: selectedVendorType,
                    accessType: selectedAccessType,
                    accessDetails: accessDetails.trimmingCharacters(in: .whitespacesAndNewlines),
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                    photoEvidence: photoEvidence,
                    signatureData: signatureData.isEmpty ? nil : signatureData
                )
                
                // Check if there was an error
                if viewModel.errorMessage != nil {
                    await MainActor.run {
                        errorMessage = viewModel.errorMessage ?? "Unknown error occurred"
                        showingError = true
                        isSubmitting = false
                    }
                } else {
                    await MainActor.run {
                        showingSuccess = true
                        isSubmitting = false
                        HapticManager.shared.notification(.success)
                    }
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
    
    // MARK: - Vendor Category Grid
    private func VendorCategoryGrid() -> some View {
        VStack(spacing: 16) {
            // Group vendors by category for better organization
            ForEach(WorkerDashboardViewModel.VendorCategory.allCases, id: \.self) { category in
                let vendorsInCategory = WorkerDashboardViewModel.VendorType.allCases.filter { $0.category == category }
                
                if !vendorsInCategory.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        // Category Header
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 8, height: 8)
                            
                            Text(category.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(category.color)
                            
                            Spacer()
                        }
                        
                        // Vendors in Category
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                            ForEach(vendorsInCategory, id: \.self) { vendorType in
                                VendorTypeButton(
                                    vendorType: vendorType,
                                    isSelected: selectedVendorType == vendorType
                                ) {
                                    selectedVendorType = vendorType
                                    HapticManager.shared.impact(.light)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct SignaturePadSheet: View {
    let onSignatureCapture: (String) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Please have the vendor sign below to confirm access was provided")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                SignaturePad(
                    onSignatureCapture: { signature in
                        onSignatureCapture(signature)
                    },
                    onClear: {
                        // Signature cleared
                    }
                )
                .padding()
            }
            .navigationTitle("Vendor Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }

struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    let optional: Bool
    let content: () -> Content
    
    init(title: String, icon: String, optional: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.optional = optional
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if optional {
                    Text("(Optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            content()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct VendorTypeButton: View {
    let vendorType: WorkerDashboardViewModel.VendorType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: vendorType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : vendorType.category.color)
                    .frame(width: 20)
                
                Text(vendorType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? vendorType.category.color : vendorType.category.color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? vendorType.category.color : vendorType.category.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AccessTypeButton: View {
    let accessType: WorkerDashboardViewModel.VendorAccessType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(accessType.color)
                    .frame(width: 8, height: 8)
                
                Text(accessType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? accessType.color : accessType.color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Camera Sheet (Placeholder)
struct CameraSheet: View {
    let onImageCaptured: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // This would integrate with UIImagePickerController or similar
        NavigationView {
            Text("Camera functionality would be implemented here")
                .navigationTitle("Camera")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct VendorAccessLogSheet_Previews: PreviewProvider {
    static var previews: some View {
        let container = ServiceContainer.shared
        let mockViewModel = WorkerDashboardViewModel(container: container)
        
        VendorAccessLogSheet(viewModel: mockViewModel)
    }
}
#endif