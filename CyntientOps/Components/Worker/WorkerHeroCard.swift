//
//  WorkerHeroCard.swift  
//  CyntientOps Phase 4
//
//  Hero card that compresses from 280px to 80px on scroll
//  Shows worker profile, progress, and clock in/out
//

import SwiftUI

struct WorkerHeroCard: View {
    let workerProfile: CoreTypes.WorkerProfile?
    let currentBuilding: CoreTypes.NamedCoordinate?
    let todaysProgress: Double
    let clockedIn: Bool
    let onClockAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Top section with avatar and building
            HStack {
                // Worker Avatar (larger)
                if let profile = workerProfile {
                    WorkerAvatar(workerName: profile.name, size: .large)
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 60, height: 60)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workerProfile?.name ?? "Worker")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if clockedIn, let building = currentBuilding {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            
                            Text("Working at \(building.name)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 8, height: 8)
                            
                            Text("Not clocked in")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: todaysProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(Int(todaysProgress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Clock Action Button
            Button(action: onClockAction) {
                HStack(spacing: 12) {
                    Image(systemName: clockedIn ? "clock.arrow.2.circlepath" : "clock")
                        .font(.system(size: 20))
                    
                    Text(clockedIn ? "Clock Out" : "Clock In")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if !clockedIn {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: clockedIn ? [.red, .red.opacity(0.8)] : [.blue, .blue.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.1),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#if DEBUG
struct WorkerHeroCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Clocked in
            WorkerHeroCard(
                workerProfile: CoreTypes.WorkerProfile(
                    id: "4",
                    name: "Kevin Dutan",
                    email: "kevin@cyntientops.com",
                    role: .worker,
                    status: .clockedIn
                ),
                currentBuilding: CoreTypes.NamedCoordinate(
                    id: "14",
                    name: "Rubin Museum",
                    address: "150 W 17th St",
                    latitude: 40.7408,
                    longitude: -73.9971,
                    type: .educational
                ),
                todaysProgress: 0.42, // 16/38 tasks
                clockedIn: true,
                onClockAction: {}
            )
            .frame(height: 280)
            
            // Not clocked in
            WorkerHeroCard(
                workerProfile: CoreTypes.WorkerProfile(
                    id: "7",
                    name: "Mercedes Inamagua", 
                    email: "mercedes@cyntientops.com",
                    role: .worker,
                    status: .available
                ),
                currentBuilding: nil,
                todaysProgress: 0.0,
                clockedIn: false,
                onClockAction: {}
            )
            .frame(height: 280)
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif