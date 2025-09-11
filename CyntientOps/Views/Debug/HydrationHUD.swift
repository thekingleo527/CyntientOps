//
//  HydrationHUD.swift
//  CyntientOps
//
//  Tiny overlay showing hydration readiness per section

import SwiftUI

struct HydrationHUD: View {
    @ObservedObject var status = HydrationStatusManager.shared

    var body: some View {
        HStack(spacing: 8) {
            pill("User", ready: status.userReady)
            pill("Buildings", ready: status.buildingsReady)
            pill("Routes", ready: status.routesReady)
            pill("Weather", ready: status.weatherReady)
            pill("DSNY", ready: status.dsnyReady)
            pill("Schedule", ready: status.scheduleReady)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.top, 8)
        .padding(.trailing, 8)
    }

    @ViewBuilder
    private func pill(_ label: String, ready: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(ready ? Color.green : Color.yellow)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption2).foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.25), in: Capsule())
    }
}

