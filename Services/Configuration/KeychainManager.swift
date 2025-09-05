//
//  KeychainManager.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 8/4/25.
//


//
//  KeychainManager.swift
//  CyntientOps (formerly CyntientOps)
//
//  Phase 0.5: Keychain Manager for secure storage
//  Manages secure storage of sensitive data including NYC API keys
//

import Foundation
import Security

public final class KeychainManager {
    
    // MARK: - Singleton
    public static let shared = KeychainManager()
    
    // MARK: - Configuration
    private let service: String
    private let accessGroup: String?
    
    // MARK: - Error Types
    public enum KeychainError: LocalizedError {
        case itemNotFound
        case duplicateItem
        case invalidData
        case unhandledError(status: OSStatus)
        
        public var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "Item not found in keychain"
            case .duplicateItem:
                return "Item already exists in keychain"
            case .invalidData:
                return "Invalid data format"
            case .unhandledError(let status):
                return "Keychain error: \(status)"
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        self.service = Bundle.main.bundleIdentifier ?? "com.cyntientops.app"
        
        // Use app group for sharing between app and extensions
        #if !DEBUG
        self.accessGroup = "group.com.cyntientops.shared"
        #else
        self.accessGroup = nil
        #endif
    }
    
    // MARK: - Public Methods - Generic
    
    /// Save data to keychain
    public func save(_ data: Data, for key: String) throws {
        let query = createQuery(for: key)
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        var newQuery = query
        newQuery[kSecValueData as String] = data
        
        let status = SecItemAdd(newQuery as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Retrieve data from keychain
    public func getData(for key: String) throws -> Data {
        var query = createQuery(for: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    /// Delete item from keychain
    public func delete(key: String) throws {
        let query = createQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Check if item exists
    public func exists(key: String) -> Bool {
        var query = createQuery(for: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Public Methods - Convenience
    
    /// Save string to keychain
    public func saveString(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try save(data, for: key)
    }
    
    /// Get string from keychain
    public func getString(for key: String) throws -> String {
        let data = try getData(for: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }
    
    /// Save codable object to keychain
    public func saveCodable<T: Codable>(_ object: T, for key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try save(data, for: key)
    }
    
    /// Get codable object from keychain
    public func getCodable<T: Codable>(_ type: T.Type, for key: String) throws -> T {
        let data = try getData(for: key)
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
    
    // MARK: - Specific Storage Methods
    
    /// Save API credentials
    public func saveAPICredentials(_ credentials: APICredentials) throws {
        try saveCodable(credentials, for: KeychainKeys.apiCredentials)
    }
    
    /// Get API credentials
    public func getAPICredentials() throws -> APICredentials {
        return try getCodable(APICredentials.self, for: KeychainKeys.apiCredentials)
    }
    
    /// Save QuickBooks OAuth tokens
    public func saveQuickBooksTokens(_ tokens: QuickBooksTokens) throws {
        try saveCodable(tokens, for: KeychainKeys.quickBooksTokens)
    }
    
    /// Get QuickBooks OAuth tokens
    public func getQuickBooksTokens() throws -> QuickBooksTokens {
        return try getCodable(QuickBooksTokens.self, for: KeychainKeys.quickBooksTokens)
    }
    
    /// Save user session
    public func saveUserSession(_ session: UserSession) throws {
        try saveCodable(session, for: KeychainKeys.userSession)
    }
    
    /// Get user session
    public func getUserSession() throws -> UserSession {
        return try getCodable(UserSession.self, for: KeychainKeys.userSession)
    }
    
    /// Save NYC API keys
    public func saveNYCAPIKeys(_ keys: NYCAPIKeys) throws {
        try saveCodable(keys, for: KeychainKeys.nycAPIKeys)
    }
    
    /// Get NYC API keys
    public func getNYCAPIKeys() throws -> NYCAPIKeys {
        return try getCodable(NYCAPIKeys.self, for: KeychainKeys.nycAPIKeys)
    }
    
    /// Clear all sensitive data
    public func clearAll() {
        let keys = [
            KeychainKeys.apiCredentials,
            KeychainKeys.quickBooksTokens,
            KeychainKeys.userSession,
            KeychainKeys.biometricEnabled,
            KeychainKeys.encryptionKey,
            KeychainKeys.nycAPIKeys
        ]
        
        for key in keys {
            try? delete(key: key)
        }
    }
    
    // MARK: - Private Methods
    
    private func createQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
}

// MARK: - Keychain Keys

private struct KeychainKeys {
    static let apiCredentials = "com.cyntientops.api.credentials"
    static let quickBooksTokens = "com.cyntientops.quickbooks.tokens"
    static let userSession = "com.cyntientops.user.session"
    static let biometricEnabled = "com.cyntientops.biometric.enabled"
    static let encryptionKey = "com.cyntientops.encryption.key"
    static let nycAPIKeys = "com.cyntientops.nyc.api.keys"
}

// MARK: - Data Models

public struct APICredentials: Codable {
    public let apiKey: String
    public let apiSecret: String
    public let environment: String
    
    public init(apiKey: String, apiSecret: String, environment: String) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.environment = environment
    }
}

public struct QuickBooksTokens: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date
    public let companyId: String
    
    public init(accessToken: String, refreshToken: String, expiresAt: Date, companyId: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.companyId = companyId
    }
}

public struct NYCAPIKeys: Codable {
    public let hpdAPIKey: String
    public let dobAPIKey: String
    public let depAPIKey: String
    public let ll97APIKey: String
    public let dsnyAPIKey: String
    
    public init(hpdAPIKey: String, dobAPIKey: String, depAPIKey: String, ll97APIKey: String, dsnyAPIKey: String) {
        self.hpdAPIKey = hpdAPIKey
        self.dobAPIKey = dobAPIKey
        self.depAPIKey = depAPIKey
        self.ll97APIKey = ll97APIKey
        self.dsnyAPIKey = dsnyAPIKey
    }
}

public struct UserSession: Codable {
    public let userId: String
    public let token: String
    public let refreshToken: String
    public let expiresAt: Date
    
    public init(userId: String, token: String, refreshToken: String, expiresAt: Date) {
        self.userId = userId
        self.token = token
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}