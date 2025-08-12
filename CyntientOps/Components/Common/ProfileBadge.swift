//
//  ProfileBadge.swift
//  CyntientOps v6.0
//
//  ✅ INTEGRATED: With DashboardSyncService for real-time updates
//  ✅ ALIGNED: With three-dashboard architecture
//  ✅ CONNECTED: To worker status and Nova AI
//  ✅ SIMPLIFIED: Focused on essential features
//  ✅ FIXED: All compilation and logic errors resolved.
//

import SwiftUI
import Combine
import GRDB

// MARK: - ProfileBadge Component

public struct ProfileBadge: View {
    // MARK: - Core Properties
    let worker: CoreTypes.WorkerProfile
    let size: BadgeSize
    let context: DashboardContext
    let onTap: () -> Void

    // MARK: - State
    @State private var isPressed = false
    @State private var pulseAnimation = false
    
    // This dedicated StateObject monitors the specific worker's status.
    @StateObject private var statusMonitor: WorkerStatusMonitor
    
    // MARK: - Initialization
    public init(
        worker: CoreTypes.WorkerProfile,
        size: BadgeSize = .standard,
        context: DashboardContext = .worker,
        onTap: @escaping () -> Void = {}
    ) {
        self.worker = worker
        self.size = size
        self.context = context
        self.onTap = onTap
        // Initialize the StateObject with the worker's ID.
        self._statusMonitor = StateObject(wrappedValue: WorkerStatusMonitor(workerId: worker.id))
    }
    
    // MARK: - Computed Properties
    
    private var displaySize: CGFloat {
        switch size {
        case .compact: return 32
        case .standard: return 44
        case .large: return 56
        }
    }
    
    private var initials: String {
        // ✅ FIXED: Robustly handles names with single or multiple parts.
        let components = worker.name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard let first = components.first?.first else { return "?" }
        
        if components.count > 1, let last = components.last?.first {
            return "\(first)\(last)".uppercased()
        }
        return String(first).uppercased()
    }
    
    private var gradientColors: [Color] {
        switch context {
        case .worker:
            return [CyntientOpsDesign.DashboardColors.workerPrimary, CyntientOpsDesign.DashboardColors.workerSecondary]
        case .admin:
            return [CyntientOpsDesign.DashboardColors.adminPrimary, CyntientOpsDesign.DashboardColors.adminSecondary]
        case .client:
            return [CyntientOpsDesign.DashboardColors.clientPrimary, CyntientOpsDesign.DashboardColors.clientSecondary]
        case .building(let id):
            let hash = id.hashValue
            let hue = Double(abs(hash) % 360) / 360.0
            return [Color(hue: hue, saturation: 0.6, brightness: 0.8), Color(hue: hue, saturation: 0.4, brightness: 0.6)]
        }
    }
    
    private var showStatusDot: Bool {
        switch context {
        case .admin, .building, .worker:
            return size != .compact
        case .client:
            return false
        }
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: handleTap) {
            ZStack {
                Circle().fill(.ultraThinMaterial).overlay(glassOverlay)
                profileContent
                if showStatusDot { statusIndicator }
                if statusMonitor.hasNovaAlert && context == .worker { novaIndicator }
                if context == .admin && statusMonitor.activeTaskCount > 0 { taskCountBadge }
            }
            .frame(width: displaySize, height: displaySize)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0.5,
            pressing: { pressing in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
        .onChange(of: statusMonitor.currentStatus) { oldValue, newValue in
            if newValue == .clockedIn && !pulseAnimation {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            } else if newValue != .clockedIn {
                pulseAnimation = false
            }
        }
    }
    
    // MARK: - View Components
    
    private var glassOverlay: some View {
        Circle().stroke(
            LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
            lineWidth: 1
        )
    }
    
    @ViewBuilder
    private var profileContent: some View {
        if let imageUrl = worker.profileImageUrl {
            AsyncImage(url: imageUrl) { image in
                image.resizable().aspectRatio(contentMode: .fill).clipShape(Circle())
            } placeholder: {
                initialsView
            }
        } else {
            initialsView
        }
    }
    
    private var initialsView: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
            
            if pulseAnimation && statusMonitor.currentStatus == .clockedIn {
                Circle()
                    .stroke(gradientColors[0], lineWidth: 2)
                    .scaleEffect(pulseAnimation ? 1.4 : 1.0)
                    .opacity(pulseAnimation ? 0 : 1.0)
            }
            
            Text(initials)
                .font(.system(size: displaySize * 0.4, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
    
    private var statusIndicator: some View {
        Circle()
            .fill(CyntientOpsDesign.EnumColors.workerStatus(statusMonitor.currentStatus))
            .frame(width: displaySize * 0.25, height: displaySize * 0.25)
            .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 1))
            .offset(x: displaySize * 0.35, y: displaySize * 0.35)
    }
    
    private var novaIndicator: some View {
        Image(systemName: "sparkle")
            .font(.system(size: displaySize * 0.3))
            .foregroundColor(.yellow)
            .background(Circle().fill(Color.black.opacity(0.6)).padding(-2))
            .offset(x: -displaySize * 0.3, y: -displaySize * 0.3)
            .transition(.scale.combined(with: .opacity))
    }
    
    private var taskCountBadge: some View {
        Text("\(statusMonitor.activeTaskCount)")
            .font(.system(size: displaySize * 0.25, weight: .bold))
            .foregroundColor(.white)
            .padding(displaySize * 0.1)
            .background(Circle().fill(Color.red))
            .offset(x: displaySize * 0.3, y: -displaySize * 0.3)
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        HapticManager.impact(.light)
        onTap()
    }
}

// MARK: - Supporting Types

public enum BadgeSize {
    case compact, standard, large
}

public enum DashboardContext: Equatable { // ✅ FIXED: Conformance added
    case worker
    case admin
    case client
    case building(String)
}

// MARK: - Worker Status Monitor

@MainActor
class WorkerStatusMonitor: ObservableObject {
    @Published var currentStatus: CoreTypes.WorkerStatus = .offline
    @Published var activeTaskCount: Int = 0
    @Published var hasNovaAlert = false
    
    private var cancellables = Set<AnyCancellable>()
    private let workerId: String
    
    init(workerId: String) {
        self.workerId = workerId
        setupMonitoring()
    }
    
    private func setupMonitoring() {
        // Initial status check
        Task { await checkWorkerStatus() }
        
        // Periodic refresh
        Timer.publish(every: 30, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                Task { await self?.checkWorkerStatus() }
            }
            .store(in: &cancellables)
            
        // ✅ FIXED: Correct Combine publisher assignment
        DashboardSyncService.shared.workerDashboardUpdates
            .filter { $0.workerId == self.workerId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleDashboardUpdate(update)
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: .novaAlertForWorker)
            .compactMap { $0.userInfo?["workerId"] as? String }
            .filter { $0 == self.workerId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.triggerNovaAlert()
            }
            .store(in: &cancellables)
    }
    
    private func handleDashboardUpdate(_ update: CoreTypes.DashboardUpdate) {
        if let statusString = update.data["status"], let status = CoreTypes.WorkerStatus(rawValue: statusString) {
            self.currentStatus = status
        }
        if let taskCountString = update.data["activeTaskCount"], let count = Int(taskCountString) {
            self.activeTaskCount = count
        }
    }
    
    private func triggerNovaAlert() {
        withAnimation {
            hasNovaAlert = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation {
                self.hasNovaAlert = false
            }
        }
    }
    
    private func checkWorkerStatus() async {
        do {
            let sessions = try await GRDBManager.shared.query("SELECT * FROM clock_sessions WHERE worker_id = ? AND clock_out_time IS NULL ORDER BY clock_in_time DESC LIMIT 1", [workerId])
            
            if !sessions.isEmpty {
                currentStatus = .clockedIn
                let tasks = try await GRDBManager.shared.query("SELECT COUNT(*) as count FROM routine_tasks WHERE workerId = ? AND isCompleted = 0 AND DATE(scheduledDate) = DATE('now')", [workerId])
                activeTaskCount = Int(tasks.first?["count"] as? Int64 ?? 0)
            } else {
                currentStatus = .available
                activeTaskCount = 0
            }
        } catch {
            print("❌ Error checking worker status for \(workerId): \(error)")
            currentStatus = .offline
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let novaAlertForWorker = Notification.Name("novaAlertForWorker")
}

// MARK: - Preview

struct ProfileBadge_Previews: PreviewProvider {
    static let sampleWorker = CoreTypes.WorkerProfile(id: "4", name: "Kevin Dutan", email: "kevin@cyntientops.com", role: .worker)
    
    static var previews: some View {
        VStack(spacing: 32) {
            HStack(spacing: 16) {
                ProfileBadge(worker: sampleWorker, size: .large, context: .worker) {}
                ProfileBadge(worker: sampleWorker, size: .standard, context: .admin) {}
                ProfileBadge(worker: sampleWorker, size: .compact, context: .building("14")) {}
            }
            .padding()
            .background(Color.black.opacity(0.8))
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .preferredColorScheme(.dark)
        .environmentObject(DashboardSyncService.shared)
    }
}
