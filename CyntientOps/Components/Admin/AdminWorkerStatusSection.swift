//
//  AdminWorkerStatusSection.swift
//  CyntientOps Phase 4
//
//  Worker status overview section for admin dashboard
//

import SwiftUI

struct AdminWorkerStatusSection: View {
    let activeWorkers: [CoreTypes.WorkerProfile]
    let allWorkers: [CoreTypes.WorkerProfile]
    let onWorkerTap: (CoreTypes.WorkerProfile) -> Void
    let onViewAll: () -> Void
    
    private var utilization: Double {
        guard !allWorkers.isEmpty else { return 0.0 }
        return Double(activeWorkers.count) / Double(allWorkers.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text("Worker Status")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                StatusPill(
                    text: "\(activeWorkers.count)/\(allWorkers.count)",
                    color: utilization > 0.7 ? .green : .orange,
                    style: .outlined
                )
                
                Spacer()
                
                Button(action: onViewAll) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Utilization Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Team Utilization")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(utilization * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(utilization > 0.7 ? .green : .orange)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(utilization > 0.7 ? Color.green : Color.orange)
                            .frame(width: geometry.size.width * utilization, height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            // Active Workers
            if !activeWorkers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Currently Active")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(activeWorkers.prefix(4)) { worker in
                            AdminActiveWorkerCard(
                                worker: worker,
                                onTap: { onWorkerTap(worker) }
                            )
                        }
                    }
                    
                    if activeWorkers.count > 4 {
                        Button(action: onViewAll) {
                            HStack {
                                Text("+ \(activeWorkers.count - 4) more workers")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    
                    Text("No workers currently active")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct AdminActiveWorkerCard: View {
    let worker: CoreTypes.WorkerProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Worker Avatar
                WorkerAvatar(workerName: worker.name, size: .small)
                
                // Worker Info
                VStack(alignment: .leading, spacing: 1) {
                    Text(worker.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("Active")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
struct AdminWorkerStatusSection_Previews: PreviewProvider {
    static var previews: some View {
        let mockActiveWorkers = [
            CoreTypes.WorkerProfile(
                id: "4",
                name: "Kevin Dutan",
                email: "kevin@francosphere.com",
                role: .worker,
                status: .clockedIn
            ),
            CoreTypes.WorkerProfile(
                id: "7",
                name: "Mercedes Inamagua",
                email: "mercedes@francosphere.com", 
                role: .worker,
                status: .clockedIn
            ),
            CoreTypes.WorkerProfile(
                id: "1",
                name: "Greg Hutson",
                email: "greg@francosphere.com",
                role: .worker,
                status: .clockedIn
            )
        ]
        
        let mockAllWorkers = mockActiveWorkers + [
            CoreTypes.WorkerProfile(
                id: "2",
                name: "Edwin Lema",
                email: "edwin@francosphere.com",
                role: .worker,
                status: .available
            ),
            CoreTypes.WorkerProfile(
                id: "3",
                name: "Luis Lopez",
                email: "luis@francosphere.com",
                role: .worker,
                status: .available
            )
        ]
        
        AdminWorkerStatusSection(
            activeWorkers: mockActiveWorkers,
            allWorkers: mockAllWorkers,
            onWorkerTap: { _ in },
            onViewAll: { }
        )
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif