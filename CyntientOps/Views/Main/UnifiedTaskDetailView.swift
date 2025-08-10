//
//  UnifiedTaskDetailView.swift
//  CyntientOps v6.0
//
//  ✅ UNIFIED: Single task detail view for all roles and modes
//  ✅ SIMPLIFIED: Dedicated mode for accessibility and simplified interface
//  ✅ DARK ELEGANCE: Consistent theme across all modes
//  ✅ REAL-TIME: Live updates via DashboardSyncService
//  ✅ ACCESSIBLE: Large touch targets and clear typography in simplified mode
//  ✅ FIXED: Replaced CameraModel with working implementation
//

import SwiftUI
import PhotosUI
import MapKit
import Combine
import AVFoundation
import UIKit

struct UnifiedTaskDetailView: View {
    // MARK: - Properties
    let task: CoreTypes.ContextualTask
    let mode: TaskDetailMode
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    @StateObject private var viewModel: TaskDetailViewModel
    
    // Photo handling
    @State private var showPhotoCapture = false
    @State private var capturedPhoto: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?
    
    // Task state
    @State private var taskNotes = ""
    @State private var showCompletionConfirmation = false
    @State private var isCompleting = false
    
    // Admin features
    @State private var showReassignSheet = false
    @State private var showRescheduleSheet = false
    
    // Simplified mode states
    @State private var showSimplifiedPhotoOptions = false
    @State private var simplifiedPhotoTaken = false
    
    // MARK: - Mode Enum
    enum TaskDetailMode {
        case worker
        case admin
        case dashboard
        case simplified  // NEW: For workers with simplified interface
        
        var allowsEditing: Bool {
            switch self {
            case .admin: return true
            case .worker: return true
            case .dashboard: return false
            case .simplified: return true
            }
        }
        
        var showsAdvancedFeatures: Bool {
            switch self {
            case .admin: return true
            case .worker: return true
            case .dashboard: return true
            case .simplified: return false
            }
        }
    }
    
