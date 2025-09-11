import SwiftUI

struct RecentActivityList: View {
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    let onOpenBuilding: (String) -> Void
    let isWorker: Bool

    var body: some View {
        // Feature flag: default OFF for workers, ON for admins
        if isWorker && !AppFeatures.RecentActivity.enabledForWorkers { EmptyView() } else {
            if dashboardSync.summarizedRecentActivity.isEmpty { EmptyView() } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(LocalizedStringKey("dashboard.recent_activity"))
                            .font(.headline)
                        Spacer()
                    }
                    ForEach(dashboardSync.summarizedRecentActivity.prefix(6)) { item in
                        Button(action: { onOpenBuilding(item.buildingId) }) {
                            HStack(spacing: 10) {
                                Image(systemName: "building.2.fill")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.subheadline).fontWeight(.semibold)
                                    Text(item.changes.joined(separator: " • "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(item.occurredAt, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
