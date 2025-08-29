//
//  ProfileAssignedBuildingsView.swift
//  CyntientOps
//
//  Shows actual building assignments from OperationalDataManager
//  Displays real building data with coordinates, task counts, and completion status
//

import SwiftUI
import MapKit
import CoreLocation

public struct ProfileAssignedBuildingsView: View {
    
    @StateObject private var viewModel: WorkerProfileViewModel
    @State private var selectedBuilding: WorkerProfileViewModel.BuildingAssignment? = nil
    @State private var showingBuildingDetails = false
    @State private var showingMapView = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    public init(viewModel: WorkerProfileViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Header
            headerView
            
            // Buildings Grid or Empty State
            if viewModel.currentAssignments.isEmpty {
                emptyStateView
            } else {
                buildingsGridView
            }
            
            // Map Toggle
            mapToggleView
        }
        .padding()
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingBuildingDetails) {
            if let building = selectedBuilding {
                BuildingDetailSheet(assignment: building, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingMapView) {
            ProfileBuildingsMapView(
                assignments: viewModel.currentAssignments,
                region: $mapRegion,
                onBuildingSelected: { assignment in
                    selectedBuilding = assignment
                    showingMapView = false
                    showingBuildingDetails = true
                }
            )
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Assigned Buildings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let worker = viewModel.currentWorker {
                    Text("\(worker.name)'s Properties")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Summary Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(viewModel.currentAssignments.count) Buildings")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                let activeBuildingsCount = viewModel.currentAssignments.filter(\.isActiveToday).count
                Text("\(activeBuildingsCount) Active Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Building Assignments")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Worker building assignments will appear here once loaded from the operational data.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 32)
    }
    
    private var buildingsGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.currentAssignments, id: \.buildingId) { assignment in
                    BuildingAssignmentCard(
                        assignment: assignment,
                        onTap: {
                            selectedBuilding = assignment
                            showingBuildingDetails = true
                        }
                    )
                }
            }
        }
    }
    
    private var mapToggleView: some View {
        HStack {
            Spacer()
            
            Button(action: {
                updateMapRegion()
                showingMapView = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "map")
                        .font(.caption)
                    
                    Text("View on Map")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(20)
            }
            .disabled(viewModel.currentAssignments.isEmpty)
        }
    }
    
    private func updateMapRegion() {
        guard !viewModel.currentAssignments.isEmpty else { return }
        
        let coordinates = viewModel.currentAssignments.map { $0.coordinate }
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 40.7589
        let maxLat = latitudes.max() ?? 40.7589
        let minLon = longitudes.min() ?? -73.9851
        let maxLon = longitudes.max() ?? -73.9851
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.005, (maxLat - minLat) * 1.2),
            longitudeDelta: max(0.005, (maxLon - minLon) * 1.2)
        )
        
        mapRegion = MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Supporting Views

