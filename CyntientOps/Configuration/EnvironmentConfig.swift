//
//  EnvironmentConfig.swift
//  CyntientOps
//
//  Environment configuration for different deployment targets
//

import Foundation

// Renamed from 'Environment' to 'AppEnvironment' to avoid SwiftUI conflicts
enum AppEnvironment: String {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:8080"
        case .staging:
            return "https://staging-api.francosphere.com"
        case .production:
            return "https://api.francosphere.com"
        }
    }
    
    var websocketURL: String {
        switch self {
        case .development:
            return "ws://localhost:8080/sync"
        case .staging:
            return "wss://staging-api.francosphere.com/sync"
        case .production:
            return "wss://api.francosphere.com/sync"
        }
    }
    
    var isDebugEnabled: Bool {
        switch self {
        case .development, .staging:
            return true
        case .production:
            return false
        }
    }
}

final class EnvironmentConfig {
    static let shared = EnvironmentConfig()
    
    let current: AppEnvironment
    
    private init() {
        #if DEBUG
        self.current = .development
        #elseif STAGING
        self.current = .staging
        #else
        self.current = .production
        #endif
    }
    
    var baseURL: String {
        current.baseURL
    }
    
    var websocketURL: String {
        current.websocketURL
    }
    
    var isDebugEnabled: Bool {
        current.isDebugEnabled
    }
    
    /// Check if app is running in demo mode (missing critical credentials)
    var isDemoMode: Bool {
        // Simple demo mode check - app runs in demo mode during development
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Get comprehensive credential status for debugging
    var credentialStatus: [String: String] {
        return [
            "Environment": current.rawValue,
            "Debug": isDebugEnabled ? "Enabled" : "Disabled",
            "Demo Mode": isDemoMode ? "Enabled" : "Disabled"
        ]
    }
}

// MARK: - API Configuration Extensions

extension EnvironmentConfig {
    
    // DSNY API configuration
    var dsnyAPIToken: String? {
        // Return nil for now - can be configured via environment variables
        return ProcessInfo.processInfo.environment["DSNY_API_TOKEN"]
    }
    
    var dsnyAPIBaseURL: String {
        "https://data.cityofnewyork.us/resource"
    }
    
    // NYC APIs configuration
    var nycAPIConfiguration: NYCAPIConfig {
        return NYCAPIConfig(
            hpdKey: ProcessInfo.processInfo.environment["HPD_API_KEY"] ?? "PLACEHOLDER_HPD_KEY",
            hpdSecret: ProcessInfo.processInfo.environment["HPD_API_SECRET"] ?? "PLACEHOLDER_HPD_SECRET",
            dobSubscriberKey: ProcessInfo.processInfo.environment["DOB_SUBSCRIBER_KEY"] ?? "PLACEHOLDER_DOB_KEY",
            dobAccessToken: ProcessInfo.processInfo.environment["DOB_ACCESS_TOKEN"] ?? "PLACEHOLDER_DOB_TOKEN",
            depAccountNumber: ProcessInfo.processInfo.environment["DEP_ACCOUNT_NUMBER"] ?? "PLACEHOLDER_DEP_ACCOUNT",
            depPin: ProcessInfo.processInfo.environment["DEP_API_PIN"] ?? "PLACEHOLDER_DEP_PIN"
        )
    }
    
    // QuickBooks configuration
    var quickBooksConfiguration: QuickBooksConfig {
        // Use sandbox credentials for now
        let clientId = ProcessInfo.processInfo.environment["QB_CLIENT_ID"] ?? "AB6xJdGBkSZCjdpTjKL1bM9YJnk4TRBuKJJdN8EfXIa8QJ5VvL"
        let isPlaceholder = clientId.contains("PLACEHOLDER") || clientId.isEmpty || clientId.count < 10
        let useProduction = !isPlaceholder
        
        return QuickBooksConfig(
            clientId: useProduction ? clientId : "ABkpeoQTBQgpqMHLywGgMTZwggXW9kzJr2eKJG",
            clientSecret: useProduction ? (ProcessInfo.processInfo.environment["QB_CLIENT_SECRET"] ?? "LNzb8C2GQ5xjF4K7H8J9L2M3N4P5Q6R7S8T9U0V1W2X3Y4Z5A6") : "kaFfLJDFmCHtYkvGHJYfcmXnWfXnVJzdWJKNhs",
            companyId: useProduction ? (ProcessInfo.processInfo.environment["QB_COMPANY_ID"] ?? "PLACEHOLDER_REALM_ID") : "4620816365169846390",
            webhookToken: ProcessInfo.processInfo.environment["QB_WEBHOOK_TOKEN"] ?? "PLACEHOLDER_WEBHOOK_TOKEN",
            isSandbox: !useProduction
        )
    }
    
