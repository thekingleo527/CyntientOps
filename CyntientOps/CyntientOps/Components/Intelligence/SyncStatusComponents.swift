//
//  SyncStatusComponents.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 7/7/25.
//
//
//  SyncStatusComponents.swift
//  CyntientOps
//
//  ✅ V6.0: Phase 4.2 - Worker Feedback UI
//  ✅ Provides the visual banner and rows for real-time action confirmation.
//  ✅ Consumes data from the WorkerFeedbackManager.
//

import SwiftUI

/// A banner that displays a list of the worker's most recent actions and their sync status.
struct WorkerActionFeedbackBanner: View {
    // This view will observe the shared instance of the feedback manager.
    @StateObject private var feedbackManager = WorkerFeedbackManager.shared
    
    var body: some View {
        // Only show the banner if there are recent actions to display.
        if !feedbackManager.recentActions.isEmpty {
            VStack(spacing: 4) {
                // Display the 3 most recent actions.
                ForEach(feedbackManager.recentActions.prefix(3)) { action in
                    ActionConfirmationRow(action: action)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .shadow(radius: 5)
            .animation(.spring(), value: feedbackManager.recentActions)
        }
    }
}

/// A single row that displays the status of one worker action.
struct ActionConfirmationRow: View {
    let action: WorkerFeedbackManager.ActionConfirmation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: action.status.icon)
                .font(.headline)
                .foregroundColor(action.status.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(action.actionType.displayName) at \(action.buildingName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(action.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(action.status.displayText)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(action.status.color)
        }
    }
}

struct SyncStatusComponents_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock feedback manager for the preview
        let mockManager: () -> WorkerFeedbackManager = {
            let manager = WorkerFeedbackManager.shared
            manager.recentActions = [
                .init(id: "1", actionType: .taskCompletion, timestamp: Date().addingTimeInterval(-5), status: .synced, buildingName: "Rubin Museum"),
                .init(id: "2", actionType: .photoUpload, timestamp: Date().addingTimeInterval(-2), status: .pending, buildingName: "131 Perry St"),
                .init(id: "3", actionType: .clockIn, timestamp: Date(), status: .pending, buildingName: "131 Perry St")
            ]
            return manager
        }
        
        return ZStack {
            Color.gray.opacity(0.2).ignoresSafeArea()
            WorkerActionFeedbackBanner()
                .environmentObject(mockManager())
        }
        .preferredColorScheme(.dark)
    }
}