private struct BuildingAssignmentCard: View {
    let assignment: WorkerProfileViewModel.BuildingAssignment
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Building Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(assignment.buildingName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(assignment.buildingId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Status Badge
                HStack {
                    ProfileStatusBadge(
                        isActive: assignment.isActiveToday,
                        text: assignment.isActiveToday ? "Active Today" : "Scheduled"
                    )
                    
                    Spacer()
                }
                
                // Stats Grid
                VStack(spacing: 8) {
                    HStack {
                        ProfileStatItem(
                            icon: "list.bullet",
                            value: "\(assignment.taskCount)",
                            label: "Tasks"
                        )
                        
                        Spacer()
                        
                        ProfileStatItem(
                            icon: "clock",
                            value: formattedDuration(assignment.estimatedDuration),
                            label: "Duration"
                        )
                    }
                    
                    HStack {
                        ProfileStatItem(
                            icon: "percent",
                            value: String(format: "%.0f%%", assignment.completionRate * 100),
                            label: "Complete"
                        )
                        
                        Spacer()
                        
                        if let lastVisited = assignment.lastVisited {
                            ProfileStatItem(
                                icon: "clock.arrow.circlepath",
                                value: relativeDate(lastVisited),
                                label: "Last Visit"
                            )
                        } else {
                            ProfileStatItem(
                                icon: "questionmark.circle",
                                value: "N/A",
                                label: "Last Visit"
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Location Info
                HStack {
                    Image(systemName: "location")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.4f, %.4f", assignment.coordinate.latitude, assignment.coordinate.longitude))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
            }
            .padding()
            .frame(height: 180)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(assignment.isActiveToday ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct ProfileStatusBadge: View {
    let isActive: Bool
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
            .foregroundColor(isActive ? .green : .orange)
            .cornerRadius(8)
    }
}

private struct ProfileStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Buildings Map View

private struct ProfileBuildingsMapView: View {
    let assignments: [WorkerProfileViewModel.BuildingAssignment]
    @Binding var region: MKCoordinateRegion
    let onBuildingSelected: (WorkerProfileViewModel.BuildingAssignment) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAssignment: WorkerProfileViewModel.BuildingAssignment?
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(position: $cameraPosition) {
                    ForEach(assignments, id: \.buildingId) { assignment in
                        Annotation("", coordinate: assignment.coordinate) {
                            ProfileBuildingMapPin(
                                assignment: assignment,
                                isSelected: selectedAssignment?.buildingId == assignment.buildingId,
                                onTap: {
                                    selectedAssignment = assignment
                                }
                            )
                        }
                    }
                }
                .ignoresSafeArea()
                .onAppear {
                    cameraPosition = .region(region)
                }
                
                // Selected Building Info
                if let selected = selectedAssignment {
                    VStack {
                        Spacer()
                        
                        BuildingMapInfoCard(assignment: selected) {
                            onBuildingSelected(selected)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Building Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ProfileBuildingMapPin: View {
    let assignment: WorkerProfileViewModel.BuildingAssignment
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(assignment.isActiveToday ? Color.green : Color.orange)
                    .frame(width: isSelected ? 32 : 24, height: isSelected ? 32 : 24)
                
                Image(systemName: "building.2")
                    .font(.system(size: isSelected ? 14 : 10))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

private struct BuildingMapInfoCard: View {
    let assignment: WorkerProfileViewModel.BuildingAssignment
    let onViewDetails: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Building Info
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.buildingName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(assignment.taskCount) tasks • \(formattedDuration(assignment.estimatedDuration))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // View Details Button
            Button("Details", action: onViewDetails)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Building Detail Sheet

private struct BuildingDetailSheet: View {
    let assignment: WorkerProfileViewModel.BuildingAssignment
    let viewModel: WorkerProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Building Header
                    buildingHeaderView
                    
                    // Stats Section
                    buildingStatsView
                    
                    // Tasks Section
                    tasksListView
                }
                .padding()
            }
            .navigationTitle("Building Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var buildingHeaderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(assignment.buildingName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Building ID: \(assignment.buildingId)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.secondary)
                Text(String(format: "%.4f, %.4f", assignment.coordinate.latitude, assignment.coordinate.longitude))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var buildingStatsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                WorkerProfileStatCard(
                    title: "Total Tasks",
                    value: "\(assignment.taskCount)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                WorkerProfileStatCard(
                    title: "Estimated Time",
                    value: formattedDuration(assignment.estimatedDuration),
                    icon: "clock",
                    color: .orange
                )
                
                WorkerProfileStatCard(
                    title: "Completion Rate",
                    value: String(format: "%.0f%%", assignment.completionRate * 100),
                    icon: "percent",
                    color: .green
                )
                
                WorkerProfileStatCard(
                    title: "Status",
                    value: assignment.isActiveToday ? "Active" : "Scheduled",
                    icon: assignment.isActiveToday ? "checkmark.circle" : "clock.arrow.circlepath",
                    color: assignment.isActiveToday ? .green : .orange
                )
            }
        }
    }
    
    private var tasksListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assigned Tasks")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(assignment.tasks, id: \.taskName) { task in
                ProfileTaskRowView(task: task)
                    .padding(.vertical, 4)
            }
        }
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

private struct WorkerProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

private struct ProfileTaskRowView: View {
    let task: OperationalDataTaskAssignment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.taskName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(task.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(task.estimatedDuration) min")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(task.skillLevel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}

// MARK: - Previews

#if DEBUG && false
// Preview disabled to avoid dependency on unavailable WorkerProfileViewModel.preview()
struct ProfileAssignedBuildingsView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
            .previewLayout(.sizeThatFits)
    }
}
#endif
