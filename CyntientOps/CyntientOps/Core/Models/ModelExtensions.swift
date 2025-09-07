//
//  ModelExtensions.swift
//  CyntientOps
//
//  ✅ V6.0: Adds UI-specific properties to core data models.
//

import SwiftUI

// Type aliases for CoreTypes

extension TaskCategory {
    var color: Color {
        switch self {
        case .cleaning: return .blue
        case .maintenance: return .orange
        case .repair: return .red
        case .sanitation: return .green
        case .inspection: return .purple
        default: return .gray
        }
    }
}

extension TaskUrgency {
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high, .urgent, .critical, .emergency: return .red
        default: return .gray
        }
    }
}
