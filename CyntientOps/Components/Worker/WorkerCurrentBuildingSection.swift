//
//  WorkerCurrentBuildingSection.swift
//  CyntientOps Phase 4
//
//  Current building section showing building info and relevant tasks
//

import SwiftUI

struct WorkerCurrentBuildingSection: View {
    let building: CoreTypes.NamedCoordinate
    let buildingTasks: [CoreTypes.ContextualTask]
    let onTaskTap: (CoreTypes.ContextualTask) -> Void
    let onBuildingTap: () -> Void
    
    private var completedTasks: Int {
        buildingTasks.filter { $0.isCompleted }.count
    }
    
    private var totalTasks: Int {
        buildingTasks.count
    }
    
    private var progressPercentage: Double {
        totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header with Building Info
            Button(action: onBuildingTap) {
                HStack(spacing: 12) {
                    // Building Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    
                    // Building Details
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(building.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            StatusPill(text: "CURRENT", color: .green, style: .filled)
                        }
                        
                        Text(building.address)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Progress Summary
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(completedTasks)/\(totalTasks)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Tasks")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Building Progress")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(progressPercentage * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.blue)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
            
            // Recent Building Tasks
            if !buildingTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Building Tasks")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 6) {
                        ForEach(buildingTasks.prefix(3)) { task in
                            WorkerBuildingTaskRow(
                                task: task,
                                onTap: { onTaskTap(task) }
                            )
                        }
                        
                        if buildingTasks.count > 3 {
                            Button(action: onBuildingTap) {
                                HStack {
                                    Text("View all \(buildingTasks.count) tasks")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.blue.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

struct WorkerBuildingTaskRow: View {
    let task: CoreTypes.ContextualTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Status Icon
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(task.isCompleted ? .green : .gray)
                
                // Task Title
                Text(task.title)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                // Tags
                HStack(spacing: 4) {
                    if task.isOverdue {
                        Text("OVERDUE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    if task.requiresPhoto == true {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color.white.opacity(0.03))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
struct WorkerCurrentBuildingSection_Previews: PreviewProvider {
    static var previews: some View {
        let building = CoreTypes.NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            address: "150 W 17th St, New York, NY 10011",
            latitude: 40.7408,
            longitude: -73.9971,
            type: .educational
        )
        
        let buildingTasks = [
            CoreTypes.ContextualTask(
                id: "task-1",
                title: "Clean gallery floors - Level 2",
                description: "Daily cleaning of hardwood gallery floors",
                status: .completed,
                urgency: .medium,
                building: building,
                requiresPhoto: true
            ),
            CoreTypes.ContextualTask(
                id: "task-2", 
                title: "Dust exhibition cases - Himalayan Art",
                description: "Weekly dusting of glass display cases",
                urgency: .low,
                building: building,
                requiresPhoto: false
            ),
            CoreTypes.ContextualTask(
                id: "task-3",
                title: "Vacuum carpeted areas - Lobby",
                description: "Daily vacuuming of lobby carpets",
                dueDate: Date().addingTimeInterval(-3600),
                urgency: .medium,
                building: building,
                requiresPhoto: true
            ),
            CoreTypes.ContextualTask(
                id: "task-4",
                title: "Empty trash receptacles - All floors",
                description: "Empty and replace liners in all waste bins",
                status: .completed,
                urgency: .medium,
                building: building,
                requiresPhoto: false
            )
        ]
        
        WorkerCurrentBuildingSection(
            building: building,
            buildingTasks: buildingTasks,
            onTaskTap: { _ in },
            onBuildingTap: { }
        )
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif