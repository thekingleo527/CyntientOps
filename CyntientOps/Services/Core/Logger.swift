//
//  Logger.swift
//  CyntientOps
//
//  🎯 PRODUCTION LOGGING: Replaces print statements with proper logging
//  ✅ PERFORMANCE: Conditional logging based on build configuration
//  ✅ STRUCTURED: Different log levels and categories
//

import Foundation
import os.log

@MainActor
public class CyntientLogger {
    public static let shared = CyntientLogger()
    
    // MARK: - Log Categories
    private let appLifecycleLog = OSLog(subsystem: "com.cyntientops.app", category: "AppLifecycle")
    private let databaseLog = OSLog(subsystem: "com.cyntientops.app", category: "Database")
    private let authLog = OSLog(subsystem: "com.cyntientops.app", category: "Authentication")
    private let apiLog = OSLog(subsystem: "com.cyntientops.app", category: "API")
    private let uiLog = OSLog(subsystem: "com.cyntientops.app", category: "UI")
    private let operationalLog = OSLog(subsystem: "com.cyntientops.app", category: "Operations")
    
    private init() {}
    
    // MARK: - Public Logging Methods
    
    public func info(_ message: String, category: LogCategory = .general) {
        #if DEBUG
        print("ℹ️ [\(category.rawValue)] \(message)")
        #endif
        os_log("%{public}@", log: logForCategory(category), type: .info, message)
    }
    
    public func debug(_ message: String, category: LogCategory = .general) {
        #if DEBUG
        print("🐛 [\(category.rawValue)] \(message)")
        #endif
        os_log("%{public}@", log: logForCategory(category), type: .debug, message)
    }
    
    public func warning(_ message: String, category: LogCategory = .general) {
        #if DEBUG
        print("⚠️ [\(category.rawValue)] \(message)")
        #endif
        os_log("%{public}@", log: logForCategory(category), type: .default, message)
    }
    
    public func error(_ message: String, category: LogCategory = .general, error: Error? = nil) {
        let fullMessage = error != nil ? "\(message) - Error: \(error!.localizedDescription)" : message
        #if DEBUG
        print("❌ [\(category.rawValue)] \(fullMessage)")
        #endif
        os_log("%{public}@", log: logForCategory(category), type: .error, fullMessage)
    }
    
    public func success(_ message: String, category: LogCategory = .general) {
        #if DEBUG
        print("✅ [\(category.rawValue)] \(message)")
        #endif
        os_log("%{public}@", log: logForCategory(category), type: .info, message)
    }
    
    // MARK: - Performance Logging
    
    public func startPerformanceTimer(_ identifier: String) -> PerformanceTimer {
        return PerformanceTimer(identifier: identifier, logger: self)
    }
    
    // MARK: - Private Methods
    
    private func logForCategory(_ category: LogCategory) -> OSLog {
        switch category {
        case .appLifecycle: return appLifecycleLog
        case .database: return databaseLog
        case .authentication: return authLog
        case .api: return apiLog
        case .ui: return uiLog
        case .operations: return operationalLog
        case .general: return OSLog.default
        }
    }
}

// MARK: - Log Categories

public enum LogCategory: String, CaseIterable {
    case general = "General"
    case appLifecycle = "AppLifecycle"
    case database = "Database"
    case authentication = "Auth"
    case api = "API"
    case ui = "UI"
    case operations = "Operations"
}

// MARK: - Performance Timer

public class PerformanceTimer {
    private let identifier: String
    private let startTime: CFAbsoluteTime
    private let logger: CyntientLogger
    
    init(identifier: String, logger: CyntientLogger) {
        self.identifier = identifier
        self.startTime = CFAbsoluteTimeGetCurrent()
        self.logger = logger
    }
    
    public func end() {
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("⏱️ \(identifier) completed in \(String(format: "%.3f", timeElapsed))s", category: .operations)
    }
}

// MARK: - Global Convenience Functions

public func print(_ message: String, category: LogCategory = .general) {
    CyntientLogger.shared.info(message, category: category)
}

public func logDebug(_ message: String, category: LogCategory = .general) {
    CyntientLogger.shared.debug(message, category: category)
}

public func logWarning(_ message: String, category: LogCategory = .general) {
    CyntientLogger.shared.warning(message, category: category)
}

public func logError(_ message: String, category: LogCategory = .general, error: Error? = nil) {
    CyntientLogger.shared.error(message, category: category, error: error)
}

public func logSuccess(_ message: String, category: LogCategory = .general) {
    CyntientLogger.shared.success(message, category: category)
}