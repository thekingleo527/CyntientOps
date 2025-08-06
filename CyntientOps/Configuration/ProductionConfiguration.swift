// ===================================================================
// SPRINT 4: PRODUCTION DEPLOYMENT & LAUNCH
// File: Configuration/ProductionConfiguration.swift
// ===================================================================

import Foundation
import UIKit

// MARK: - Production Configuration Manager

public final class ProductionConfiguration {
    
    // MARK: - Environment
    
    public enum Environment: String {
        case development = "dev"
        case staging = "staging"
        case production = "prod"
        
        public var baseURL: String {
            switch self {
            case .development:
                return "https://dev-api.cyntientops.com"
            case .staging:
                return "https://staging-api.cyntientops.com"
            case .production:
                return "https://api.cyntientops.com"
            }
        }
        
        public var nycAPIKey: String {
            switch self {
            case .development, .staging:
                return "TEST_NYC_API_KEY_DEV"
            case .production:
                return ProcessInfo.processInfo.environment["NYC_API_KEY"] ?? ""
            }
        }
    }
    
    // MARK: - Current Environment
    
    public static var currentEnvironment: Environment {
        #if DEBUG
        return .development
        #else
        if let envString = ProcessInfo.processInfo.environment["APP_ENVIRONMENT"],
           let env = Environment(rawValue: envString) {
            return env
        }
        return .production
        #endif
    }
    
    // MARK: - Feature Flags
    
    public struct FeatureFlags {
        public static var isNYCAPIEnabled: Bool {
            return currentEnvironment == .production || 
                   UserDefaults.standard.bool(forKey: "feature.nycAPI.enabled")
        }
        
        public static var isOfflineQueueEnabled: Bool {
            return true // Always enabled
        }
        
        public static var isComplianceSuiteEnabled: Bool {
            return currentEnvironment == .production
        }
        
        public static var isNovaAIEnabled: Bool {
            return true // Always enabled
        }
        
        public static var isAdvancedAnalyticsEnabled: Bool {
            return currentEnvironment == .production
        }
    }
    
    // MARK: - API Configuration
    
    public struct APIConfig {
        public static let timeout: TimeInterval = 30
        public static let maxRetries: Int = 3
        public static let batchSize: Int = 50
        
        public static var headers: [String: String] {
            return [
                "X-App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                "X-Build-Number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
                "X-Platform": "iOS",
                "X-Device-Model": UIDevice.current.model,
                "X-OS-Version": UIDevice.current.systemVersion,
                "X-Environment": currentEnvironment.rawValue
            ]
        }
    }
    
    // MARK: - Monitoring & Analytics
    
    public struct Monitoring {
        public static let sentryDSN = "https://your-sentry-dsn@sentry.io/project-id"
        public static let mixpanelToken = "your-mixpanel-token"
        public static let firebaseProjectID = "cyntientops-prod"
        
        public static var isEnabled: Bool {
            return currentEnvironment == .production
        }
    }
}