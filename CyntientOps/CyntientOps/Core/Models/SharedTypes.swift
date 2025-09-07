//
//  SharedTypes.swift
//  CyntientOps
//
//  Shared type definitions
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - TrendDirection
enum TrendDirection: String, Codable {
    case up = "up"
    case down = "down"
    case stable = "stable"
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
}

// MARK: - WeatherImpact

// MARK: - TaskTrends
struct TaskTrends {
    let weeklyCompletion: [Double]
    let categoryBreakdown: [String: Int]
    let changePercentage: Double
    let comparisonPeriod: String
    let trend: TrendDirection
}

// MARK: - PerformanceMetrics
struct PerformanceMetrics {
    let efficiency: Double
    let tasksCompleted: Int
    let averageTime: Double
    let qualityScore: Double
    let lastUpdate: Date
}

// MARK: - StreakData
struct StreakData {
    let currentStreak: Int
    let longestStreak: Int
    let lastUpdate: Date
}
