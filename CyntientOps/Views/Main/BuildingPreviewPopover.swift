//
//  BuildingPreviewPopover.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: Asset names match exactly what's in Assets.xcassets
//  ✅ MAINTAINED: All existing functionality preserved
//  ✅ UPDATED: Uses consolidated WorkerContextEngine
//  ✅ ADDED: Missing button styles
//  ✅ FIXED: Unnecessary await expression
//

import SwiftUI
import Foundation
import MapKit

struct BuildingPreviewPopover: View {
    let building: CoreTypes.NamedCoordinate
    let onDetails: () -> Void
    let onDismiss: () -> Void
    
    // Using WorkerContextEngine (WorkerContextEngineAdapter is now a type alias)
    @StateObject private var contextEngine = WorkerContextEngine.shared
    @State private var tasks: [ContextualTask] = []
    @State private var openTasksCount: Int = 0
    @State private var nextSanitationDate: String?
    @State private var isLoading = true
    @State private var dismissTimer: Timer?
    
    // NEW: Operational Intelligence Data
    @State private var todayNotesCount: Int = 0
    @State private var urgentNotesCount: Int = 0
    @State private var pendingSupplyRequests: Int = 0
    @State private var lowStockAlerts: Int = 0
    @State private var activeWorkers: Int = 0
    @State private var recentVendorAccess: Int = 0
    @State private var lastWorkerNote: String = ""
    @State private var lastSupplyRequest: String = ""
    @State private var hasUrgentAlerts: Bool = false
    
    // MARK: - Asset Name Mappings (Based on actual Assets.xcassets)
    
    private let buildingAssetMap: [String: String] = [
        // Building ID to Asset Name mapping
        "1": "12_West_18th_Street",
        "2": "29_31_East_20th_Street",
        "3": "36_Walker_Street",
        "4": "41_Elizabeth_Street",
        "5": "68_Perry_Street",
        "6": "104_Franklin_Street",
        "7": "112_West_18th_Street",
        "8": "117_West_17th_Street",
        "9": "123_1st_Avenue",
        "10": "131_Perry_Street",
        "11": "133_East_15th_Street",
        "12": "135West17thStreet",        // Note: No underscores
        "13": "136_West_17th_Street",
        "14": "Rubin_Museum_142_148_West_17th_Street",
        "15": "138West17thStreet",        // Note: No underscores
        "16": "41_Elizabeth_Street",      // Reusing if same building
        "park": "Stuyvesant_Cove_Park"
    ]
    
    // Alternative mapping by building name
    private let buildingNameMap: [String: String] = [
        "12 West 18th Street": "12_West_18th_Street",
        "29-31 East 20th Street": "29_31_East_20th_Street",
        "36 Walker Street": "36_Walker_Street",
        "41 Elizabeth Street": "41_Elizabeth_Street",
        "68 Perry Street": "68_Perry_Street",
        "104 Franklin Street": "104_Franklin_Street",
        "112 West 18th Street": "112_West_18th_Street",
        "117 West 17th Street": "117_West_17th_Street",
        "123 1st Avenue": "123_1st_Avenue",
        "131 Perry Street": "131_Perry_Street",
        "133 East 15th Street": "133_East_15th_Street",
        "135 West 17th Street": "135West17thStreet",
        "136 W 17th Street": "136_West_17th_Street",
        "136 West 17th Street": "136_West_17th_Street",
        "138 West 17th Street": "138West17thStreet",
        "Rubin Museum": "Rubin_Museum_142_148_West_17th_Street",
        "Stuyvesant Cove Park": "Stuyvesant_Cove_Park"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with building image
            buildingHeader
            
            // Building info
            buildingInfo
            
            // Task and schedule info
            statusInfo
            
            // Action buttons
            actionButtons
        }
        .padding(20)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear {
            loadBuildingData()
            startDismissTimer()
        }
        .onDisappear {
            dismissTimer?.invalidate()
        }
    }
    
    // MARK: - Building Header
    
    private var buildingHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(building.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Building image
            buildingImageView
                .frame(height: 120)
                .clipped()
                .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var buildingImageView: some View {
        if let assetName = getBuildingAssetName() {
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // Fallback view with building icon
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.blue.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: getBuildingIcon())
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        Text(building.name)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 8)
                    }
                )
        }
    }
    
    private func getBuildingAssetName() -> String? {
        // Try ID mapping first
        if let assetName = buildingAssetMap[building.id] {
            return assetName
        }
        
        // Try name mapping
        if let assetName = buildingNameMap[building.name] {
            return assetName
        }
        
        // Special case for parks
        if building.name.lowercased().contains("stuyvesant") ||
           building.name.lowercased().contains("cove park") {
            return "Stuyvesant_Cove_Park"
        }
        
        // Special case for Rubin Museum
        if building.name.lowercased().contains("rubin") ||
           building.name.lowercased().contains("museum") {
            return "Rubin_Museum_142_148_West_17th_Street"
        }
        
        return nil
    }
    
    private func getBuildingIcon() -> String {
        let name = building.name.lowercased()
        
        if name.contains("museum") || name.contains("rubin") {
            return "building.columns.fill"
        } else if name.contains("park") || name.contains("stuyvesant") || name.contains("cove") {
            return "leaf.fill"
        } else if name.contains("perry") || name.contains("elizabeth") || name.contains("walker") {
            return "house.fill"
        } else if name.contains("west") || name.contains("east") || name.contains("franklin") {
            return "building.2.fill"
        } else if name.contains("avenue") {
            return "building.fill"
        } else {
            return "building.2.fill"
        }
    }
    
    // MARK: - Building Info (UNCHANGED)
    
    private var buildingInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Building address - address is non-optional String in CoreTypes
            // Only show if not empty
            if !building.address.isEmpty {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(building.address)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
            }
            
            // Building ID
            HStack {
                Image(systemName: "building.2")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("Building ID: \(building.id)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Coordinates for reference
            HStack {
                Image(systemName: "globe")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(String(format: "%.4f", building.latitude)), \(String(format: "%.4f", building.longitude))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    // MARK: - Status Info (UNCHANGED)
    
    private var statusInfo: some View {
        VStack(spacing: 12) {
            Divider()
                .background(Color.white.opacity(0.2))
            
            if isLoading {
                loadingStatusView
            } else {
                loadedStatusView
            }
        }
    }
    
    private var loadingStatusView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("Loading building status...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
        }
    }
    
    private var loadedStatusView: some View {
        VStack(spacing: 8) {
            // Active Workers & Tasks Row
            HStack {
                Image(systemName: activeWorkers > 0 ? "person.fill" : "person")
                    .font(.caption)
                    .foregroundColor(activeWorkers > 0 ? .green : .gray)
                
                Text("\(activeWorkers) active • \(openTasksCount) tasks")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                if openTasksCount > 0 {
                    Circle()
                        .fill(openTasksCount > 3 ? Color.red : Color.orange)
                        .frame(width: 8, height: 8)
                }
            }
            
            // Operational Intelligence Row
            HStack(spacing: 12) {
                // Notes indicator
                if todayNotesCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: urgentNotesCount > 0 ? "exclamationmark.triangle.fill" : "note.text")
                            .font(.caption2)
                            .foregroundColor(urgentNotesCount > 0 ? .red : .blue)
                        
                        Text("\(todayNotesCount)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                }
                
                // Supply requests indicator
                if pendingSupplyRequests > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "box")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        
                        Text("\(pendingSupplyRequests)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                }
                
                // Low stock alerts
                if lowStockAlerts > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        
                        Text("\(lowStockAlerts)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                }
                
                // Vendor access indicator
                if recentVendorAccess > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "key.fill")
                            .font(.caption2)
                            .foregroundColor(.purple)
                        
                        Text("\(recentVendorAccess)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                }
                
                Spacer()
            }
            
            // Latest Activity Row
            if !lastWorkerNote.isEmpty || !lastSupplyRequest.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    if !lastWorkerNote.isEmpty {
                        HStack {
                            Image(systemName: "quote.bubble")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            
                            Text(lastWorkerNote)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                            
                            Spacer()
                        }
                    }
                    
                    if !lastSupplyRequest.isEmpty {
                        HStack {
                            Image(systemName: "box.truck")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            
                            Text(lastSupplyRequest)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            // Sanitation schedule (moved to bottom)
            if let sanitationDate = nextSanitationDate {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    Text("Next sanitation: \(sanitationDate)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
            
            // Task completion stats
            if !tasks.isEmpty {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    Text("\(completedTasksCount)/\(tasks.count) completed today")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Action Buttons (UNCHANGED)
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Details") {
                onDetails()
            }
            .buttonStyle(PrimaryPreviewButtonStyle())
            
            Button("Dismiss") {
                onDismiss()
            }
            .buttonStyle(SecondaryPreviewButtonStyle())
        }
    }
    
    // MARK: - Real Data Loading with Operational Intelligence
    
    private func loadBuildingData() {
        Task {
            // Load real task data for this building
            let allTasks = WorkerContextEngine.shared.getTodaysTasks()
            
            // ✅ FIXED: Use buildingId instead of buildingName
            let buildingTasks = allTasks.filter { task in
                task.buildingId == building.id
            }
            
            // Filter open tasks using TaskStatus enum
            let openTasks = buildingTasks.filter { task in
                task.status != .completed && task.status != .cancelled
            }
            
            // Find next sanitation task
            let sanitationTasks = buildingTasks.filter { task in
                task.category == .sanitation ||
                task.title.lowercased().contains("sanitation") ||
                task.title.lowercased().contains("dsny") ||
                task.title.lowercased().contains("trash")
            }
            
            let nextSanitation = sanitationTasks.first { task in
                task.status != .completed && task.status != .cancelled
            }
            
            // Load operational intelligence data
            await loadOperationalIntelligence()
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.6)) {
                    self.tasks = allTasks
                    openTasksCount = openTasks.count
                    
                    if let next = nextSanitation {
                        // Use dueDate if available, otherwise just show "Today"
                        if let dueDate = next.dueDate {
                            let formatter = DateFormatter()
                            formatter.timeStyle = .short
                            let time = formatter.string(from: dueDate)
                            nextSanitationDate = "Today \(time)"
                        } else {
                            nextSanitationDate = "Today"
                        }
                    } else {
                        nextSanitationDate = nil
                    }
                    
                    isLoading = false
                }
            }
        }
    }
    
    private func loadOperationalIntelligence() async {
        do {
            // Load today's worker notes for this building
            let todayStart = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
            
            let notesRows = try await GRDBManager.shared.query("""
                SELECT * FROM daily_notes 
                WHERE building_id = ? 
                AND timestamp >= ? 
                AND timestamp < ?
                ORDER BY timestamp DESC
            """, [building.id, todayStart.ISO8601Format(), tomorrow.ISO8601Format()])
            
            let totalNotes = notesRows.count
            let urgentNotes = notesRows.filter { row in
                let category = row["category"] as? String ?? ""
                return category == "Safety Concern" || category == "Maintenance Issue"
            }.count
            
            // Get most recent note preview
            let latestNote = notesRows.first.flatMap { row in
                let noteText = row["note_text"] as? String ?? ""
                let workerName = row["worker_name"] as? String ?? ""
                return noteText.isEmpty ? "" : "\(workerName): \(noteText)"
            } ?? ""
            
            // Load pending supply requests for this building
            let supplyRows = try await InventoryService.shared.getSupplyRequests(for: building.id, status: "pending")
            let pendingSupplies = supplyRows.count
            
            // Get most recent supply request
            let latestSupplyRequest = supplyRows.first.flatMap { row in
                let requesterName = row["requester_name"] as? String ?? "Worker"
                return "Recent supply request by \(requesterName)"
            } ?? ""
            
            // Load low stock alerts for this building
            let alertsRows = try await InventoryService.shared.getActiveAlerts(for: building.id)
            let lowStockCount = alertsRows.count
            
            // Load active workers for this building (from clock-in status)
            let workersRows = try await GRDBManager.shared.query("""
                SELECT COUNT(DISTINCT worker_id) as worker_count
                FROM clock_entries 
                WHERE building_id = ? 
                AND action = 'clock_in'
                AND DATE(created_at) = DATE('now')
                AND worker_id NOT IN (
                    SELECT worker_id FROM clock_entries 
                    WHERE building_id = ? 
                    AND action = 'clock_out' 
                    AND DATE(created_at) = DATE('now')
                    AND created_at > (
                        SELECT MAX(created_at) FROM clock_entries 
                        WHERE building_id = ? 
                        AND action = 'clock_in' 
                        AND DATE(created_at) = DATE('now')
                    )
                )
            """, [building.id, building.id, building.id])
            
            let activeWorkerCount = Int(workersRows.first?["worker_count"] as? Int64 ?? 0)
            
            // Load recent vendor access (last 24 hours)
            let yesterday = Date().addingTimeInterval(-24 * 60 * 60)
            let vendorRows = try await GRDBManager.shared.query("""
                SELECT COUNT(*) as vendor_count
                FROM vendor_access_logs 
                WHERE building_id = ? 
                AND timestamp >= ?
            """, [building.id, yesterday.ISO8601Format()])
            
            let recentVendorCount = Int(vendorRows.first?["vendor_count"] as? Int64 ?? 0)
            
            // Check for urgent alerts
            let hasUrgent = urgentNotes > 0 || lowStockCount > 0
            
            await MainActor.run {
                self.todayNotesCount = totalNotes
                self.urgentNotesCount = urgentNotes
                self.pendingSupplyRequests = pendingSupplies
                self.lowStockAlerts = lowStockCount
                self.activeWorkers = activeWorkerCount
                self.recentVendorAccess = recentVendorCount
                self.lastWorkerNote = latestNote.prefix(40) + (latestNote.count > 40 ? "..." : "")
                self.lastSupplyRequest = latestSupplyRequest
                self.hasUrgentAlerts = hasUrgent
            }
            
        } catch {
            logInfo("⚠️ Failed to load operational intelligence for building \(building.id): \(error)")
            
            // Set defaults on error
            await MainActor.run {
                self.todayNotesCount = 0
                self.urgentNotesCount = 0
                self.pendingSupplyRequests = 0
                self.lowStockAlerts = 0
                self.activeWorkers = 0
                self.recentVendorAccess = 0
                self.lastWorkerNote = ""
                self.lastSupplyRequest = ""
                self.hasUrgentAlerts = false
            }
        }
    }
    
    private var completedTasksCount: Int {
        tasks.filter { $0.status == .completed }.count
    }
    
    private func startDismissTimer() {
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                onDismiss()
            }
        }
    }
}

// MARK: - Button Styles

struct PrimaryPreviewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.blue.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryPreviewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview Provider

struct BuildingPreviewPopover_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Rubin Museum preview
                BuildingPreviewPopover(
                    building: CoreTypes.NamedCoordinate(
                        id: "14",
                        name: "Rubin Museum",
                        address: "150 W 17th St, New York, NY 10011",
                        latitude: 40.7402,
                        longitude: -73.9979
                    ),
                    onDetails: {
                        logInfo("Show Rubin Museum details")
                    },
                    onDismiss: {
                        logInfo("Dismiss popover")
                    }
                )
                
                // Stuyvesant Cove Park preview
                BuildingPreviewPopover(
                    building: CoreTypes.NamedCoordinate(
                        id: "park",
                        name: "Stuyvesant Cove Park",
                        address: "E 20th St & FDR Dr, New York, NY 10009",
                        latitude: 40.7325,
                        longitude: -73.9732
                    ),
                    onDetails: {
                        logInfo("Show park details")
                    },
                    onDismiss: {
                        logInfo("Dismiss popover")
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}
