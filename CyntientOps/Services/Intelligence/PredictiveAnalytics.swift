
//  PredictiveAnalytics.swift
//  CyntientOps
//
//  Stream D: Features & Polish
//  Mission: Create a service for ML-driven predictions.
//
//  ✅ SKELETON READY: A well-defined API for future ML model integration.
//  ✅ SAFE DEFAULTS: Provides reasonable default predictions.
//  ✅ EXTENSIBLE: Methods are designed to be easily replaced with real model calls.
//

import Foundation

// MARK: - Predictive Analytics Service

public final class PredictiveAnalytics {
    
    private let grdbManager = GRDBManager.shared
    
    public init() {}
    
    // MARK: - Task Predictions
    
    /// Predicts the completion time for a given task by a specific worker using historical data
    public func predictTaskCompletionTime(
        task: CoreTypes.ContextualTask,
        worker: CoreTypes.WorkerProfile
    ) async throws -> TimeInterval {
        
        // Get historical completion times for similar tasks by this worker
        let category = task.category?.rawValue ?? "general"
        let historicalData = try await getHistoricalTaskData(workerId: worker.id, category: category)
        
        var baseDuration: TimeInterval
        
        if !historicalData.isEmpty {
            // Use historical average as base, weighted by recency
            baseDuration = calculateWeightedAverage(historicalData)
        } else {
            // Fallback to category-based estimates if no historical data
            baseDuration = getBaseCategoryDuration(category: category)
        }
        
        // Apply urgency multiplier
        if let urgency = task.urgency {
            switch urgency {
            case .critical, .emergency:
                baseDuration *= 1.8 // Critical tasks take longer due to precision needed
            case .urgent, .high:
                baseDuration *= 1.3
            case .medium, .normal:
                baseDuration *= 1.0
            case .low:
                baseDuration *= 0.8
            }
        }
        
        // Apply worker skill multiplier
        let skillMultiplier = calculateSkillMultiplier(worker: worker, taskCategory: category)
        baseDuration *= skillMultiplier
        
        // Apply time-of-day factor (workers are typically slower in the evening)
        let timeOfDayFactor = getTimeOfDayFactor()
        baseDuration *= timeOfDayFactor
        
        return max(baseDuration, 300) // Minimum 5 minutes
    }
    
    // MARK: - Building Predictions
    
    /// Predicts future maintenance needs for a building based on historical patterns
    public func predictMaintenanceNeeds(
        building: CoreTypes.NamedCoordinate
    ) async throws -> [MaintenancePrediction] {
        
        // Get historical maintenance data for this building
        let historicalMaintenanceData = try await getHistoricalMaintenanceData(buildingId: building.id)
        let buildingAge = getBuildingAge(building: building)
        
        var predictions: [MaintenancePrediction] = []
        
        // Analyze patterns in historical data
        let maintenancePatterns = analyzeMaintenancePatterns(historicalMaintenanceData)
        
        // Predict based on patterns and building characteristics
        for pattern in maintenancePatterns {
            let daysUntilNext = predictNextOccurrence(pattern: pattern, buildingAge: buildingAge)
            let confidence = calculatePredictionConfidence(pattern: pattern, historicalData: historicalMaintenanceData)
            
            predictions.append(MaintenancePrediction(
                issue: pattern.issueType,
                confidence: confidence,
                nextPredictedDate: Date().addingTimeInterval(TimeInterval(daysUntilNext * 86400)),
                category: pattern.category,
                estimatedCost: pattern.averageCost
            ))
        }
        
        // Add seasonal predictions
        predictions.append(contentsOf: getSeasonalMaintenancePredictions(building: building))
        
        // Sort by urgency (soonest and highest confidence first)
        return predictions.sorted { pred1, pred2 in
            let urgencyScore1 = pred1.confidence * (1.0 / max(Double(pred1.daysUntilDue), 1.0))
            let urgencyScore2 = pred2.confidence * (1.0 / max(Double(pred2.daysUntilDue), 1.0))
            return urgencyScore1 > urgencyScore2
        }
    }
    
