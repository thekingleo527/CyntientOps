//
//  EnhancedClockInGlassCard.swift
//  CyntientOps
//
//  ✅ V6.0: Decoupled from ClockInManager actor.
//  ✅ Now a "dumb" view that accepts simple state values.
//

import SwiftUI

struct EnhancedClockInGlassCard: View {
    let isClockedIn: Bool
    let onClockInToggle: () -> Void

    var body: some View {
        Button(action: onClockInToggle) {
            VStack(spacing: 8) {
                Image(systemName: isClockedIn ? "clock.badge.checkmark.fill" : "clock.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isClockedIn ? .green : .blue)
                
                Text(isClockedIn ? "CLOCK\nOUT" : "CLOCK\nIN")
                    .font(.system(size: 11, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(isClockedIn ? .green : .blue)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
