///
//  WorkerFeedbackManager.swift
//  CyntientOps
//
//  ✅ V6.0: Phase 2.3 - Worker Feedback Loop
//  ✅ Provides immediate UI confirmation to workers for their actions.
//  ✅ Manages the state of pending, synced, and failed actions.
//  ✅ REVISED: Works directly with WorkerEventOutbox
//

import Foundation
import SwiftUI
import Combine

/// An observable object that provides real-time feedback to the worker about the status of their actions.
@MainActor
class WorkerFeedbackManager: ObservableObject {
    static let shared = WorkerFeedbackManager()

    /// Represents the confirmation status of a single worker action.
    struct ActionConfirmation: Identifiable, Equatable {
        let id: String
        let actionType: WorkerActionType
        let timestamp: Date
        var status: ConfirmationStatus
        let buildingName: String
        
        static func == (lhs: ActionConfirmation, rhs: ActionConfirmation) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    /// The possible states for an action confirmation.
    enum ConfirmationStatus: String {
        case pending, synced, failed
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .synced: return .green
            case .failed: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "hourglass"
            case .synced: return "checkmark.circle.fill"
            case .failed: return "exclamationmark.triangle.fill"
            }
        }
        
        var displayText: String {
            self.rawValue.capitalized
        }
    }

    @Published var recentActions: [ActionConfirmation] = []
    @Published var pendingCount: Int = 0
    @Published var isSyncing = false
    
    private var syncCheckTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Start periodic sync status checks
        startSyncStatusMonitoring()
    }

    /// Called immediately when a worker performs an action. This provides instant UI feedback.
    func recordAction(type: WorkerActionType, buildingName: String, actionId: String) async {
        print("👍 Recording action for immediate feedback: \(type.feedbackDisplayName)")
        
        let confirmation = ActionConfirmation(
            id: actionId,
            actionType: type,
            timestamp: Date(),
            status: .pending,
            buildingName: buildingName
        )
        
        // Insert at the top and limit the list to the 5 most recent actions.
        recentActions.insert(confirmation, at: 0)
        if recentActions.count > 5 {
            recentActions.removeLast()
        }
        
        updatePendingCount()
        
        // Trigger sync after adding action
        await triggerSync()
    }
    
    /// Start monitoring sync status
    private func startSyncStatusMonitoring() {
        // Check sync status every 2 seconds when there are pending actions
        Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.checkSyncStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Check if any pending actions have been synced
    private func checkSyncStatus() async {
        guard !recentActions.isEmpty else { return }
        
        // Get current pending event count from outbox
        let outboxPendingCount = await WorkerEventOutbox.shared.getPendingEventCount()
        
        // If outbox has fewer pending events than we have pending confirmations,
        // some events must have been synced
        let ourPendingCount = recentActions.filter { $0.status == .pending }.count
        
        if outboxPendingCount < ourPendingCount {
            // Mark oldest pending actions as synced
            var syncedCount = ourPendingCount - outboxPendingCount
            
            for (index, action) in recentActions.enumerated().reversed() {
                if action.status == .pending && syncedCount > 0 {
                    print("✅ Marking action as synced: \(action.actionType.feedbackDisplayName)")
                    recentActions[index].status = .synced
                    syncedCount -= 1
                }
            }
            
            updatePendingCount()
        }
    }
    
    /// Trigger the outbox to attempt syncing
    private func triggerSync() async {
        guard !isSyncing else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        await WorkerEventOutbox.shared.attemptFlush()
        
        // Check sync status after flush attempt
        await checkSyncStatus()
    }
    
    /// Mark an action as failed
    func markActionFailed(actionId: String) {
        if let index = recentActions.firstIndex(where: { $0.id == actionId }) {
            print("❌ Marking action as failed: \(recentActions[index].actionType.feedbackDisplayName)")
            recentActions[index].status = .failed
            updatePendingCount()
        }
    }
    
    /// Retry a failed action
    func retryAction(_ actionId: String) {
        if let index = recentActions.firstIndex(where: { $0.id == actionId && $0.status == .failed }) {
            print("🔄 Retrying action: \(recentActions[index].actionType.feedbackDisplayName)")
            recentActions[index].status = .pending
            updatePendingCount()
            
            // Trigger a sync attempt
            Task {
                await triggerSync()
            }
        }
    }
    
    /// Clear all completed actions
    func clearCompletedActions() {
        recentActions.removeAll { $0.status == .synced }
        updatePendingCount()
    }
    
    /// Force sync all pending actions
    func syncNow() async {
        await triggerSync()
    }
    
    /// Updates the count of actions that are still waiting to be synced.
    private func updatePendingCount() {
        pendingCount = recentActions.filter { $0.status == .pending }.count
    }
    
    /// Get a summary of action statuses
    var actionSummary: (pending: Int, synced: Int, failed: Int) {
        let pending = recentActions.filter { $0.status == .pending }.count
        let synced = recentActions.filter { $0.status == .synced }.count
        let failed = recentActions.filter { $0.status == .failed }.count
        return (pending, synced, failed)
    }
    
    /// Get sync status text
    var syncStatusText: String {
        if isSyncing {
            return "Syncing..."
        } else if pendingCount > 0 {
            return "\(pendingCount) pending"
        } else {
            return "All synced"
        }
    }
}

// MARK: - WorkerActionType Extension

extension WorkerActionType {
    var feedbackDisplayName: String {
        switch self {
        case .taskComplete, .taskCompletion:
            return "Task Completed"
        case .clockIn:
            return "Clocked In"
        case .clockOut:
            return "Clocked Out"
        case .photoUpload:
            return "Photo Uploaded"
        case .commentUpdate:
            return "Comment Added"
        case .routineInspection:
            return "Routine Inspection"
        case .buildingStatusUpdate:
            return "Building Status Updated"
        case .emergencyReport:
            return "Emergency Reported"
        }
    }
}

// MARK: - UI Component for displaying feedback

struct WorkerFeedbackView: View {
    @ObservedObject var feedbackManager = WorkerFeedbackManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Label("Recent Actions", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                
                Spacer()
                
                if feedbackManager.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                Text(feedbackManager.syncStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Action list
            if feedbackManager.recentActions.isEmpty {
                Text("No recent actions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(feedbackManager.recentActions) { action in
                    ActionRow(action: action)
                }
            }
            
            // Summary
            if feedbackManager.pendingCount > 0 {
                Button(action: {
                    Task {
                        await feedbackManager.syncNow()
                    }
                }) {
                    Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct ActionRow: View {
    let action: WorkerFeedbackManager.ActionConfirmation
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: action.status.icon)
                .foregroundColor(action.status.color)
                .frame(width: 20)
            
            // Action details
            VStack(alignment: .leading, spacing: 2) {
                Text(action.actionType.feedbackDisplayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(action.buildingName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Timestamp
            Text(timeAgo(from: action.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // Retry button for failed actions
            if action.status == .failed {
                Button(action: {
                    WorkerFeedbackManager.shared.retryAction(action.id)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}

// MARK: - Preview

#Preview("Worker Feedback View") {
    WorkerFeedbackView()
        .frame(maxWidth: 400)
        .padding()
}
