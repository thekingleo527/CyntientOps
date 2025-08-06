//
//  Credentials.swift
//  CyntientOps
//
//  ⚠️ SECURITY WARNING: ADD TO .gitignore - NEVER COMMIT WITH REAL VALUES
//  This file contains placeholder values for all required API credentials
//  Replace placeholders with real values for production deployment
//

import Foundation

/// Centralized credential management for all external services
/// Based on comprehensive credentials guide provided
enum Credentials {
    
    // MARK: - NYC Government APIs
    
    /// DSNY (Department of Sanitation) API Token
    /// Status: Optional - App works without token but with 1000/hour limit
    /// With token: 50,000/hour rate limit
    /// Obtain: https://data.cityofnewyork.us/signup
    static let DSNY_API_TOKEN = ProcessInfo.processInfo.environment["DSNY_API_TOKEN"] ?? "PLACEHOLDER_DSNY_TOKEN"
    
    /// HPD (Housing Preservation & Development) API
    /// Status: Required for violation tracking
    /// Obtain: Contact HPDData@hpd.nyc.gov
    static let HPD_API_KEY = ProcessInfo.processInfo.environment["HPD_API_KEY"] ?? "PLACEHOLDER_HPD_KEY"
    static let HPD_API_SECRET = ProcessInfo.processInfo.environment["HPD_API_SECRET"] ?? "PLACEHOLDER_HPD_SECRET"
    
    /// DOB (Department of Buildings) API
    /// Status: Required for permits and inspections
    /// Obtain: https://www1.nyc.gov/site/buildings/business/dobnow-api.page
    static let DOB_SUBSCRIBER_KEY = ProcessInfo.processInfo.environment["DOB_SUBSCRIBER_KEY"] ?? "PLACEHOLDER_DOB_KEY"
    static let DOB_ACCESS_TOKEN = ProcessInfo.processInfo.environment["DOB_ACCESS_TOKEN"] ?? "PLACEHOLDER_DOB_TOKEN"
    
    /// DEP (Department of Environmental Protection) API
    /// Status: Required for water usage monitoring
    /// Obtain: Call DEP at 718-595-7000
    static let DEP_ACCOUNT_NUMBER = ProcessInfo.processInfo.environment["DEP_ACCOUNT_NUMBER"] ?? "PLACEHOLDER_DEP_ACCOUNT"
    static let DEP_API_PIN = ProcessInfo.processInfo.environment["DEP_API_PIN"] ?? "PLACEHOLDER_DEP_PIN"
    
    // MARK: - QuickBooks Integration
    
    /// QuickBooks Online API v3 Credentials
    /// Status: CRITICAL - Required for payroll export
    /// Obtain: https://developer.intuit.com
    static let QUICKBOOKS_CLIENT_ID = ProcessInfo.processInfo.environment["QB_CLIENT_ID"] ?? "AB6xJdGBkSZCjdpTjKL1bM9YJnk4TRBuKJJdN8EfXIa8QJ5VvL" // Current placeholder
    static let QUICKBOOKS_CLIENT_SECRET = ProcessInfo.processInfo.environment["QB_CLIENT_SECRET"] ?? "LNzb8C2GQ5xjF4K7H8J9L2M3N4P5Q6R7S8T9U0V1W2X3Y4Z5A6" // Current placeholder
    static let QUICKBOOKS_COMPANY_ID = ProcessInfo.processInfo.environment["QB_COMPANY_ID"] ?? "PLACEHOLDER_REALM_ID"
    static let QUICKBOOKS_WEBHOOK_TOKEN = ProcessInfo.processInfo.environment["QB_WEBHOOK_TOKEN"] ?? "PLACEHOLDER_WEBHOOK_TOKEN"
    