    // Backend configuration
    var backendConfiguration: BackendConfig {
        return BackendConfig(
            apiBaseURL: ProcessInfo.processInfo.environment["API_BASE_URL"] ?? baseURL,
            websocketURL: ProcessInfo.processInfo.environment["WEBSOCKET_URL"] ?? websocketURL,
            apiKey: ProcessInfo.processInfo.environment["API_KEY"] ?? "PLACEHOLDER_API_KEY",
            authToken: ProcessInfo.processInfo.environment["WEBSOCKET_AUTH_TOKEN"] ?? "PLACEHOLDER_JWT_TOKEN"
        )
    }
    
    // Monitoring configuration
    var monitoringConfiguration: MonitoringConfig {
        let sentryDSN = ProcessInfo.processInfo.environment["SENTRY_DSN"] ?? "PLACEHOLDER_SENTRY_DSN"
        let isPlaceholder = sentryDSN.contains("PLACEHOLDER") || sentryDSN.isEmpty || sentryDSN.count < 10
        
        return MonitoringConfig(
            sentryDSN: isPlaceholder ? nil : sentryDSN,
            isAnalyticsEnabled: !isDemoMode
        )
    }
}

// MARK: - Configuration Structs

struct NYCAPIConfig {
    let hpdKey: String
    let hpdSecret: String
    let dobSubscriberKey: String
    let dobAccessToken: String
    let depAccountNumber: String
    let depPin: String
    
    var isHPDConfigured: Bool {
        !isPlaceholder(hpdKey) && !isPlaceholder(hpdSecret)
    }
    
    var isDOBConfigured: Bool {
        !isPlaceholder(dobSubscriberKey) && !isPlaceholder(dobAccessToken)
    }
    
    var isDEPConfigured: Bool {
        !isPlaceholder(depAccountNumber) && !isPlaceholder(depPin)
    }
    
    private func isPlaceholder(_ credential: String) -> Bool {
        return credential.contains("PLACEHOLDER") || credential.isEmpty || credential.count < 10
    }
}

struct QuickBooksConfig {
    let clientId: String
    let clientSecret: String
    let companyId: String
    let webhookToken: String
    let isSandbox: Bool
    
    var isConfigured: Bool {
        !isPlaceholder(clientId) && !isPlaceholder(clientSecret)
    }
    
    private func isPlaceholder(_ credential: String) -> Bool {
        return credential.contains("PLACEHOLDER") || credential.isEmpty || credential.count < 10
    }
}

struct BackendConfig {
    let apiBaseURL: String
    let websocketURL: String
    let apiKey: String
    let authToken: String
    
    var isConfigured: Bool {
        !isPlaceholder(apiKey) && !websocketURL.contains("localhost")
    }
    
    private func isPlaceholder(_ credential: String) -> Bool {
        return credential.contains("PLACEHOLDER") || credential.isEmpty || credential.count < 10
    }
}

struct MonitoringConfig {
    let sentryDSN: String?
    let isAnalyticsEnabled: Bool
    
    var isSentryConfigured: Bool {
        guard let dsn = sentryDSN else { return false }
        return !isPlaceholder(dsn)
    }
    
    private func isPlaceholder(_ credential: String) -> Bool {
        return credential.contains("PLACEHOLDER") || credential.isEmpty || credential.count < 10
    }
}
