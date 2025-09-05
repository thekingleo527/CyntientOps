
//
//  ClientDashboardHeader.swift
//  CyntientOps
//
//  Created by Gemini on 2025-08-17.
//

import SwiftUI

struct ClientDashboardHeader: View {
    let clientName: String
    let onProfileTap: () -> Void
    let onNovaTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Left: CyntientOps logo
            CyntientOpsLogo(size: .compact)

            Spacer()

            // Center: Nova avatar
            NovaAvatar(
                size: .persistent,
                isActive: false,
                hasUrgentInsights: false,
                isBusy: false,
                onTap: onNovaTap,
                onLongPress: { onNovaTap() }
            )

            Spacer()

            // Right: Client pill
            Button(action: onProfileTap) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 32, height: 32)
                        .overlay(Text(initials(from: clientName)).font(.caption).foregroundColor(.white))
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.9),
                    Color.purple.opacity(0.1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(.white.opacity(0.1)), alignment: .bottom)
    }
}

private func initials(from name: String) -> String {
    let parts = name.split(separator: " ")
    let first = parts.first?.prefix(1) ?? "C"
    let last = parts.dropFirst().first?.prefix(1) ?? ""
    return String(first + last)
}
