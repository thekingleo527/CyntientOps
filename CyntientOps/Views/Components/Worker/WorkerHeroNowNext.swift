import SwiftUI

struct WorkerHeroNowNext: View {
    @ObservedObject var viewModel: WorkerDashboardViewModel

    var body: some View {
        HStack(spacing: 12) {
            heroCard(title: "Now", tasks: nowTasks(), color: .blue)
            heroCard(title: "Next", tasks: nextTasks(), color: .purple)
        }
    }

    private func heroCard(title: String, tasks: [WorkerDashboardViewModel.TaskItem], color: Color) -> some View {
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
                        if let due = t.dueDate { Text(due, style: .time).font(.caption2).foregroundColor(.gray) }
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

    private func nowTasks() -> [WorkerDashboardViewModel.TaskItem] {
        // Tasks due within 30 minutes or in-progress from todaysTasks if available
        let window = Date().addingTimeInterval(30*60)
        return viewModel.todaysTasks.filter { t in
            if let due = t.dueDate { return due <= window } else { return false }
        }
    }

    private func nextTasks() -> [WorkerDashboardViewModel.TaskItem] {
        // Sorted upcoming by due date
        return viewModel.upcoming.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
    }
}