    /// QuickBooks Sandbox Credentials (for testing)
    static let QB_SANDBOX_CLIENT_ID = "ABkpeoQTBQgpqMHLywGgMTZwggXW9kzJr2eKJG"
    static let QB_SANDBOX_SECRET = "kaFfLJDFmCHtYkvGHJYfcmXnWfXnVJzdWJKNhs"
    static let QB_SANDBOX_COMPANY = "4620816365169846390"
    
    // MARK: - Backend Services
    
    /// CyntientOps Backend WebSocket Server
    /// Status: CRITICAL - Required for real-time sync
    /// Current: Configured for localhost development
    static let WEBSOCKET_URL = ProcessInfo.processInfo.environment["WEBSOCKET_URL"] ?? "ws://localhost:8080/sync"
    static let WEBSOCKET_AUTH_TOKEN = ProcessInfo.processInfo.environment["WEBSOCKET_AUTH_TOKEN"] ?? "PLACEHOLDER_JWT_TOKEN"
    static let API_BASE_URL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:8080"
    static let API_KEY = ProcessInfo.processInfo.environment["API_KEY"] ?? "PLACEHOLDER_API_KEY"
    
    // MARK: - Analytics & Monitoring
    
    /// Sentry.io Crash Reporting
    /// Status: Recommended for production monitoring
    /// Obtain: https://sentry.io
    static let SENTRY_DSN = ProcessInfo.processInfo.environment["SENTRY_DSN"] ?? "PLACEHOLDER_SENTRY_DSN"
    
    // MARK: - Third-Party Integrations
    
    /// Google Calendar API v3
    /// Status: Optional - For task scheduling sync
    /// Obtain: https://console.cloud.google.com
    static let GOOGLE_CLIENT_ID = ProcessInfo.processInfo.environment["GOOGLE_CLIENT_ID"] ?? "PLACEHOLDER_GOOGLE_CLIENT_ID"
    static let GOOGLE_API_KEY = ProcessInfo.processInfo.environment["GOOGLE_API_KEY"] ?? "PLACEHOLDER_GOOGLE_API_KEY"
    
    /// Slack Web API
    /// Status: Optional - For alert notifications
    /// Obtain: https://api.slack.com/apps
    static let SLACK_BOT_TOKEN = ProcessInfo.processInfo.environment["SLACK_BOT_TOKEN"] ?? "PLACEHOLDER_SLACK_BOT_TOKEN"
    static let SLACK_WEBHOOK_URL = ProcessInfo.processInfo.environment["SLACK_WEBHOOK_URL"] ?? "PLACEHOLDER_SLACK_WEBHOOK"
    
    /// Con Edison Energy API
    /// Status: Optional - For outage notifications
    /// Obtain: https://www.coned.com/en/accounts-billing/share-energy-usage-data
    static let CONED_ACCOUNT_NUMBER = ProcessInfo.processInfo.environment["CONED_ACCOUNT_NUMBER"] ?? "PLACEHOLDER_CONED_ACCOUNT"
    static let CONED_API_USERNAME = ProcessInfo.processInfo.environment["CONED_API_USERNAME"] ?? "PLACEHOLDER_CONED_USERNAME"
    static let CONED_API_PASSWORD = ProcessInfo.processInfo.environment["CONED_API_PASSWORD"] ?? "PLACEHOLDER_CONED_PASSWORD"
    
    // MARK: - Weather Service (NO CREDENTIALS NEEDED!)
    
    /// OpenMeteo Weather API
    /// Status: ✅ FULLY WORKING - Completely free, no registration required
    /// No credentials needed - already configured in WeatherDataAdapter.swift
    
    // MARK: - Apple Developer
    
    /// Apple Developer Program Credentials
    /// Status: CRITICAL - Required for deployment
    static let APPLE_TEAM_ID = ProcessInfo.processInfo.environment["APPLE_TEAM_ID"] ?? "PLACEHOLDER_TEAM_ID"
    static let BUNDLE_ID = "com.francomanagement.cyntientops" // Current bundle ID
    static let APNS_KEY_ID = ProcessInfo.processInfo.environment["APNS_KEY_ID"] ?? "PLACEHOLDER_APNS_KEY_ID"
}

