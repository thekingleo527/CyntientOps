//
//  UpcomingTaskListView.swift
//  CyntientOps  
//
//  Weather-aware upcoming tasks list for Worker dashboard
//  Shows up to 3 prioritized tasks with weather chips and advice
//

import SwiftUI

struct UpcomingTaskListView: View {
    let rows: [TaskRowVM]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Upcoming Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if !rows.isEmpty {
                    Text("\(rows.count) tasks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Task rows
            if rows.isEmpty {
                EmptyTasksView()
            } else {
                VStack(spacing: 8) {
                    ForEach(rows) { row in
                        TaskRowView(row: row)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Task Row View

private struct TaskRowView: View {
    let row: TaskRowVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title and time
            HStack {
                Text(row.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(row.time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            
            // Building and weather info
            HStack(spacing: 8) {
                Text(row.building)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Weather chip
                if let chip = row.chip {
                    WeatherChipView(chip: chip)
                }
                
                Spacer()
            }
            
            // Weather advice
            if let advice = row.advice {
                Text(advice)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(1)
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Weather Chip View

private struct WeatherChipView: View {
    let chip: WeatherChip
    
    var body: some View {
        HStack(spacing: 4) {
            Text(chip.emoji)
                .font(.caption2)
            
            Text(chip.label)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(chipBackgroundColor, in: Capsule())
        .foregroundStyle(chipForegroundColor)
    }
    
    private var chipBackgroundColor: Color {
        switch chip {
        case .goodWindow: return .green.opacity(0.2)
        case .wet, .windy: return .orange.opacity(0.2)
        case .heavyRain, .hot: return .red.opacity(0.2)
        case .cold: return .blue.opacity(0.2)
        }
    }
    
    private var chipForegroundColor: Color {
        switch chip {
        case .goodWindow: return .green
        case .wet, .windy: return .orange
        case .heavyRain, .hot: return .red
        case .cold: return .blue
        }
    }
}

// MARK: - Empty State View

private struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.title2)
                .foregroundStyle(.green)
            
            Text("All caught up!")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Text("No upcoming tasks right now.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Preview

#Preview {
    let sampleRows = [
        TaskRowVM(scored: ScoredTask(
            task: CoreTypes.ContextualTask(
                id: "1",
                title: "Building Entrance Cleaning",
                description: "Clean front entrance",
                status: .pending,
                dueDate: Date().addingTimeInterval(3600),
                category: .cleaning
            ),
            chip: .goodWindow,
            advice: nil,
            score: 1
        )),
        TaskRowVM(scored: ScoredTask(
            task: CoreTypes.ContextualTask(
                id: "2", 
                title: "DSNY Set Out",
                description: "Prepare bags for collection",
                status: .pending,
                dueDate: Date().addingTimeInterval(7200),
                category: .operations
            ),
            chip: .wet,
            advice: "Wet window likely—consider reslotting.",
            score: 2
        )),
        TaskRowVM(scored: ScoredTask(
            task: CoreTypes.ContextualTask(
                id: "3",
                title: "Courtyard Maintenance", 
                description: "Check exterior fixtures",
                status: .pending,
                dueDate: Date().addingTimeInterval(10800),
                category: .maintenance
            ),
            chip: .windy,
            advice: "High wind; bag/tie securely.",
            score: 3
        ))
    ]
    
    return VStack {
        UpcomingTaskListView(rows: sampleRows)
        Spacer()
    }
    .padding()
    .background(Color.black.gradient)
}