//
//  WorkerUrgentTasksSection.swift
//  CyntientOps Phase 4
//
//  Urgent tasks section for worker dashboard
//  Shows tasks requiring immediate attention
//

import SwiftUI

struct WorkerUrgentTasksSection: View {
    let tasks: [CoreTypes.ContextualTask]
    let onTaskTap: (CoreTypes.ContextualTask) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
                
                Text("Urgent Tasks")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                StatusPill(text: "\(tasks.count)", color: .red, style: .filled)
                
                Spacer()
            }
            
            // Tasks List
            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    WorkerUrgentTaskRow(
                        task: task,
                        onTap: { onTaskTap(task) }
                    )
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color.red.opacity(0.1),
                    Color.red.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

struct WorkerUrgentTaskRow: View {
    let task: CoreTypes.ContextualTask
    let onTap: () -> Void
    
    var urgencyColor: Color {
        switch task.urgency {
        case .emergency: return .red
        case .critical: return .red
        case .urgent: return .orange
        default: return .orange
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Urgency Indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(urgencyColor)
                    .frame(width: 4, height: 40)
                
                // Task Icon
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(task.isCompleted ? .green : urgencyColor)
                
                // Task Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if let building = task.building {
                            Text(building.name)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if task.isOverdue {
                            Text("OVERDUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        if let urgency = task.urgency {
                            Text(urgency.rawValue.uppercased())
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(urgencyColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(urgencyColor.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                // Action indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
struct WorkerUrgentTasksSection_Previews: PreviewProvider {
    static var previews: some View {
        let urgentTasks = [
            CoreTypes.ContextualTask(
                id: "urgent-1",
                title: "Emergency water leak - Basement Level",
                description: "Water leak reported in basement mechanical room",
                dueDate: Date().addingTimeInterval(-3600),
                urgency: .emergency,
                building: CoreTypes.NamedCoordinate(
                    id: "14",
                    name: "Rubin Museum", 
                    address: "150 W 17th St",
                    latitude: 40.7408,
                    longitude: -73.9971,
                    type: .educational
                ),
                requiresPhoto: true
            ),
            CoreTypes.ContextualTask(
                id: "urgent-2",
                title: "HVAC system failure - 3rd floor",
                description: "Temperature control malfunction affecting multiple units",
                urgency: .critical,
                building: CoreTypes.NamedCoordinate(
                    id: "14",
                    name: "Rubin Museum",
                    address: "150 W 17th St", 
                    latitude: 40.7408,
                    longitude: -73.9971,
                    type: .educational
                ),
                requiresPhoto: false
            )
        ]
        
        WorkerUrgentTasksSection(
            tasks: urgentTasks,
            onTaskTap: { _ in }
        )
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif