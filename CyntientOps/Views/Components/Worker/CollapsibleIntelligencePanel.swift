import SwiftUI

struct CollapsibleIntelligencePanel: View {
    @Binding var isExpanded: Bool
    let container: ServiceContainer
    @ObservedObject var viewModel: WorkerDashboardViewModel

    var body: some View {
        VStack {
            if isExpanded {
                expandedContent
            } else {
                collapsedContent
            }
        }
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }

    private var expandedContent: some View {
        VStack {
            // Task lists, route optimization, etc. would go here
            taskList
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
        .frame(height: 400)
    }

    private var collapsedContent: some View {
        HStack {
            Text("Nova Intelligence")
            Image(systemName: "chevron.up")
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
        .frame(height: 60)
    }

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !viewModel.urgentTasks.isEmpty {
                    Section(header: Text("Urgent Tasks").font(.headline)) {
                        ForEach(viewModel.urgentTasks) { task in
                            TaskRow(task: task)
                        }
                    }
                }

                if let currentBuilding = viewModel.currentBuilding {
                    Section(header: Text("Current Building: \(currentBuilding.name)").font(.headline)) {
                        ForEach(viewModel.getTasksForBuilding(currentBuilding.id)) { task in
                            TaskRow(task: task)
                        }
                    }
                }

                Section(header: Text("Upcoming Buildings").font(.headline)) {
                    ForEach(viewModel.upcomingBuildings) { building in
                        VStack(alignment: .leading) {
                            Text(building.name)
                                .font(.headline)
                            ForEach(viewModel.getTasksForBuilding(building.id)) { task in
                                TaskRow(task: task)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TaskRow: View {
    let task: CoreTypes.ContextualTask

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                if let building = task.building {
                    Text(building.name)
                        .font(.subheadline)
                }
            }
            Spacer()
            Button("Start") { /* TODO */ }
            Button("Details") { /* TODO */ }
            Button("Navigate") { /* TODO */ }
        }
    }
}