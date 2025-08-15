//
//  ProductionConfiguration.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 8/4/25.
//


//
//  ProductionConfiguration.swift
//  CyntientOps (formerly CyntientOps)
//
//  Phase 0.4: Production Configuration
//  Centralized configuration for production environment
//

import Foundation

public struct ProductionConfiguration {
    
    // MARK: - Environment
    public enum Environment: String {
        case development = "development"
        case staging = "staging"
        case production = "production"
        
        public var isProduction: Bool {
            self == .production
        }
        
        public var isDebug: Bool {
            // PRODUCTION DEPLOYMENT: Always return false for production
            return false
        }
    }
    
    // MARK: - Current Environment
    public static var environment: Environment {
        // PRODUCTION DEPLOYMENT: Always use production environment
        // Check for staging flag or default to production
        if ProcessInfo.processInfo.environment["STAGING"] != nil {
            return .staging
        }
        return .production
    }
    
    // MARK: - API Configuration
    public struct API {
        public static var baseURL: String {
            switch environment {
            case .development:
                return "https://dev-api.cyntientops.com/v1"
            case .staging:
                return "https://staging-api.cyntientops.com/v1"
            case .production:
                return "https://api.cyntientops.com/v1"
            }
        }
        
        public static let timeout: TimeInterval = 30.0
        public static let maxRetries = 3
        public static let retryDelay: TimeInterval = 2.0
        
        // API Keys (retrieved from Keychain in production)
        public static var apiKey: String {
            // In production, this would be retrieved from KeychainManager
            return "prod_api_key_placeholder"
        }
    }
    
    // MARK: - Database Configuration
    public struct Database {
        public static let name = "cyntientops.sqlite"
        public static let encryptionEnabled = environment.isProduction
        public static let backupEnabled = true
        public static let backupRetentionDays = 30
        
        // Connection pool settings
        public static let maxConnections = 10
        public static let connectionTimeout: TimeInterval = 5.0
    }
    
    // MARK: - Security Configuration
    public struct Security {
        public static let sessionDuration: TimeInterval = 8 * 60 * 60 // 8 hours
        public static let sessionRefreshThreshold: TimeInterval = 30 * 60 // 30 minutes
        public static let maxLoginAttempts = 5
        public static let lockoutDuration: TimeInterval = 15 * 60 // 15 minutes
        
        // Password requirements
        public static let minPasswordLength = 8
        public static let requireUppercase = true
        public static let requireLowercase = true
        public static let requireNumbers = true
        public static let requireSpecialChars = true
        
        // Biometric settings
        public static let biometricEnabled = true
        public static let biometricTimeout: TimeInterval = 5 * 60 // 5 minutes
    }
    
    // MARK: - Photo Configuration
    public struct Photos {
        public static let maxPhotoSize: Int = 5 * 1024 * 1024 // 5MB
        public static let compressionQuality: Double = 0.8
        public static let thumbnailSize = CGSize(width: 200, height: 200)
        public static let encryptionEnabled = true
        public static let expirationHours = 24
        
        // Storage paths
        public static let storageDirectory = "Photos"
        public static let thumbnailDirectory = "Thumbnails"
    }
    
    // MARK: - Sync Configuration
    public struct Sync {
        public static let autoSyncEnabled = true
        public static let syncInterval: TimeInterval = 5 * 60 // 5 minutes
        public static let batchSize = 50
        public static let maxRetries = 3
        
        // WebSocket settings
        public static var websocketURL: String {
            switch environment {
            case .development:
                return "wss://dev-ws.cyntientops.com"
            case .staging:
                return "wss://staging-ws.cyntientops.com"
            case .production:
                return "wss://ws.cyntientops.com"
            }
        }
    }
    
    // MARK: - Analytics Configuration
    public struct Analytics {
        public static let enabled = environment.isProduction
        public static let sessionTimeout: TimeInterval = 30 * 60 // 30 minutes
        public static let batchSize = 100
        public static let flushInterval: TimeInterval = 60 // 1 minute
        
        // Sentry DSN
        public static var sentryDSN: String {
            switch environment {
            case .development:
                return "" // No Sentry in development
            case .staging:
                return "https://c77b2dddf9eca868ead5142d23a438cf@o4509764891901952.ingest.us.sentry.io/4509764893081600"
            case .production:
                return "https://c77b2dddf9eca868ead5142d23a438cf@o4509764891901952.ingest.us.sentry.io/4509764893081600"
            }
        }
    }
    
    // MARK: - Feature Flags
    public struct Features {
        public static let advancedAnalytics = true
        public static let offlineMode = true
        public static let voiceCommands = false // Coming soon
        public static let arNavigation = false // Coming soon
        public static let quickBooksIntegration = true
        public static let weatherIntegration = true
        public static let emergencyTasks = true
        public static let simplifiedUI = true // For Mercedes
        public static let eveningMode = true // For Angel
    }
    
    // MARK: - Company Information
    public struct Company {
        public static let name = "Franco Management Enterprises"
        public static let shortName = "FME"
        public static let supportEmail = "support@cyntientops.com"
        public static let supportPhone = "+1 (212) 555-0100"
        public static let websiteURL = "https://www.cyntientops.com"
    }
    
    // MARK: - Default Values
    public struct Defaults {
        public static let language = "en"
        public static let timeZone = TimeZone(identifier: "America/New_York")!
        public static let calendar = Calendar(identifier: .gregorian)
        public static let firstDayOfWeek = 2 // Monday
        public static let workingHoursStart = 6 // 6 AM
        public static let workingHoursEnd = 22 // 10 PM
    }
    
    // MARK: - Debug Settings
    public struct Debug {
        public static let verboseLogging = !environment.isProduction
        public static let mockDataEnabled = environment == .development
        public static let skipAuthentication = false
        public static let showDebugMenu = !environment.isProduction
        public static let crashlyticsEnabled = environment != .development
    }
    
    // MARK: - Helper Methods
    
    /// Get configuration value with fallback
    public static func getValue<T>(_ key: String, default defaultValue: T) -> T {
        // In production, this could read from a remote config service
        return defaultValue
    }
    
    /// Check if feature is enabled
    public static func isFeatureEnabled(_ feature: String) -> Bool {
        // In production, this could check against a feature flag service
        return true
    }
    
    /// Log configuration on startup
    public static func logConfiguration() {
        print("🔧 CyntientOps Configuration")
        print("   Environment: \(environment.rawValue)")
        print("   API URL: \(API.baseURL)")
        print("   WebSocket URL: \(Sync.websocketURL)")
        print("   Database: \(Database.name)")
        print("   Features:")
        print("     - Offline Mode: \(Features.offlineMode)")
        print("     - QuickBooks: \(Features.quickBooksIntegration)")
        print("     - Weather: \(Features.weatherIntegration)")
        print("     - Simplified UI: \(Features.simplifiedUI)")
    }
}