    /// Predicts worker performance trends based on historical data
    public func predictWorkerPerformance(
        worker: CoreTypes.WorkerProfile,
        timeframe: TimeInterval
    ) async throws -> WorkerPerformancePrediction {
        
        let historicalPerformance = try await getWorkerPerformanceHistory(workerId: worker.id)
        
        // Calculate trending metrics
        let completionRateTrend = calculateTrend(historicalPerformance.map { $0.completionRate })
        let qualityScoreTrend = calculateTrend(historicalPerformance.map { $0.qualityScore })
        let efficiencyTrend = calculateTrend(historicalPerformance.map { $0.efficiency })
        
        // Predict future performance
        let currentCompletionRate = historicalPerformance.last?.completionRate ?? 0.8
        let predictedCompletionRate = max(0.0, min(1.0, currentCompletionRate + (completionRateTrend * timeframe)))
        
        return WorkerPerformancePrediction(
            workerId: worker.id,
            predictedCompletionRate: predictedCompletionRate,
            predictedQualityScore: max(1.0, min(5.0, (historicalPerformance.last?.qualityScore ?? 4.0) + qualityScoreTrend)),
            predictedEfficiency: max(0.5, min(2.0, (historicalPerformance.last?.efficiency ?? 1.0) + efficiencyTrend)),
            confidence: calculatePerformancePredictionConfidence(historicalData: historicalPerformance)
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func getHistoricalTaskData(workerId: String, category: String) async throws -> [TaskHistoryData] {
        let rows = try await grdbManager.query("""
            SELECT 
                (julianday(completedDate) - julianday(scheduledDate)) * 86400 as duration_seconds,
                created_at
            FROM routine_tasks 
            WHERE workerId = ? AND category = ? AND isCompleted = 1 AND completedDate IS NOT NULL
            ORDER BY created_at DESC
            LIMIT 20
        """, [workerId, category])
        
        return rows.compactMap { row in
            guard let duration = row["duration_seconds"] as? Double,
                  let createdAtStr = row["created_at"] as? String,
                  let createdAt = ISO8601DateFormatter().date(from: createdAtStr) else {
                return nil
            }
            return TaskHistoryData(duration: duration, completedAt: createdAt)
        }
    }
    
    private func calculateWeightedAverage(_ data: [TaskHistoryData]) -> TimeInterval {
        let now = Date()
        let weightedSum = data.reduce(0.0) { sum, item in
            let daysSince = now.timeIntervalSince(item.completedAt) / 86400
            let weight = exp(-daysSince / 30.0) // Exponential decay over 30 days
            return sum + (item.duration * weight)
        }
        let totalWeight = data.reduce(0.0) { sum, item in
            let daysSince = now.timeIntervalSince(item.completedAt) / 86400
            return sum + exp(-daysSince / 30.0)
        }
        
        return totalWeight > 0 ? weightedSum / totalWeight : 1800 // 30 minutes default
    }
    
    private func getBaseCategoryDuration(category: String) -> TimeInterval {
        switch category.lowercased() {
        case "cleaning":
            return 45 * 60 // 45 minutes
        case "maintenance":
            return 90 * 60 // 1.5 hours
        case "inspection":
            return 30 * 60 // 30 minutes
        case "repair":
            return 120 * 60 // 2 hours
        case "installation":
            return 180 * 60 // 3 hours
        default:
            return 60 * 60 // 1 hour default
        }
    }
    
    private func calculateSkillMultiplier(worker: CoreTypes.WorkerProfile, taskCategory: String) -> Double {
        // Parse worker skills (assuming they're stored as comma-separated string)
        let workerSkills = worker.skills?.map { $0.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) } ?? []
        
        if workerSkills.contains(taskCategory.lowercased()) {
            return 0.8 // Skilled workers are 20% faster
        } else {
            return 1.2 // Unskilled workers are 20% slower
        }
    }
    
    private func getTimeOfDayFactor() -> Double {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6...9:   return 0.9  // Morning - slightly faster
        case 10...15: return 1.0  // Peak hours - normal
        case 16...18: return 1.1  // Afternoon - slightly slower
        case 19...23: return 1.3  // Evening - much slower
        default:      return 1.5  // Night/early morning - very slow
        }
    }
    
