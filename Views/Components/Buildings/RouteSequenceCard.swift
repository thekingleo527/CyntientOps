import SwiftUI

// Extracted reusable card for showing a single route sequence
struct RouteSequenceCard: View {
    let sequence: RouteSequence
    let container: ServiceContainer
    // Optional override to display the correct worker
    let overrideWorkerName: String?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sequence.buildingName)
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)

                    HStack(spacing: 16) {
                        Label(displayWorkerName, systemImage: "person.fill")
                        Label(CoreTypes.DateUtils.timeFormatter.string(from: sequence.arrivalTime), systemImage: "clock.fill")
                        Label(formatDuration(sequence.estimatedDuration), systemImage: "timer")
                    }
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    sequenceTypeIcon

                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                }
            }

            // Operations list (expandable)
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Operations")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)

                    ForEach(sequence.operations, id: \.id) { operation in
                        HStack(spacing: 12) {
                            Image(systemName: operationIcon(for: operation.category))
                                .font(.system(size: 14))
                                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryAction)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(operation.name)
                                    .font(.subheadline)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)

                                if let instructions = operation.instructions {
                                    Text(instructions)
                                        .font(.caption)
                                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()

                            Text(formatDuration(operation.estimatedDuration))
                                .font(.caption)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .glassCard()
        // No task-side lookup; parent provides worker name for accuracy
    }

    private var displayWorkerName: String {
        overrideWorkerName ?? "Unknown Worker"
    }

    private var sequenceTypeIcon: some View {
        let (icon, color) = sequenceTypeIconAndColor(sequence.sequenceType)
        return Image(systemName: icon)
            .font(.system(size: 16))
            .foregroundColor(color)
    }

    private func sequenceTypeIconAndColor(_ type: RouteSequence.SequenceType) -> (String, Color) {
        switch type {
        case .buildingCheck:
            return ("building.2.fill", .blue)
        case .indoorCleaning:
            return ("house.fill", .green)
        case .outdoorCleaning:
            return ("sun.max.fill", .orange)
        case .maintenance:
            return ("wrench.and.screwdriver.fill", .purple)
        case .inspection:
            return ("magnifyingglass", .cyan)
        case .sanitation:
            return ("trash.circle.fill", .orange)
        case .operations:
            return ("gearshape.fill", .gray)
        @unknown default:
            return ("square.dashed", .gray)
        }
    }

    private func operationIcon(for category: OperationTask.TaskCategory) -> String {
        switch category {
        case .sweeping: return "wind"
        case .hosing: return "drop.fill"
        case .vacuuming: return "tornado"
        case .mopping: return "mop"
        case .trashCollection: return "trash.fill"
        case .dsnySetout: return "trash"
        case .maintenance: return "wrench.fill"
        case .buildingInspection: return "magnifyingglass"
        case .posterRemoval: return "doc.text.fill"
        case .treepitCleaning: return "leaf.fill"
        case .stairwellCleaning: return "stairs"
        case .binManagement: return "trash.circle.fill"
        case .laundryRoom: return "washer"
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}
