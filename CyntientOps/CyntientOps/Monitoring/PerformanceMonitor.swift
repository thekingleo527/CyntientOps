//
//  PerformanceMonitor.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 7/31/25.
//


//
//  PerformanceMonitor.swift
//  CyntientOps
//
//  Stream D: Features & Polish
//  Mission: Create a utility for tracking application performance.
//
//  ✅ PRODUCTION READY: A centralized performance measurement tool.
//  ✅ LIGHTWEIGHT: Minimal overhead for performance-sensitive operations.
//  ✅ INTEGRATED: Designed to log metrics to a future analytics or logging service.
//

import Foundation
import os.log

final class PerformanceMonitor {
    
    // MARK: - Singleton
    static let shared = PerformanceMonitor()
    
    // Using os.Logger for efficient, system-level logging.
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Performance")
    
    private init() {}
    
    // MARK: - Core Measurement Function
    
    /// Measures the execution time of a synchronous block of code.
    ///
    /// - Parameters:
    ///   - operation: A descriptive name for the operation being measured (e.g., "database.query.tasks").
    ///   - block: The synchronous closure to execute and measure.
    /// - Returns: The result of the block.
    @discardableResult
    func measure<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logPerformance(operation: operation, duration: duration)
        }
        return try block()
    }
    
    /// Measures the execution time of an asynchronous block of code.
    ///
    /// - Parameters:
    ///   - operation: A descriptive name for the operation being measured (e.g., "api.fetch.buildings").
    ///   - block: The asynchronous closure to execute and measure.
    /// - Returns: The result of the block.
    @discardableResult
    func measure<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logPerformance(operation: operation, duration: duration)
        }
        return try await block()
    }
    
    // MARK: - Specific Tracking Methods
    
    /// A dedicated function to track app launch time.
    /// Should be called from the `AppDelegate` or `CyntientOpsApp`.
    func trackLaunchTime(duration: TimeInterval) {
        logPerformance(operation: "app.launch", duration: duration)
    }
    
    /// A dedicated function to track the duration of an API call.
    func trackAPICall(endpoint: String, duration: TimeInterval) {
        logPerformance(operation: "api.\(endpoint)", duration: duration)
    }
    
    /// A dedicated function to track the duration of a database query.
    func trackDatabaseQuery(statement: String, duration: TimeInterval) {
        // Sanitize statement to avoid logging sensitive data
        let sanitizedStatement = statement.components(separatedBy: " ").first ?? "query"
        logPerformance(operation: "db.\(sanitizedStatement)", duration: duration)
    }
    
    // MARK: - Private Logging Helper
    
    private func logPerformance(operation: String, duration: TimeInterval) {
        // Format duration to milliseconds for readability.
        let durationInMS = duration * 1000
        
        // Log to both the console and the unified logging system.
        // This allows viewing logs in both Xcode and the Console app.
        logger.info("⏱️ PERFORMANCE [\(operation)]: \(String(format: "%.2f", durationInMS)) ms")
        
        // In the future, this could also send the metric to a dedicated analytics service.
        // Example: AnalyticsManager.shared.trackTiming(category: "performance", interval: duration, name: operation)
    }
}