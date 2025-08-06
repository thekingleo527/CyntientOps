//
//  QBConnectionStatus.swift
//  CyntientOps
//
//  ✅ V6.0: This is the single, authoritative definition for the QuickBooks connection status.
//

import Foundation
import SwiftUI

public enum QBConnectionStatus: Equatable {
    case disconnected, connecting, connected, expired, error(String)
    
    public var displayText: String {
        switch self {
        case .disconnected: return "Not Connected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .expired: return "Token Expired"
        case .error(let message): return "Error: \(message)"
        }
    }
    
    public var color: Color {
        switch self {
        case .disconnected: return .gray
        case .connecting: return .blue
        case .connected: return .green
        case .expired: return .orange
        case .error: return .red
        }
    }
    
    public var icon: String {
        switch self {
        case .disconnected: return "link.circle"
        case .connecting: return "arrow.clockwise.circle"
        case .connected: return "checkmark.circle.fill"
        case .expired: return "clock.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}
