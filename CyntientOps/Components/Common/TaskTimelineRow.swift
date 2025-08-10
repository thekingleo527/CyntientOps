//  TaskTimelineRow.swift
//  CyntientOps
//
//  ✅ FIXED: Compilation error resolved - using completedAt instead of completedDate
//  ✅ Uses task.title property (from CyntientOpsModels.swift)
//  ✅ Fixed constructor to match actual ContextualTask init
//  ✅ Handles optional urgency properly
//

import SwiftUI

struct TaskTimelineRow: View {
    let task: ContextualTask
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(task.isCompleted ? Color.green : Color.orange)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                // Using task.title (actual property from CyntientOpsModels)
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Safe unwrapping of optional description
                Text(task.description ?? "No description")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let dueDate = task.dueDate {
                    Text("Due: \(dueDate, style: .time)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // Urgency badge with safe handling of optional urgency
            if let urgency = task.urgency {
                Text(urgency.rawValue.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(urgencyColor(for: urgency))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            } else {
                Text("Medium")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func urgencyColor(for urgency: TaskUrgency) -> Color {
        switch urgency {
        case .emergency:
            return .purple
        case .critical, .urgent:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .green
        case .normal:
            return .blue
        }
    }
}

// MARK: - Preview Provider
struct TaskTimelineRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Preview 1: Incomplete task
            TaskTimelineRow(
                task: ContextualTask(
                    id: "preview-1",
                    title: "Clean Main Lobby",
                    description: "Daily cleaning of building entrance and lobby area",
                    // ✅ FIXED: Using completedAt instead of completedDate
                    completedAt: nil,  // This makes isCompleted false
                    dueDate: Date().addingTimeInterval(3600),
                    category: .maintenance,
                    urgency: .high,
                    building: NamedCoordinate(
                        id: "1",
                        name: "123 Main Street",
                        latitude: 40.7128,
                        longitude: -74.0060
                    ),
                    worker: WorkerProfile(
                        id: "1",
                        name: "Kevin Dutan",
                        email: "kevin@cyntientops.com",
                        phoneNumber: "555-0123",
                        role: .worker,
                        skills: [],
                        certifications: [],
                        hireDate: Date()
                    )
                )
            )
            
            // Preview 2: Completed task
            TaskTimelineRow(
                task: ContextualTask(
                    id: "preview-2",
                    title: "Empty Trash Bins",
                    description: "Remove trash from all floors",
                    completedAt: Date(), // This makes isCompleted true
                    dueDate: Date().addingTimeInterval(-3600),
                    category: .cleaning,
                    urgency: .medium,
                    building: NamedCoordinate(
                        id: "2",
                        name: "456 Park Ave",
                        latitude: 40.7580,
                        longitude: -73.9855
                    ),
                    worker: WorkerProfile(
                        id: "2",
                        name: "Maria Garcia",
                        email: "maria@cyntientops.com",
                        phoneNumber: "555-0124",
                        role: .worker,
                        skills: [],
                        certifications: [],
                        hireDate: Date()
                    )
                )
            )
            
            // Preview 3: Emergency task
            TaskTimelineRow(
                task: ContextualTask(
                    id: "preview-3",
                    title: "Water Leak - 3rd Floor",
                    description: nil, // Testing nil description
                    completedAt: nil,
                    dueDate: Date(),
                    category: .emergency,
                    urgency: .emergency,
                    building: NamedCoordinate(
                        id: "3",
                        name: "789 Broadway",
                        latitude: 40.7489,
                        longitude: -73.9680
                    ),
                    worker: WorkerProfile(
                        id: "1",
                        name: "Kevin Dutan",
                        email: "kevin@cyntientops.com",
                        phoneNumber: "555-0123",
                        role: .worker,
                        skills: [],
                        certifications: [],
                        hireDate: Date()
                    )
                )
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
