//
//  ProductionCredentialsManager.swift
//  CyntientOps Production
//
//  Secure credential management for production deployment
//  Handles API keys, tokens, and sensitive configuration
//

import Foundation
import Security

@MainActor
public final class ProductionCredentialsManager: ObservableObject {
    
    public static let shared = ProductionCredentialsManager()
    
    private let keychainService = "com.cyntientops.credentials"
    
    // MARK: - Published Properties
    @Published public var credentialsStatus: [String: CredentialStatus] = [:]
    @Published public var isProductionReady = false
    
    public enum CredentialStatus {
        case valid
        case missing
        case invalid
        case expired
    }
    
    private init() {
        Task {
            await validateAllCredentials()
        }
    }
    
    // MARK: - Credential Validation
    
    /// Validate all critical credentials for production readiness
    public func validateAllCredentials() async {
        let criticalCredentials = [
            "QUICKBOOKS_CLIENT_ID": Credentials.QUICKBOOKS_CLIENT_ID,
            "QUICKBOOKS_CLIENT_SECRET": Credentials.QUICKBOOKS_CLIENT_SECRET,
            "HPD_API_KEY": Credentials.HPD_API_KEY,
            "DOB_SUBSCRIBER_KEY": Credentials.DOB_SUBSCRIBER_KEY,
            "DSNY_API_TOKEN": Credentials.DSNY_API_TOKEN,
            "API_BASE_URL": Credentials.API_BASE_URL,
            "WEBSOCKET_URL": Credentials.WEBSOCKET_URL
        ]
        
        var allValid = true
        
        for (key, value) in criticalCredentials {
            let status = validateCredential(key: key, value: value)
            credentialsStatus[key] = status
            
            if status != .valid {
                allValid = false
                print("❌ Invalid credential: \(key)")
            } else {
                print("✅ Valid credential: \(key)")
            }
        }
        
        isProductionReady = allValid
        
        if allValid {
            print("🎉 All credentials validated - PRODUCTION READY")
        } else {
            print("⚠️ Missing or invalid credentials - NOT PRODUCTION READY")
        }
    }
    
    private func validateCredential(key: String, value: String) -> CredentialStatus {
        // Check if value is placeholder
        if value.contains("PLACEHOLDER") || value.contains("localhost") || value.isEmpty {
            return .missing
        }
        
        // Validate specific credential formats
        switch key {
        case "QUICKBOOKS_CLIENT_ID", "QUICKBOOKS_CLIENT_SECRET":
            return value.count >= 30 ? .valid : .invalid
        case "HPD_API_KEY", "DOB_SUBSCRIBER_KEY":
            return value.count >= 20 ? .valid : .invalid  
        case "DSNY_API_TOKEN":
            return value.count >= 10 ? .valid : .invalid
        case "API_BASE_URL", "WEBSOCKET_URL":
            return value.hasPrefix("https://") || value.hasPrefix("wss://") ? .valid : .invalid
        default:
            return value.count > 5 ? .valid : .invalid
        }
    }
    
    // MARK: - Secure Storage
    
    /// Store credential securely in Keychain
    public func storeCredential(key: String, value: String) -> Bool {
        guard !value.isEmpty else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: value.data(using: .utf8)!
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("🔐 Stored credential: \(key)")
            return true
        } else {
            print("❌ Failed to store credential: \(key)")
            return false
        }
    }
    
    /// Retrieve credential from Keychain
    public func retrieveCredential(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let credential = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return credential
    }
    
    /// Delete credential from Keychain
    public func deleteCredential(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Production Setup
    
    /// Setup credentials for production deployment
    public func setupProductionCredentials() async -> Bool {
        print("🚀 Setting up production credentials...")
        
        let requiredCredentials = [
            "QUICKBOOKS_CLIENT_ID",
            "QUICKBOOKS_CLIENT_SECRET", 
            "QUICKBOOKS_COMPANY_ID",
            "HPD_API_KEY",
            "HPD_API_SECRET",
            "DOB_SUBSCRIBER_KEY",
            "DOB_ACCESS_TOKEN",
            "DSNY_API_TOKEN",
            "DEP_ACCOUNT_NUMBER",
            "DEP_API_PIN",
            "API_BASE_URL",
            "WEBSOCKET_URL",
            "WEBSOCKET_AUTH_TOKEN",
            "APPLE_TEAM_ID"
        ]
        
        var missingCredentials: [String] = []
        
        for credential in requiredCredentials {
            if retrieveCredential(key: credential) == nil {
                missingCredentials.append(credential)
            }
        }
        
        if !missingCredentials.isEmpty {
            print("❌ Missing production credentials:")
            for credential in missingCredentials {
                print("  • \(credential)")
            }
            
            print("\n📝 To complete production setup:")
            print("1. Obtain all required API credentials")
            print("2. Set environment variables or use Keychain")
            print("3. Run setupProductionCredentials() again")
            
            return false
        }
        
        await validateAllCredentials()
        return isProductionReady
    }
    
    /// Generate credential setup instructions
    public func generateSetupInstructions() -> String {
        return """
        # CyntientOps Production Credential Setup
        
        ## Required API Credentials:
        
        ### 1. QuickBooks Online Integration
        - QUICKBOOKS_CLIENT_ID: Get from Intuit Developer Console
        - QUICKBOOKS_CLIENT_SECRET: Get from Intuit Developer Console
        - QUICKBOOKS_COMPANY_ID: Your QuickBooks company ID
        
        ### 2. NYC Government APIs
        - HPD_API_KEY: Contact HPDData@hpd.nyc.gov
        - HPD_API_SECRET: From HPD Developer Account
        - DOB_SUBSCRIBER_KEY: From NYC DOB API Portal
        - DOB_ACCESS_TOKEN: From NYC DOB API Portal
        - DSNY_API_TOKEN: From NYC OpenData Portal (optional)
        - DEP_ACCOUNT_NUMBER: Your DEP account number
        - DEP_API_PIN: From DEP Customer Portal
        
        ### 3. Backend Services
        - API_BASE_URL: Your backend API URL (https://)
        - WEBSOCKET_URL: Your WebSocket server URL (wss://)
        - WEBSOCKET_AUTH_TOKEN: JWT token for WebSocket auth
        
        ### 4. Apple Developer
        - APPLE_TEAM_ID: From Apple Developer Portal
        
        ## Setup Instructions:
        
        1. Set environment variables in Xcode Scheme:
           - Product -> Scheme -> Edit Scheme -> Arguments -> Environment Variables
        
        2. Or use secure storage (recommended):
           - Call storeCredential(key:value:) for each credential
        
        3. Validate with validateAllCredentials()
        
        ## Security Notes:
        - Never commit real credentials to version control
        - Use environment variables or Keychain for production
        - Credentials are encrypted in Keychain storage
        """
    }
    
    // MARK: - Development Helper
    
    #if DEBUG
    /// Enable demo mode for development/testing
    public func enableDemoMode() {
        print("🧪 Enabling demo mode - using mock credentials")
        // Development helper only; not available in production builds
    }
    #endif
        
        let demoCredentials = [
            "QUICKBOOKS_CLIENT_ID": "demo_client_id",
            "API_BASE_URL": "https://demo-api.cyntientops.com",
            "WEBSOCKET_URL": "wss://demo-api.cyntientops.com/ws"
        ]
        
        for (key, value) in demoCredentials {
            _ = storeCredential(key: key, value: value)
        }
    }
}