    // MARK: - Initialization
    init(task: CoreTypes.ContextualTask, mode: TaskDetailMode = .worker) {
        self.task = task
        self.mode = mode
        self._viewModel = StateObject(wrappedValue: TaskDetailViewModel())
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                CyntientOpsDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                // Content based on mode
                Group {
                    switch mode {
                    case .simplified:
                        simplifiedLayout
                    case .worker:
                        workerLayout
                    case .admin:
                        adminLayout
                    case .dashboard:
                        dashboardLayout
                    }
                }
            }
            .navigationBarTitleDisplayMode(mode == .simplified ? .inline : .large)
            .navigationTitle(mode == .simplified ? "" : "Task Details")
            .toolbar {
                toolbarContent
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPhotoCapture) {
            if mode == .simplified {
                SimplifiedPhotoCaptureView(
                    onPhotoTaken: { photo in
                        capturedPhoto = photo
                        simplifiedPhotoTaken = true
                        showPhotoCapture = false
                    },
                    onCancel: {
                        showPhotoCapture = false
                    }
                )
            } else {
                PhotoCaptureView(image: $capturedPhoto)
            }
        }
        .sheet(isPresented: $showReassignSheet) {
            TaskReassignmentPlaceholder(task: task)
        }
        .sheet(isPresented: $showRescheduleSheet) {
            TaskReschedulePlaceholder(task: task)
        }
        .alert("Task Completed!", isPresented: $showCompletionConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Great job! This task has been marked as complete.")
        }
    }
    
    // MARK: - Simplified Layout
    @ViewBuilder
    private var simplifiedLayout: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 1. Task Header - Extra Large
                VStack(spacing: 16) {
                    // Task icon
                    Image(systemName: task.category?.icon ?? "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                        .padding()
                        .background(
                            Circle()
                                .fill(CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.1))
                        )
                    
                    // Task title
                    Text(task.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Building name
                    if let building = task.building {
                        Label {
                            Text(building.name)
                                .font(.title2)
                                .fontWeight(.medium)
                        } icon: {
                            Image(systemName: "building.2.fill")
                                .font(.title2)
                        }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
                .francoDarkCardBackground()
                
                // 2. Essential Information Only
                VStack(spacing: 24) {
                    // Task description (if exists)
                    if let description = task.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Instructions", systemImage: "doc.text")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            
                            Text(description)
                                .font(.title3)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .francoDarkCardBackground()
                    }
                    
                    // Due time (if exists and not completed)
                    if let dueDate = task.dueDate, task.status != .completed {
                        HStack(spacing: 16) {
                            Image(systemName: "clock.fill")
                                .font(.largeTitle)
                                .foregroundColor(task.isOverdue ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.warning)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.isOverdue ? "OVERDUE" : "Due By")
                                    .font(.headline)
                                    .foregroundColor(task.isOverdue ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.secondaryText)
                                
                                Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .francoDarkCardBackground()
                    }
                }
                
                // 3. Photo Section (if required)
                if task.requiresPhoto == true && task.status != .completed {
                    VStack(spacing: 20) {
                        Label("Photo Required", systemImage: "camera.fill")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
                        
                        if let photo = capturedPhoto {
                            // Show captured photo
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .overlay(
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title)
                                            Text("Photo Added")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(
                                            CyntientOpsDesign.DashboardColors.success
                                                .opacity(0.9)
                                        )
                                    }
                                )
                            
                            // Retake button
                            Button(action: { showPhotoCapture = true }) {
                                Label("Take New Photo", systemImage: "camera")
                                    .font(.title3)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                            }
                            .padding(.top)
                        } else {
                            // Take photo button
                            Button(action: { showPhotoCapture = true }) {
                                VStack(spacing: 16) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 50))
                                    Text("Take Photo")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(CyntientOpsDesign.DashboardColors.warning)
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding()
                    .francoDarkCardBackground()
                }
                
                // 4. Status or Action
                if task.status == .completed {
                    // Completed status
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 80))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                        
                        Text("Task Completed")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                        
                        if let completedDate = task.completedAt {
                            Text("Completed \(completedDate.formatted(.relative(presentation: .named)))")
                                .font(.title3)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        }
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                    .francoDarkCardBackground()
                } else {
                    // Complete button
                    Button(action: completeSimplifiedTask) {
                        HStack(spacing: 20) {
                            if isCompleting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                            }
                            
                            Text(isCompleting ? "Completing..." : "Complete Task")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(
                            canCompleteSimplifiedTask ?
                            CyntientOpsDesign.DashboardColors.success :
                            CyntientOpsDesign.DashboardColors.inactive
                        )
                        .cornerRadius(20)
                    }
                    .disabled(!canCompleteSimplifiedTask || isCompleting)
                    
                    // Helper text if photo needed
                    if task.requiresPhoto == true && capturedPhoto == nil {
                        Label("Take a photo before completing", systemImage: "exclamationmark.circle")
                            .font(.title3)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
                            .padding(.top)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Worker Layout
    @ViewBuilder
    private var workerLayout: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Task header card
                taskHeaderCard
                
                // Task details card
                taskDetailsCard
                
                // Location card (if applicable)
                if task.building != nil {
                    locationCard
                }
                
                // Photo evidence section
                if task.requiresPhoto == true {
                    photoEvidenceCard
                }
                
                // Notes section
                notesCard
                
                // Action section
                if task.status != .completed {
                    workerActionSection
                }
            }
            .padding()
        }
    }
    
    // MARK: - Admin Layout
    @ViewBuilder
    private var adminLayout: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Task header with admin controls
                adminTaskHeaderCard
                
                // Task details
                taskDetailsCard
                
                // Worker assignment
                workerAssignmentCard
                
                // Location card
                if task.building != nil {
                    locationCard
                }
                
                // Photo evidence
                if task.requiresPhoto == true {
                    photoEvidenceCard
                }
                
                // Notes and history
                notesCard
                taskHistoryCard
                
                // Admin actions
                adminActionSection
            }
            .padding()
        }
    }
    
    // MARK: - Dashboard Layout (Read-only)
    @ViewBuilder
    private var dashboardLayout: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Task overview
                taskHeaderCard
                
                // Quick stats
                taskStatsCard
                
                // Details
                taskDetailsCard
                
                // Location
                if task.building != nil {
                    locationCard
                }
                
                // Completion evidence
                if task.status == .completed && task.requiresPhoto == true {
                    completionEvidenceCard
                }
            }
            .padding()
        }
    }
    
    // MARK: - Shared Components
    
    private var taskHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Status indicator
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                
                Spacer()
                
                // Urgency badge
                if let urgency = task.urgency {
                    Text(urgency.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(urgencyColor)
                        )
                        .foregroundColor(.white)
                }
            }
            
            Text(task.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if let category = task.category {
                Label(category.rawValue, systemImage: category.icon)
                    .font(.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var taskDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Details", systemImage: "info.circle")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if let description = task.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            Divider()
                .background(CyntientOpsDesign.DashboardColors.borderSubtle)
            
            // Timing information
            VStack(alignment: .leading, spacing: 8) {
                if let scheduled = task.scheduledDate {
                    HStack {
                        Label("Scheduled", systemImage: "calendar")
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        Spacer()
                        Text(scheduled.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    }
                    .font(.subheadline)
                }
                
                if let due = task.dueDate {
                    HStack {
                        Label("Due", systemImage: "clock")
                            .foregroundColor(task.isOverdue ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.secondaryText)
                        Spacer()
                        Text(due.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(task.isOverdue ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.primaryText)
                            .fontWeight(task.isOverdue ? .bold : .regular)
                    }
                    .font(.subheadline)
                }
                
                if let duration = task.estimatedDuration {
                    HStack {
                        Label("Estimated Duration", systemImage: "timer")
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        Spacer()
                        Text(formatDuration(duration))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Location", systemImage: "location")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if let building = task.building {
                VStack(alignment: .leading, spacing: 8) {
                    Text(building.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text(building.address)
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    // Mini map
                    Map(coordinateRegion: .constant(
                        MKCoordinateRegion(
                            center: building.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    ), annotationItems: [building]) { location in
                        MapMarker(coordinate: location.coordinate, tint: CyntientOpsDesign.DashboardColors.workerPrimary)
                    }
                    .frame(height: 150)
                    .cornerRadius(12)
                    .disabled(true)
                    
                    // Directions button
                    if mode == .worker {
                        Button(action: openInMaps) {
                            Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                                .font(.subheadline)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var photoEvidenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Photo Evidence", systemImage: "camera")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
                
                if task.requiresPhoto == true && task.status != .completed {
                    Text("Required")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(CyntientOpsDesign.DashboardColors.warning)
                        )
                        .foregroundColor(.white)
                }
            }
            
            if let photo = capturedPhoto {
                // Show captured photo
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .onTapGesture {
                        // Could show full screen preview
                    }
                
                if mode.allowsEditing && task.status != .completed {
                    Button(action: { showPhotoCapture = true }) {
                        Label("Retake Photo", systemImage: "camera")
                            .font(.subheadline)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                    }
                    .padding(.top, 8)
                }
            } else if mode.allowsEditing && task.status != .completed {
                // Photo capture options
                VStack(spacing: 12) {
                    Button(action: { showPhotoCapture = true }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title3)
                            Text("Take Photo")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(CyntientOpsDesign.DashboardColors.workerPrimary)
                        .cornerRadius(12)
                    }
                    
                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title3)
                            Text("Choose from Library")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(CyntientOpsDesign.DashboardColors.workerPrimary, lineWidth: 2)
                        )
                    }
                    .onChange(of: photoPickerItem) { newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                capturedPhoto = image
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notes", systemImage: "note.text")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if mode.allowsEditing && task.status != .completed {
                TextField("Add notes about this task...", text: $taskNotes, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(CyntientOpsDesign.DashboardColors.cardBackground)
                    )
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .lineLimit(3...6)
            } else if !taskNotes.isEmpty {
                Text(taskNotes)
                    .font(.body)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            } else {
                Text("No notes added")
                    .font(.body)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    .italic()
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    // MARK: - Action Sections
    
    private var workerActionSection: some View {
        VStack(spacing: 12) {
            Button(action: completeTask) {
                HStack {
                    if isCompleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                    }
                    
                    Text(isCompleting ? "Completing..." : "Complete Task")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    canCompleteTask ?
                    CyntientOpsDesign.DashboardColors.success :
                    CyntientOpsDesign.DashboardColors.inactive
                )
                .cornerRadius(12)
            }
            .disabled(!canCompleteTask || isCompleting)
            
            if task.requiresPhoto == true && capturedPhoto == nil {
                Text("Photo evidence required to complete task")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
            }
        }
        .padding()
    }
    
    // MARK: - Admin Components
    
    private var adminTaskHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                taskHeaderCard
                
                Menu {
                    Button(action: { showReassignSheet = true }) {
                        Label("Reassign Worker", systemImage: "person.2")
                    }
                    
                    Button(action: { showRescheduleSheet = true }) {
                        Label("Reschedule", systemImage: "calendar")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: cancelTask) {
                        Label("Cancel Task", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.adminPrimary)
                }
            }
        }
    }
    
    private var workerAssignmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Worker Assignment", systemImage: "person.badge.shield.checkmark")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if let worker = task.worker {
                HStack {
                    // Worker avatar
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.adminPrimary.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(worker.name.prefix(2).uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.adminPrimary)
                        )
                    
                    VStack(alignment: .leading) {
                        Text(worker.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        
                        if let phone = worker.phone {
                            Text(phone)
                                .font(.caption)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Contact button
                    Button(action: contactWorker) {
                        Image(systemName: "phone.circle.fill")
                            .font(.title2)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.adminPrimary)
                    }
                }
            } else {
                Text("No worker assigned")
                    .font(.body)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    .italic()
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var taskHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Task History", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                historyItem(
                    icon: "plus.circle",
                    text: "Task created",
                    date: task.createdAt,
                    color: CyntientOpsDesign.DashboardColors.info
                )
                
                if let scheduled = task.scheduledDate {
                    historyItem(
                        icon: "calendar.badge.plus",
                        text: "Scheduled",
                        date: scheduled,
                        color: CyntientOpsDesign.DashboardColors.info
                    )
                }
                
                if task.status == .completed, let completed = task.completedAt {
                    historyItem(
                        icon: "checkmark.circle",
                        text: "Completed",
                        date: completed,
                        color: CyntientOpsDesign.DashboardColors.success
                    )
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private func historyItem(icon: String, text: String, date: Date, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            Spacer()
            
            Text(date.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
    }
    
    private var adminActionSection: some View {
        VStack(spacing: 12) {
            if task.status != .completed {
                HStack(spacing: 12) {
                    Button(action: { showReassignSheet = true }) {
                        Label("Reassign", systemImage: "person.2")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.adminPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(CyntientOpsDesign.DashboardColors.adminPrimary, lineWidth: 2)
                            )
                    }
                    
                    Button(action: { showRescheduleSheet = true }) {
                        Label("Reschedule", systemImage: "calendar")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.adminPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(CyntientOpsDesign.DashboardColors.adminPrimary, lineWidth: 2)
                            )
                    }
                }
            }
            
            // Verification for completed tasks
            if task.status == .completed {
                Button(action: verifyTask) {
                    Label("Verify Completion", systemImage: "checkmark.seal")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(CyntientOpsDesign.DashboardColors.adminPrimary)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Dashboard Components
    
    private var taskStatsCard: some View {
        HStack(spacing: 20) {
            statItem(
                icon: "clock",
                value: formatDuration(task.estimatedDuration ?? 3600),
                label: "Duration"
            )
            
            if let worker = task.worker {
                statItem(
                    icon: "person",
                    value: worker.name.components(separatedBy: " ").first ?? "N/A",
                    label: "Assigned"
                )
            }
            
            if let urgency = task.urgency {
                statItem(
                    icon: "exclamationmark.circle",
                    value: urgency.rawValue,
                    label: "Priority"
                )
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
            
            Text(value)
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text(label)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var completionEvidenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Completion Evidence", systemImage: "checkmark.seal")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.success)
            
            if let completedAt = task.completedAt {
                HStack {
                    Text("Completed")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    Spacer()
                    Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
                .font(.subheadline)
            }
            
            if let worker = task.worker {
                HStack {
                    Text("By")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    Spacer()
                    Text(worker.name)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
                .font(.subheadline)
            }
            
            // Show photo evidence if available
            if task.requiresPhoto == true && capturedPhoto != nil {
                Text("Photo evidence provided")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                    .padding(.top, 8)
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { dismiss() }) {
                if mode == .simplified {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                        Text("Back")
                            .font(.title3)
                    }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                } else {
                    Image(systemName: "xmark")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
            }
        }
        
        if mode == .admin {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showReassignSheet = true }) {
                        Label("Reassign Worker", systemImage: "person.2")
                    }
                    
                    Button(action: { showRescheduleSheet = true }) {
                        Label("Reschedule", systemImage: "calendar")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: cancelTask) {
                        Label("Cancel Task", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.adminPrimary)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var canCompleteTask: Bool {
        if task.requiresPhoto == true && capturedPhoto == nil {
            return false
        }
        return task.status != .completed
    }
    
    private var canCompleteSimplifiedTask: Bool {
        if task.requiresPhoto == true && capturedPhoto == nil {
            return false
        }
        return task.status != .completed
    }
    
    private func completeTask() {
        guard canCompleteTask else { return }
        
        isCompleting = true
        
        Task {
            do {
                try await viewModel.completeTask(
                    notes: taskNotes
                )
                
                // Broadcast update
                let update = CoreTypes.DashboardUpdate(
                    source: mode == .admin ? .admin : .worker,
                    type: .taskCompleted,
                    buildingId: task.buildingId ?? "",
                    workerId: task.worker?.id ?? "",
                    data: [
                        "taskId": task.id,
                        "taskTitle": task.title,
                        "completedAt": ISO8601DateFormatter().string(from: Date())
                    ]
                )
                
                if mode == .admin {
                    await dashboardSync.broadcastAdminUpdate(update)
                } else {
                    await dashboardSync.broadcastWorkerUpdate(update)
                }
                
                await MainActor.run {
                    isCompleting = false
                    showCompletionConfirmation = true
                }
            } catch {
                await MainActor.run {
                    isCompleting = false
                    // Show error
                }
            }
        }
    }
    
    private func completeSimplifiedTask() {
        guard canCompleteSimplifiedTask else { return }
        
        isCompleting = true
        HapticManager.notification(.success)
        
        Task {
            do {
                try await viewModel.completeTask(
                    notes: "" // Simplified mode doesn't have notes
                )
                
                // Broadcast update
                let update = CoreTypes.DashboardUpdate(
                    source: mode == .admin ? .admin : .worker,
                    type: .taskCompleted,
                    buildingId: task.buildingId ?? "",
                    workerId: task.worker?.id ?? "",
                    data: [
                        "taskId": task.id,
                        "taskTitle": task.title,
                        "completedAt": ISO8601DateFormatter().string(from: Date())
                    ]
                )
                
                if mode == .admin {
                    await dashboardSync.broadcastAdminUpdate(update)
                } else {
                    await dashboardSync.broadcastWorkerUpdate(update)
                }
                
                await MainActor.run {
                    isCompleting = false
                    showCompletionConfirmation = true
                }
            } catch {
                await MainActor.run {
                    isCompleting = false
                    // In simplified mode, show a simple error
                    HapticManager.notification(.error)
                }
            }
        }
    }
    
    private func cancelTask() {
        // Admin function to cancel task - placeholder implementation
        // TODO: Implement task cancellation in TaskDetailViewModel
        dismiss()
    }
    
    private func verifyTask() {
        // Admin function to verify completion - placeholder implementation
        // TODO: Implement task verification in TaskDetailViewModel
        print("Task verification requested for task: \(task.id)")
    }
    
    private func contactWorker() {
        guard let phone = task.worker?.phone else { return }
        if let url = URL(string: "tel://\(phone)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openInMaps() {
        guard let building = task.building else { return }
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: building.coordinate))
        mapItem.name = building.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var statusIcon: String {
        switch task.status {
        case .pending: return "clock"
        case .inProgress: return "arrow.right.circle"
        case .completed: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .cancelled: return "xmark.circle"
        case .paused: return "pause.circle"
        case .waiting: return "hourglass"
        }
    }
    
    private var statusColor: Color {
        CyntientOpsDesign.EnumColors.taskStatus(task.status)
    }
    
    private var urgencyColor: Color {
        CyntientOpsDesign.EnumColors.taskUrgency(task.urgency ?? .low)
    }
}

// MARK: - Supporting Views

struct SimplifiedPhotoCaptureView: View {
    let onPhotoTaken: (UIImage) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        // For simplified mode, we'll use a standard photo capture
        PhotoCaptureView { capturedImage in
            if let image = capturedImage {
                onPhotoTaken(image)
            } else {
                onCancel()
            }
        }
    }
}

// MARK: - Photo Capture View

struct PhotoCaptureView: View {
    @Binding var image: UIImage?
    let completion: ((UIImage?) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraViewModel()
    
    init(image: Binding<UIImage?>) {
        self._image = image
        self.completion = nil
    }
    
    init(completion: @escaping (UIImage?) -> Void) {
        self._image = .constant(nil)
        self.completion = completion
    }
    
    var body: some View {
        ZStack {
            // Camera preview or image picker
            if camera.isCameraAvailable {
                CameraViewRepresentable(camera: camera)
                    .ignoresSafeArea()
            } else {
                // Fallback to image picker for simulator
                ImagePickerFallback(image: $image, completion: completion)
            }
            
            // Overlay controls
            VStack {
                // Top bar
                HStack {
                    Button("Cancel") {
                        if let completion = completion {
                            completion(nil)
                        } else {
                            dismiss()
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Bottom controls
                HStack(spacing: 50) {
                    // Gallery button
                    Button(action: {
                        camera.openPhotoLibrary()
                    }) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    // Capture button
                    Button(action: {
                        camera.capturePhoto { capturedImage in
                            if let completion = completion {
                                completion(capturedImage)
                            } else {
                                image = capturedImage
                                dismiss()
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 80, height: 80)
                        }
                    }
                    
                    // Flash button
                    Button(action: {
                        camera.toggleFlash()
                    }) {
                        Image(systemName: camera.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            camera.checkPermissions()
        }
    }
}

// MARK: - Camera View Model

@MainActor
class CameraViewModel: NSObject, ObservableObject {
    @Published var isCameraAvailable = true
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var showImagePicker = false
    
    var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var captureCompletionHandler: ((UIImage?) -> Void)?
    
    // Thread-safe access to completion handler
    private let completionQueue = DispatchQueue(label: "com.francosphere.camera.completion")
    
    private var captureCompletion: ((UIImage?) -> Void)? {
        get {
            completionQueue.sync { captureCompletionHandler }
        }
        set {
            completionQueue.sync { captureCompletionHandler = newValue }
        }
    }
    
    override init() {
        super.init()
        #if targetEnvironment(simulator)
        isCameraAvailable = false
        #else
        setupCamera()
        #endif
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                }
            }
        default:
            isCameraAvailable = false
        }
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // Add video input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            isCameraAvailable = false
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Add photo output
        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration()
        
        self.captureSession = session
        self.photoOutput = output
        
        // Start session on background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        
        guard let photoOutput = photoOutput else {
            completion(nil)
            return
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
    }
    
    func openPhotoLibrary() {
        showImagePicker = true
    }
    
    deinit {
        captureSession?.stopRunning()
    }
}

// MARK: - Camera Delegate

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            Task { @MainActor [weak self] in
                self?.captureCompletion?(nil)
                self?.captureCompletion = nil
            }
            return
        }
        
        Task { @MainActor [weak self] in
            self?.captureCompletion?(image)
            self?.captureCompletion = nil
        }
    }
}

// MARK: - Camera View Representable

struct CameraViewRepresentable: UIViewRepresentable {
    let camera: CameraViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        // Add preview layer
        if let session = camera.captureSession {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
}

// MARK: - Image Picker Fallback

struct ImagePickerFallback: View {
    @Binding var image: UIImage?
    let completion: ((UIImage?) -> Void)?
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("Camera not available")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("Use photo library instead")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Button("Cancel") {
                    if let completion = completion {
                        completion(nil)
                    } else {
                        dismiss()
                    }
                }
                .foregroundColor(.white.opacity(0.7))
                .padding()
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            UnifiedImagePicker(image: $inputImage)
        }
        .onChange(of: inputImage) { newImage in
            if let newImage = newImage {
                if let completion = completion {
                    completion(newImage)
                } else {
                    image = newImage
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Unified Image Picker (Renamed to avoid conflicts)

struct UnifiedImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: UnifiedImagePicker
        
        init(_ parent: UnifiedImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

struct UnifiedTaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Worker mode
            UnifiedTaskDetailView(
                task: CoreTypes.ContextualTask(
                    title: "Clean Main Lobby",
                    description: "Daily cleaning of the main lobby area",
                    status: .pending,
                    dueDate: Date().addingTimeInterval(3600),
                    category: .cleaning,
                    urgency: .medium,
                    building: CoreTypes.NamedCoordinate(
                        id: "1",
                        name: "123 Main Street",
                        address: "123 Main St, New York, NY",
                        latitude: 40.7128,
                        longitude: -74.0060
                    ),
                    requiresPhoto: true
                ),
                mode: .worker
            )
            .previewDisplayName("Worker Mode")
            
            // Simplified mode
            UnifiedTaskDetailView(
                task: CoreTypes.ContextualTask(
                    title: "Empty Trash Bins",
                    description: "Empty all trash bins on Floor 2",
                    status: .pending,
                    category: .sanitation,
                    urgency: .high,
                    building: CoreTypes.NamedCoordinate(
                        id: "1",
                        name: "Office Building",
                        address: "456 Park Ave",
                        latitude: 40.7128,
                        longitude: -74.0060
                    ),
                    requiresPhoto: true
                ),
                mode: .simplified
            )
            .previewDisplayName("Simplified Mode")
            
            // Admin mode
            UnifiedTaskDetailView(
                task: CoreTypes.ContextualTask(
                    title: "HVAC Maintenance",
                    description: "Quarterly HVAC system maintenance",
                    status: .pending,
                    dueDate: Date().addingTimeInterval(86400),
                    category: .maintenance,
                    urgency: .high,
                    building: CoreTypes.NamedCoordinate(
                        id: "2",
                        name: "Corporate Tower",
                        address: "789 Business Blvd",
                        latitude: 40.7589,
                        longitude: -73.9851
                    ),
                    worker: CoreTypes.WorkerProfile(
                        id: "w1",
                        name: "John Smith",
                        email: "john@example.com",
                        phone: "555-0123",
                        role: .worker
                    )
                ),
                mode: .admin
            )
            .previewDisplayName("Admin Mode")
        }
        .preferredColorScheme(.dark)
        .environmentObject(DashboardSyncService.shared)
    }
}

// MARK: - Placeholder Components

struct TaskReassignmentPlaceholder: View {
    let task: CoreTypes.ContextualTask
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Task Reassignment")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text("Reassignment functionality coming soon")
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationTitle("Reassign Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct TaskReschedulePlaceholder: View {
    let task: CoreTypes.ContextualTask
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Task Reschedule")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text("Reschedule functionality coming soon")
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationTitle("Reschedule Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
