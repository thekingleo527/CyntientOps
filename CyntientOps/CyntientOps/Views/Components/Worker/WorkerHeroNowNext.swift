import SwiftUI

struct WorkerHeroNowNext: View {
    @ObservedObject var viewModel: WorkerDashboardViewModel

    var body: some View {
        HStack(spacing: 12) {
            heroCard(title: "Now", tasks: nowTasks(), color: .blue)
            heroCard(title: "Next", tasks: nextTasks(), color: .purple)
        }
    }

    private func heroCard(title: String, tasks: [TaskRowVM], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Circle().fill(color).frame(width: 6, height: 6)
            }
            ForEach(tasks.prefix(2), id: \.id) { t in
                HStack(spacing: 8) {
                    Circle().fill(color.opacity(0.8)).frame(width: 6, height: 6)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.title).font(.subheadline)
                        Text(t.time).font(.caption2).foregroundColor(.gray)
                    }
                    Spacer()
                }
            }
            if tasks.isEmpty {
                Text("All clear").font(.caption).foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private func nowTasks() -> [TaskRowVM] {
        // Return first few tasks from upcoming (these are already weather-sorted and prioritized)
        return Array(viewModel.upcoming.prefix(2))
    }

    private func nextTasks() -> [TaskRowVM] {
        // Return next tasks after the "now" tasks
        return Array(viewModel.upcoming.dropFirst(2).prefix(2))
    }
}

