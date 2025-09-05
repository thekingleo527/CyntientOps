// TimelineProgressBar.swift
// Visual timeline for task progression

import SwiftUI
// CyntientOps Types Import
// (This comment helps identify our import)

struct TimelineProgressBar: View {
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                
                // Hour markers
                HStack(spacing: 0) {
                    ForEach(0..<24) { hour in
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 1)
                        
                        if hour < 23 {
                            Spacer()
                        }
                    }
                }
                
                // Current time indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 4)
                    .offset(x: currentTimeOffset(in: geometry.size.width))
                
                // Time labels
                HStack {
                    Text("12am")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text("Now")
                        .font(.caption2.bold())
                        .foregroundColor(.blue)
                        .offset(x: currentTimeOffset(in: geometry.size.width) - 20)
                    
                    Spacer()
                    
                    Text("11pm")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 4)
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private func currentTimeOffset(in width: CGFloat) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let totalMinutes = Double(hour * 60 + minute)
        let dayProgress = totalMinutes / (24 * 60)
        return width * CGFloat(dayProgress)
    }
}
