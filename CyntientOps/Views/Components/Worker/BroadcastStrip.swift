import SwiftUI
import Combine

struct BroadcastStrip: View {
    @EnvironmentObject private var dashboardSync: DashboardSyncService

    @State private var latest: CoreTypes.DashboardUpdate?
    @State private var cancellable: AnyCancellable?

    var body: some View {
        Group {
            if let update = latest {
                HStack(spacing: 8) {
                    Image(systemName: icon(for: update))
                    Text(message(for: update))
                        .lineLimit(1)
                        .font(.caption)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color(for: update).opacity(0.15))
                .foregroundColor(color(for: update))
                .cornerRadius(8)
                .transition(.opacity)
            }
        }
        .onAppear { subscribe() }
        .onDisappear { cancellable?.cancel() }
    }

    private func subscribe() {
        // Merge cross dashboard and worker-specific updates
        cancellable = dashboardSync.crossDashboardUpdates
            .merge(with: dashboardSync.workerDashboardUpdates)
            .receive(on: RunLoop.main)
            .sink { update in
                // Show only actionable/high-priority summaries
                switch update.type {
                case .criticalAlert, .complianceStatusChanged, .workerClockedIn, .workerClockedOut, .taskCompleted, .buildingUpdate:
                    latest = update
                default:
                    break
                }
            }
    }

    private func color(for update: CoreTypes.DashboardUpdate) -> Color {
        switch update.type {
        case .criticalAlert, .complianceStatusChanged:
            return .red
        case .taskCompleted:
            return .green
        case .workerClockedIn, .workerClockedOut, .buildingUpdate:
            return .blue
        default:
            return .gray
        }
    }

    private func icon(for update: CoreTypes.DashboardUpdate) -> String {
        switch update.type {
        case .criticalAlert: return "exclamationmark.triangle.fill"
        case .complianceStatusChanged: return "checkmark.shield.fill"
        case .taskCompleted: return "checkmark.circle.fill"
        case .workerClockedIn: return "clock.fill"
        case .workerClockedOut: return "clock"
        case .buildingUpdate: return "building.2.fill"
        default: return "info.circle.fill"
        }
    }

    private func message(for update: CoreTypes.DashboardUpdate) -> String {
        if let desc = update.description, !desc.isEmpty { return desc }
        switch update.type {
        case .criticalAlert: return "Critical alert received"
        case .complianceStatusChanged: return "Compliance status updated"
        case .taskCompleted: return "Task completed"
        case .workerClockedIn: return "Worker clocked in"
        case .workerClockedOut: return "Worker clocked out"
        case .buildingUpdate: return "Building updated"
        default: return "Update"
        }
    }
}