    private func getHistoricalMaintenanceData(buildingId: String) async throws -> [MaintenanceHistoryData] {
        // This would query historical maintenance records
        // For now, return sample data based on building characteristics
        return [
            MaintenanceHistoryData(issueType: "HVAC Filter Replacement", lastOccurrence: Date().addingTimeInterval(-45 * 86400), frequency: 30),
            MaintenanceHistoryData(issueType: "Plumbing Inspection", lastOccurrence: Date().addingTimeInterval(-75 * 86400), frequency: 90),
            MaintenanceHistoryData(issueType: "Electrical Check", lastOccurrence: Date().addingTimeInterval(-180 * 86400), frequency: 180)
        ]
    }
    
    private func getBuildingAge(building: CoreTypes.NamedCoordinate) -> Int {
        // This would typically come from building metadata
        // For now, return a reasonable estimate
        return 15 // 15 years old
    }
    
    private func analyzeMaintenancePatterns(_ data: [MaintenanceHistoryData]) -> [MaintenancePattern] {
        return data.map { item in
            MaintenancePattern(
                issueType: item.issueType,
                averageFrequency: item.frequency,
                category: categorizeMaintenanceIssue(item.issueType),
                averageCost: estimateMaintenanceCost(item.issueType)
            )
        }
    }
    
    private func predictNextOccurrence(pattern: MaintenancePattern, buildingAge: Int) -> Int {
        // Adjust frequency based on building age
        let ageFactor = 1.0 + (Double(buildingAge) / 50.0) // Older buildings need more maintenance
        let adjustedFrequency = Double(pattern.averageFrequency) / ageFactor
        return max(7, Int(adjustedFrequency)) // Minimum 7 days
    }
    
    private func calculatePredictionConfidence(pattern: MaintenancePattern, historicalData: [MaintenanceHistoryData]) -> Double {
        let dataPoints = historicalData.filter { $0.issueType == pattern.issueType }.count
        return min(0.95, 0.3 + (Double(dataPoints) * 0.1)) // Higher confidence with more data
    }
    
    private func getSeasonalMaintenancePredictions(building: CoreTypes.NamedCoordinate) -> [MaintenancePrediction] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        var seasonal: [MaintenancePrediction] = []
        
        // Spring preparations
        if currentMonth >= 2 && currentMonth <= 4 {
            seasonal.append(MaintenancePrediction(
                issue: "Spring HVAC Maintenance",
                confidence: 0.85,
                nextPredictedDate: getNextSeasonalDate(month: 3),
                category: "HVAC",
                estimatedCost: 350.0
            ))
        }
        
        // Winter preparations
        if currentMonth >= 9 && currentMonth <= 11 {
            seasonal.append(MaintenancePrediction(
                issue: "Winter Heating System Check",
                confidence: 0.90,
                nextPredictedDate: getNextSeasonalDate(month: 10),
                category: "HVAC",
                estimatedCost: 280.0
            ))
        }
        