// MARK: - Demo Mode Configuration

/// Demo mode for testing without real credentials
enum DemoMode {
    /// Enable demo mode when credentials are missing
    static let isEnabled: Bool = {
        // Check if critical credentials are placeholders
        let hasQuickBooksCredentials = !Credentials.QUICKBOOKS_CLIENT_ID.contains("PLACEHOLDER")
        let hasBackendCredentials = !Credentials.WEBSOCKET_URL.contains("localhost") && !Credentials.API_KEY.contains("PLACEHOLDER")
        
        // Enable demo mode if critical credentials are missing
        return !hasQuickBooksCredentials || !hasBackendCredentials
    }()
    
    /// Mock DSNY response for demo mode
    static let mockDSNYResponse = """
    {
        "district_section": "MN05",
        "regular_coll": "MON/THU", 
        "recycle_coll": "TUE",
        "organic_coll": "WED"
    }
    """
    
    /// Mock QuickBooks employees for demo mode
    static let mockQuickBooksEmployees = [
        "Greg Hutson", "Edwin Lema", "Kevin Dutan",
        "Mercedes Inamagua", "Luis Lopez", "Angel Guiracocha", "Shawn Magloire"
    ]
    
    /// Mock WebSocket messages for demo mode
    static let mockWebSocketMessages = [
        "task_completed", "worker_clocked_in", "building_alert",
        "compliance_warning", "route_optimized", "weather_alert"
    ]
    
    /// Mock violation data for demo mode
    static let mockHPDViolations = [
        "LEAD PAINT", "WATER LEAK", "HEATING FAILURE", "PEST INFESTATION"
    ]
    
    /// Mock permit data for demo mode
    static let mockDOBPermits = [
        "ALT1 - Major Alteration", "PL1 - Plumbing Work", "ELE - Electrical Work"
    ]
}

// MARK: - Credential Validation

extension Credentials {
    /// Check if credential is a placeholder value
    static func isPlaceholder(_ credential: String) -> Bool {
        return credential.contains("PLACEHOLDER") || 
               credential.isEmpty || 
               credential.count < 10
    }
    
    /// Get credential status for monitoring
    static func getCredentialStatus() -> [String: String] {
        return [
            "DSNY": isPlaceholder(DSNY_API_TOKEN) ? "Missing (Rate Limited)" : "Configured",
            "HPD": isPlaceholder(HPD_API_KEY) ? "Missing (No Violations)" : "Configured",
            "DOB": isPlaceholder(DOB_SUBSCRIBER_KEY) ? "Missing (No Permits)" : "Configured",
            "QuickBooks": isPlaceholder(QUICKBOOKS_CLIENT_ID) ? "Missing (No Payroll)" : "Configured",
            "Backend": isPlaceholder(API_KEY) ? "Missing (No Sync)" : "Configured",
            "Sentry": isPlaceholder(SENTRY_DSN) ? "Missing (No Monitoring)" : "Configured",
            "Demo Mode": DemoMode.isEnabled ? "Enabled" : "Disabled"
        ]
    }
    
    /// Priority order for credential implementation
    static func getCredentialPriorities() -> [String: Int] {
        return [
            "QuickBooks": 1,        // Must have for payroll
            "Backend": 2,           // Must have for sync
            "Apple Developer": 3,   // Must have for deployment
            "DSNY": 4,             // Should have (works without)
            "Sentry": 5,           // Should have for monitoring
            "HPD": 6,              // Should have for violations
            "DOB": 7,              // Should have for permits
            "Google": 8,           // Nice to have
            "Slack": 9,            // Nice to have
            "DEP": 10,             // Nice to have
            "Con Edison": 11       // Nice to have
        ]
    }
}