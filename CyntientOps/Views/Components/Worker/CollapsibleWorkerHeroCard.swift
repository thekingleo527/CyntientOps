import SwiftUI

struct CollapsibleWorkerHeroCard: View {
    @Binding var isExpanded: Bool
    let workerProfile: CoreTypes.WorkerProfile?
    let currentBuilding: CoreTypes.NamedCoordinate?
    let todaysProgress: Double
    let clockedIn: Bool
    let onClockAction: () -> Void
    let onStartNextTask: () -> Void
    let onUploadPhoto: () -> Void
    let onReportIssue: () -> Void
    let viewModel: WorkerDashboardViewModel

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
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Good Morning, \(workerProfile?.name ?? "Worker")")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Current: \(currentBuilding?.name ?? "Not Clocked In")")
                }
                Spacer()
                if let weather = viewModel.weatherData {
                    WeatherView(weather: weather)
                }
            }

            ProgressView(value: todaysProgress)
                .progressViewStyle(LinearProgressViewStyle())

            HStack {
                QuickStat(title: "Active", value: String(format: "%.1fh", viewModel.hoursWorkedToday))
                QuickStat(title: "Photos", value: "\(viewModel.todaysPhotoCount)")
                QuickStat(title: "Walked", value: "\(String(format: "%.1f", viewModel.distanceWalked))mi")
                QuickStat(title: "Efficiency", value: "\(Int(viewModel.todaysEfficiency * 100))%")
            }

            Picker("View", selection: .constant(0)) {
                Text("Map View").tag(0)
                Text("List View").tag(1)
                Text("Schedule").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())

            HStack {
                Button("Start Next Task", action: onStartNextTask)
                Button("Upload Photo", action: onUploadPhoto)
                Button("Report Issue", action: onReportIssue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
        .frame(height: 380)
    }

    private var collapsedContent: some View {
        HStack {
            Text("\(viewModel.completedTasksCount)/\(viewModel.todaysTasks.count) Tasks")
            ProgressView(value: todaysProgress)
                .progressViewStyle(LinearProgressViewStyle())
            if let nextTask = viewModel.todaysTasks.first(where: { !$0.isCompleted }) {
                Text("Next: \(nextTask.title)")
            }
            Image(systemName: "chevron.down")
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
        .frame(height: 80)
    }
}

struct QuickStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
        }
    }
}

struct WeatherView: View {
    let weather: CoreTypes.WeatherData

    var body: some View {
        HStack {
            Image(systemName: weather.condition.iconName)
            Text("\(weather.temperature)°F")
        }
    }
}

extension CoreTypes.WeatherCondition {
    var iconName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "snow"
        default: return "sun.max.fill"
        }
    }
}