        return seasonal
    }
    
    private func getNextSeasonalDate(month: Int) -> Date {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        
        let targetYear = month > currentMonth ? currentYear : currentYear + 1
        return calendar.date(from: DateComponents(year: targetYear, month: month, day: 15)) ?? Date()
    }
    
    private func categorizeMaintenanceIssue(_ issueType: String) -> String {
        let type = issueType.lowercased()
        if type.contains("hvac") || type.contains("heating") || type.contains("cooling") {
            return "HVAC"
        } else if type.contains("plumbing") || type.contains("water") {
            return "Plumbing"
        } else if type.contains("electrical") {
            return "Electrical"
        } else {
            return "General"
        }
    }
    
    private func estimateMaintenanceCost(_ issueType: String) -> Double {
        switch categorizeMaintenanceIssue(issueType) {
        case "HVAC":
            return 350.0
        case "Plumbing":
            return 180.0
        case "Electrical":
            return 220.0
        default:
            return 150.0
        }
    }
    
    private func getWorkerPerformanceHistory(workerId: String) async throws -> [HistoricalPerformanceData] {
        // This would query actual performance data
        // For now, generate realistic sample data
        let currentDate = Date()
        return (0..<12).map { monthsBack in
            let date = Calendar.current.date(byAdding: .month, value: -monthsBack, to: currentDate) ?? currentDate
            return HistoricalPerformanceData(
                date: date,
                completionRate: 0.75 + Double.random(in: -0.1...0.2),
                qualityScore: 4.0 + Double.random(in: -0.5...1.0),
                efficiency: 1.0 + Double.random(in: -0.2...0.3)
            )
        }.reversed()
    }
    
    private func calculateTrend(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0.0 }
        
        let n = Double(values.count)
        let sumX = (1...values.count).reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(1...values.count, values).map { Double($0) * $1 }.reduce(0, +)
        let sumXX = (1...values.count).map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - Double(sumX) * sumY) / (n * Double(sumXX) - Double(sumX) * Double(sumX))
        return slope
    }
    
    private func calculatePerformancePredictionConfidence(historicalData: [HistoricalPerformanceData]) -> Double {
        let dataPoints = historicalData.count
        let variance = calculateVariance(historicalData.map { $0.completionRate })
        
        // Higher confidence with more data points and lower variance
        let dataConfidence = min(0.8, Double(dataPoints) / 15.0)
        let varianceConfidence = max(0.2, 1.0 - variance)
        
        return (dataConfidence + varianceConfidence) / 2.0
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count - 1)
    }
}

// MARK: - Supporting Prediction Models

public struct MaintenancePrediction: Identifiable {
    public let id = UUID()
    public let issue: String
    public let confidence: Double // Probability of the issue occurring (0.0 to 1.0)
    public let nextPredictedDate: Date
    public let category: String
    public let estimatedCost: Double
    
    public var daysUntilDue: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextPredictedDate).day ?? 0
        return max(0, days)
    }
    
    public var urgencyLevel: UrgencyLevel {
        switch daysUntilDue {
        case 0...7:   return .critical
        case 8...21:  return .high
        case 22...60: return .medium
        default:      return .low
        }
    }
    
    public enum UrgencyLevel: String {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
    }
}

public struct WorkerPerformancePrediction {
    public let workerId: String
    public let predictedCompletionRate: Double
    public let predictedQualityScore: Double
    public let predictedEfficiency: Double
    public let confidence: Double
    
    public var performanceCategory: PerformanceCategory {
        let overallScore = (predictedCompletionRate + (predictedQualityScore / 5.0) + (predictedEfficiency / 2.0)) / 3.0
        
        switch overallScore {
        case 0.9...1.0:  return .excellent
        case 0.8..<0.9:  return .good
        case 0.7..<0.8:  return .average
        case 0.6..<0.7:  return .belowAverage
        default:         return .poor
        }
    }
    
    public enum PerformanceCategory: String {
        case excellent = "Excellent"
        case good = "Good"
        case average = "Average"
        case belowAverage = "Below Average"
        case poor = "Poor"
    }
}

// MARK: - Internal Data Models

private struct TaskHistoryData {
    let duration: TimeInterval
    let completedAt: Date
}

private struct MaintenanceHistoryData {
    let issueType: String
    let lastOccurrence: Date
    let frequency: Int // days
}

private struct MaintenancePattern {
    let issueType: String
    let averageFrequency: Int
    let category: String
    let averageCost: Double
}

private struct HistoricalPerformanceData {
    let date: Date
    let completionRate: Double
    let qualityScore: Double
    let efficiency: Double
}
