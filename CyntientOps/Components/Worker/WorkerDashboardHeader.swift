//
//  WorkerDashboardHeader.swift
//  CyntientOps Phase 4
//
//  Worker Dashboard Header Component - Fixed height 60px
//  Shows worker name, task count, and current building
//

import SwiftUI

struct WorkerDashboardHeader: View {
    let workerName: String
    let totalTasks: Int
    let completedTasks: Int
    let currentBuilding: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // Worker Avatar
            WorkerAvatar(workerName: workerName, size: .small)
            
            // Worker Info
            VStack(alignment: .leading, spacing: 2) {
                Text(workerName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let building = currentBuilding {
                    Text(building)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                } else {
                    Text("Not clocked in")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Task Progress
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(completedTasks)/\(totalTasks)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Tasks")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            // Status Indicator
            Circle()
                .fill(completedTasks == totalTasks ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.white.opacity(0.1)),
            alignment: .bottom
        )
    }
}

#if DEBUG
struct WorkerDashboardHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            WorkerDashboardHeader(
                workerName: "Kevin Dutan",
                totalTasks: 38,
                completedTasks: 15,
                currentBuilding: "Rubin Museum"
            )
            .frame(height: 60)
            
            WorkerDashboardHeader(
                workerName: "Mercedes Inamagua", 
                totalTasks: 22,
                completedTasks: 22,
                currentBuilding: nil
            )
            .frame(height: 60)
            
            Spacer()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif