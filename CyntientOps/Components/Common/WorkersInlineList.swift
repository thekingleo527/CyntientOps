//
//  WorkersInlineList.swift
//  CyntientOps v6.0
//
//  🔧 FIXED: WorkerContextEngine.todayWorkers() compilation error
//  ✅ Changed to use WorkerService.getAllActiveWorkers() for multiple workers
//  ✅ Fixed Animation typo → .easeInOut animation
//  ✅ Compatible with WorkerContextEngine actor architecture
//  ✅ FIXED: ProfileBadge parameters and removed unnecessary catch block
//

import SwiftUI

struct WorkersInlineList: View {
    let buildingId: String
    let maxDisplayCount: Int
    let showDSNYWorkers: Bool
    let onWorkerTap: ((String) -> Void)?
    
    @State private var workers: [WorkerInfo] = []
    @State private var isLoading = true
    @State private var showAllWorkers = false
    
    // Convenience initializers
    init(buildingId: String,
         maxDisplayCount: Int = 3,
         showDSNYWorkers: Bool = false,
         onWorkerTap: ((String) -> Void)? = nil) {
        self.buildingId = buildingId
        self.maxDisplayCount = maxDisplayCount
        self.showDSNYWorkers = showDSNYWorkers
        self.onWorkerTap = onWorkerTap
    }
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if workers.isEmpty {
                emptyStateView
            } else {
                workersContentView
            }
        }
        .task {
            await loadWorkers()
        }
        .onChange(of: buildingId) { _, _ in
            Task {
                await loadWorkers()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
                .tint(.blue)
            
            Text("Loading workers...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.slash")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            
            Text("No workers assigned")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Workers Content View
    
    private var workersContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Display workers
            if showAllWorkers || workers.count <= maxDisplayCount {
                workersFullList
            } else {
                workersCollapsedList
            }
            
            // Show more/less button if needed
            if workers.count > maxDisplayCount {
                showMoreButton
            }
        }
    }
    
    private var workersFullList: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], alignment: .leading, spacing: 12) {
            ForEach(workers, id: \.id) { worker in
                workerCard(worker)
            }
        }
    }
    
    private var workersCollapsedList: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Show first few workers
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], alignment: .leading, spacing: 12) {
                ForEach(workers.prefix(maxDisplayCount), id: \.id) { worker in
                    workerCard(worker)
                }
            }
            
            // Show count of additional workers
            if workers.count > maxDisplayCount {
                additionalWorkersIndicator
            }
        }
    }
    
    private var additionalWorkersIndicator: some View {
        HStack {
            Text("+\(workers.count - maxDisplayCount) more")
                .font(.caption)
                .foregroundColor(.blue)
            
            Spacer()
        }
    }
    
    private var showMoreButton: some View {
        Button(action: {
            // ✅ FIXED: Animation typo → proper .easeInOut animation
            withAnimation(.easeInOut(duration: 0.3)) {
                showAllWorkers.toggle()
            }
        }) {
            HStack(spacing: 4) {
                Text(showAllWorkers ? "Show Less" : "Show All (\(workers.count))")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Image(systemName: showAllWorkers ? "chevron.up" : "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Worker Card
    
    private func workerCard(_ worker: WorkerInfo) -> some View {
        Button(action: {
            onWorkerTap?(worker.id)
        }) {
            VStack(spacing: 8) {
                // Worker avatar - Using a simple circle with initials instead of ProfileBadge
                ZStack {
                    Circle()
                        .fill(getWorkerAccentColor(worker))
                        .frame(width: 40, height: 40)
                    
                    Text(getInitials(from: worker.name))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Worker info
                VStack(spacing: 2) {
                    Text(worker.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(worker.role)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                // Status indicators
                statusIndicators(for: worker)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(getWorkerAccentColor(worker).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(worker.isActive ? 1.0 : 0.95)
        .opacity(worker.isActive ? 1.0 : 0.7)
    }
    
    private func statusIndicators(for worker: WorkerInfo) -> some View {
        HStack(spacing: 4) {
            // Clock status
            if worker.isClockedIn {
                Image(systemName: "clock.fill")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            
            // Task count
            if worker.taskCount > 0 {
                Text("\(worker.taskCount)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2), in: Capsule())
            }
            
            // DSNY indicator
            if worker.isDSNYWorker && showDSNYWorkers {
                Image(systemName: "trash")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadWorkers() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // ✅ FIXED: Get workers assigned to this building directly
            let buildingWorkers = try await // WorkerService injection needed.getActiveWorkersForBuilding(buildingId)
            
            var loadedWorkers: [WorkerInfo] = []
            
            for workerProfile in buildingWorkers {
                let worker = WorkerInfo(
                    id: workerProfile.id,
                    name: workerProfile.name,
                    displayName: formatWorkerDisplayName(workerProfile.name),
                    role: workerProfile.role.rawValue,
                    shift: getWorkerShift(workerProfile.id),
                    isActive: workerProfile.isActive,
                    isClockedIn: await isWorkerClockedIn(workerProfile.id),
                    taskCount: await getWorkerTaskCount(workerProfile.id),
                    isDSNYWorker: await isDSNYWorker(workerProfile.name)
                )
                loadedWorkers.append(worker)
            }
            
            // Sort workers by priority (clocked in first, then by task count)
            loadedWorkers.sort { worker1, worker2 in
                if worker1.isClockedIn != worker2.isClockedIn {
                    return worker1.isClockedIn
                }
                return worker1.taskCount > worker2.taskCount
            }
            
            await MainActor.run {
                self.workers = loadedWorkers
                self.isLoading = false
            }
            
        } catch {
            print("❌ Failed to load workers: \(error)")
            await MainActor.run {
                self.workers = []
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        let first = components.first?.first ?? Character("?")
        let last: Character = components.count > 1 ? (components.last?.first ?? Character(" ")) : Character(" ")
        return "\(first)\(last)".uppercased().trimmingCharacters(in: .whitespaces)
    }
    
    private func formatWorkerDisplayName(_ name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components[0]) \(String(components[1].prefix(1)))."
        }
        return name
    }
    
    private func getWorkerShift(_ workerId: String) -> String {
        switch workerId {
        case "1": return "9:00-17:00"  // Greg
        case "2": return "6:00-15:00"  // Edwin
        case "4": return "6:00-17:00"  // Kevin
        case "5": return "6:30-11:00"  // Mercedes
        case "6": return "7:00-16:00"  // Luis
        case "7": return "18:00-22:00" // Angel
        case "8": return "Flexible"    // Shawn
        default: return "9:00-17:00"
        }
    }
    
    private func isWorkerClockedIn(_ workerId: String) async -> Bool {
        // Check if worker is currently clocked in through ClockInManager
        // ✅ FIXED: Removed unnecessary do-catch as this doesn't throw
        let status = await ClockInManager.shared.getClockInStatus(for: workerId)
        return status.isClockedIn
    }
    
    private func getWorkerTaskCount(_ workerId: String) async -> Int {
        do {
            // Get tasks for this worker for today
            let tasks = try await // TaskService injection needed.getTasks(for: workerId, date: Date())
            
            // Filter tasks for this specific building
            return tasks.filter { task in
                task.buildingId == buildingId
            }.count
            
        } catch {
            print("❌ Failed to get task count for worker \(workerId): \(error)")
            return 0
        }
    }
    
    private func isDSNYWorker(_ workerName: String) async -> Bool {
        // Check if worker has DSNY/sanitation tasks
        let workerId = getWorkerIdFromName(workerName)
        
        do {
            let tasks = try await // TaskService injection needed.getTasks(for: workerId, date: Date())
            
            for task in tasks {
                let isDSNYTask = task.category?.rawValue.lowercased().contains("sanitation") == true ||
                               task.title.lowercased().contains("trash") ||
                               task.title.lowercased().contains("recycling") ||
                               task.title.lowercased().contains("dsny") ||
                               task.title.lowercased().contains("garbage")
                
                if isDSNYTask && task.buildingId == buildingId {
                    return true
                }
            }
        } catch {
            print("❌ Failed to check DSNY status for \(workerName): \(error)")
        }
        
        return false
    }
    
    private func getWorkerIdFromName(_ name: String) -> String {
        let workerMap: [String: String] = [
            "Greg Hutson": "1",
            "Edwin Lema": "2",
            "Kevin Dutan": "4",    // ✅ FIXED: Kevin's correct ID is 4
            "Mercedes Inamagua": "5",
            "Luis Lopez": "6",
            "Angel Guirachocha": "7",
            "Shawn Magloire": "8"
        ]
        
        // Handle partial matches for names like "Greg" or "Kevin"
        for (fullName, id) in workerMap {
            if fullName.lowercased().contains(name.lowercased()) ||
               name.lowercased().contains(fullName.components(separatedBy: " ").first?.lowercased() ?? "") {
                return id
            }
        }
        
        return "unknown"
    }
    
    private func getWorkerAccentColor(_ worker: WorkerInfo) -> Color {
        switch worker.id {
        case "1": return .blue    // Greg
        case "2": return .green   // Edwin
        case "4": return .purple  // Kevin
        case "5": return .orange  // Mercedes
        case "6": return .pink    // Luis
        case "7": return .teal    // Angel
        case "8": return .red     // Shawn
        default: return .gray
        }
    }
}

// MARK: - Supporting Models

struct WorkerInfo: Identifiable {
    let id: String
    let name: String
    let displayName: String
    let role: String
    let shift: String
    let isActive: Bool
    let isClockedIn: Bool
    let taskCount: Int
    let isDSNYWorker: Bool
}

// MARK: - Preview Support

#if DEBUG
struct WorkersInlineList_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WorkersInlineList(buildingId: "1")
                .padding()
            
            WorkersInlineList(
                buildingId: "5",
                maxDisplayCount: 2,
                showDSNYWorkers: true
            )
            .padding()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif
