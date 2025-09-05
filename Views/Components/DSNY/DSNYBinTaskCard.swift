//
//  DSNYBinTaskCard.swift
//  CyntientOps
//
//  DSNY bin management task card for worker dashboards
//  Shows bin retrieval tasks with building details and completion tracking
//

import SwiftUI

struct DSNYBinTaskCard: View {
    let tasks: [DSNYTask]
    let onTaskCompleted: (String) -> Void
    
    @State private var expandedTaskId: String?
    
    var body: some View {
        if !tasks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bin Retrieval Tasks")
                            .font(.headline)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        
                        Text("\(pendingTaskCount) buildings need bins brought inside")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Progress indicator
                    if totalTaskCount > 0 {
                        CircularProgressView(
                            progress: Double(completedTaskCount) / Double(totalTaskCount),
                            size: 32
                        )
                    }
                }
                
                // Task list
                VStack(spacing: 8) {
                    ForEach(tasks, id: \.id) { task in
                        DSNYTaskRow(
                            task: task,
                            isExpanded: expandedTaskId == task.id,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    expandedTaskId = expandedTaskId == task.id ? nil : task.id
                                }
                            },
                            onComplete: {
                                onTaskCompleted(task.id)
                            }
                        )
                    }
                }
            }
            .padding()
            .glassCard()
        }
    }
    
    private var pendingTaskCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }
    
    private var completedTaskCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    private var totalTaskCount: Int {
        tasks.count
    }
}

// MARK: - Task Row

struct DSNYTaskRow: View {
    let task: DSNYTask
    let isExpanded: Bool
    let onTap: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main row
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Status indicator
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(task.isCompleted ? .green : .orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.buildingName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            .strikethrough(task.isCompleted)
                        
                        HStack(spacing: 8) {
                            Text("By \(task.scheduledTime.timeString)")
                                .font(.caption)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                            
                            if task.isCompleted, let completedAt = task.completedAt {
                                Text("• Completed \(formatCompletionTime(completedAt))")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 8) {
                        if !task.isCompleted {
                            Button("Done") {
                                onComplete()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text("Instructions:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text(task.instructions)
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack {
                        Label("Collection Day", systemImage: "calendar")
                        Text(task.collectionDay.rawValue)
                        
                        Spacer()
                        
                        Label("Location", systemImage: "location")
                        Text("Curbside")
                    }
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .background(task.isCompleted ? Color.green.opacity(0.05) : Color.clear)
        .cornerRadius(8)
    }
    
    private func formatCompletionTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}

 
