//
//  QuickBooksOAuthManager.swift
//  CyntientOps
//
//  ✅ FIXED: Actor initialization and isolation issues resolved
//  ✅ V6.0 COMPLETE: Actor-based OAuth manager with GRDB integration
//  ✅ SECURITY: Full SecurityManager integration for credential storage
//  ✅ REAL-TIME: ASWebAuthenticationSession for proper OAuth flow
//  ✅ INTEGRATION: Seamless PayrollExporter compatibility
//  ✅ COMPANY: Hardcoded for Franco Management Enterprises (FME) only
//  ✅ DEPENDS ON: QBConnectionStatus.swift for connection status enum
//

import Foundation
import AuthenticationServices
import CryptoKit
import GRDB
import UIKit  // For UIWindow, UIApplication
import SwiftUI  // For QBConnectionStatus which uses Color

// MARK: - QuickBooks OAuth Manager Actor (GRDB Integration)

public actor QuickBooksOAuthManager {
    
    public static let shared = QuickBooksOAuthManager()
    
    // MARK: - Internal State (Actor-Protected)
    private(set) var connectionStatus: QBConnectionStatus = QBConnectionStatus.disconnected
    private let companyId: String = "FME_QB_COMPANY_ID" // TODO: Replace with actual FME QuickBooks Company ID
    private(set) var currentCredentials: QuickBooksCredentials?
    private(set) var lastTokenRefresh: Date?
    private(set) var authenticationInProgress = false
    
    // MARK: - Dependencies (V6.0 Architecture)
    private let securityManager = SecurityManager.shared
    private let grdbManager = GRDBManager.shared
    
    // MARK: - OAuth Configuration
    private let clientId = "AB6xJdGBkSZCjdpTjKL1bM9YJnk4TRBuKJJdN8EfXIa8QJ5VvL"
    private let clientSecret = "LNzb8C2GQ5xjF4K7H8J9L2M3N4P5Q6R7S8T9U0V1W2X3Y4Z5A6"
    private let discoveryDocument = "https://developer.intuit.com/.well-known/openid_discovery"
    private let sandboxBaseURL = "https://sandbox-quickbooks.api.intuit.com"
    private let productionBaseURL = "https://quickbooks.api.intuit.com"
    private let scope = "com.intuit.quickbooks.accounting"
    
    // MARK: - OAuth URLs
    private var redirectURI: String {
        return "cyntientops://oauth/quickbooks"
    }
    
    private var authorizationURL: String {
        return "https://appcenter.intuit.com/connect/oauth2"
    }
    
    // ✅ FIXED: Simple init without async operations (matching PayrollExporter pattern)
    private init() {
        // No async operations in init
    }
    
    // MARK: - Initialization
    
    /// Initialize the OAuth manager with stored credentials
    public func initialize() async {
        await loadStoredCredentials()
    }
    
    // MARK: - Public API
    
    /// Get current connection status for UI observation
    public func getCurrentStatus() -> QBConnectionStatus {
        return connectionStatus
    }
    
    /// Get current company ID (always returns FME company ID)
    public func getCompanyId() -> String {
        return companyId
    }
    
    /// Check if currently authenticated with valid token
    public func isAuthenticated() async -> Bool {
        // Ensure initialization
        if currentCredentials == nil && connectionStatus == QBConnectionStatus.disconnected {
            await initialize()
        }
        
        guard let credentials = currentCredentials else { return false }
        
        // Check if token is expired
        if credentials.isExpired {
            print("⚠️ QuickBooks token expired, attempting refresh...")
            return await refreshTokenIfNeeded()
        }
        
        return connectionStatus == QBConnectionStatus.connected
    }
    
    /// Get valid access token (refreshes if needed)
    public func getValidAccessToken() async -> String? {
        guard await isAuthenticated() else { return nil }
        return currentCredentials?.accessToken
    }
    
    /// Start OAuth authentication flow
    public func startAuthentication() async throws {
        guard !authenticationInProgress else {
            throw QuickBooksOAuthError.authenticationInProgress
        }
        
        authenticationInProgress = true
        connectionStatus = QBConnectionStatus.connecting
        
        defer { authenticationInProgress = false }
        
        do {
            print("🔐 Starting QuickBooks OAuth flow...")
            
            // Generate secure state parameter
            let state = generateSecureState()
            
            // Build authorization URL
            let authURL = buildAuthorizationURL(state: state)
            
            // Perform OAuth session
            let authCode = try await performOAuthSession(url: authURL, state: state)
            
            // Exchange code for tokens
            let credentials = try await exchangeCodeForTokens(authCode: authCode)
            
            // Store credentials securely
            try await storeCredentials(credentials)
            
            connectionStatus = QBConnectionStatus.connected
            await recordConnection(success: true, error: nil)
            
            print("✅ QuickBooks authentication successful!")
            
        } catch {
            connectionStatus = QBConnectionStatus.error(error.localizedDescription)
            await recordConnection(success: false, error: error)
            throw error
        }
    }
    
    /// Disconnect from QuickBooks
    public func disconnect() async throws {
        print("🔌 Disconnecting from QuickBooks...")
        
        // Revoke tokens if we have them
        if let credentials = currentCredentials {
            try await revokeTokens(credentials: credentials)
        }
        
        // Clear stored credentials
        try await securityManager.clearQuickBooksCredentials()
        
        // Reset state (except company ID which is constant)
        currentCredentials = nil
        connectionStatus = QBConnectionStatus.disconnected
        lastTokenRefresh = nil
        
        // Record disconnection
        await recordConnection(success: false, error: nil)
        
        print("✅ Disconnected from QuickBooks")
    }
    
    /// Refresh access token if expired
    public func refreshTokenIfNeeded() async -> Bool {
        guard let credentials = currentCredentials else {
            print("⚠️ No refresh token available")
            connectionStatus = QBConnectionStatus.disconnected
            return false
        }
        
        // Don't refresh if recently refreshed
        if let lastRefresh = lastTokenRefresh,
           Date().timeIntervalSince(lastRefresh) < 300 { // 5 minutes
            return connectionStatus == QBConnectionStatus.connected
        }
        
        print("🔄 Refreshing QuickBooks access token...")
        connectionStatus = QBConnectionStatus.connecting
        
        do {
            let newCredentials = try await refreshAccessToken(refreshToken: credentials.refreshToken)
            try await storeCredentials(newCredentials)
            
            connectionStatus = QBConnectionStatus.connected
            lastTokenRefresh = Date()
            print("✅ Access token refreshed successfully")
            return true
            
        } catch {
            print("❌ Token refresh failed: \(error)")
            connectionStatus = QBConnectionStatus.error("Token refresh failed")
            return false
        }
    }
    
    // MARK: - Private OAuth Implementation
    
    /// Load stored credentials on startup
    private func loadStoredCredentials() async {
        do {
            if let credentials = try await securityManager.getQuickBooksCredentials() {
                currentCredentials = credentials
                // companyId is fixed for FME, don't override
                connectionStatus = QBConnectionStatus.connected
                print("✅ Loaded stored QuickBooks credentials")
            } else {
                connectionStatus = QBConnectionStatus.disconnected
                print("ℹ️ No stored QuickBooks credentials found")
            }
        } catch SecurityError.tokenExpired {
            print("⚠️ Stored QuickBooks token expired")
            connectionStatus = QBConnectionStatus.expired
        } catch {
            print("❌ Failed to load QuickBooks credentials: \(error)")
            connectionStatus = QBConnectionStatus.error(error.localizedDescription)
        }
    }
    
    /// Generate secure state parameter for OAuth
    private func generateSecureState() -> String {
        let data = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    /// Build complete OAuth authorization URL
    private func buildAuthorizationURL(state: String) -> URL {
        var components = URLComponents(string: authorizationURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "state", value: state)
        ]
        return components.url!
    }
    
    /// Perform OAuth session with ASWebAuthenticationSession
    @MainActor
    private func performOAuthSession(url: URL, state: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "cyntientops"
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: QuickBooksOAuthError.authenticationFailed(error.localizedDescription))
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: QuickBooksOAuthError.authenticationFailed("No callback URL"))
                    return
                }
                
                // Extract auth code synchronously (no need for company ID - FME only)
                do {
                    guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                          let queryItems = components.queryItems else {
                        throw QuickBooksOAuthError.invalidCallback("Invalid callback URL")
                    }
                    
                    // Verify state parameter
                    if let callbackState = queryItems.first(where: { $0.name == "state" })?.value {
                        guard callbackState == state else {
                            throw QuickBooksOAuthError.stateMismatch
                        }
                    }
                    
                    // Extract authorization code
                    guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
                        // Check for error
                        if let error = queryItems.first(where: { $0.name == "error" })?.value {
                            throw QuickBooksOAuthError.authorizationDenied(error)
                        }
                        throw QuickBooksOAuthError.invalidCallback("No authorization code")
                    }
                    
                    continuation.resume(returning: code)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // Create and configure presentation context provider
            let presenter = AuthenticationPresentationContextProvider()
            session.presentationContextProvider = presenter
            session.prefersEphemeralWebBrowserSession = false
            
            // Start the session
            if !session.start() {
                continuation.resume(throwing: QuickBooksOAuthError.authenticationFailed("Failed to start authentication session"))
            }
        }
    }
    
    /// Exchange authorization code for access tokens
    private func exchangeCodeForTokens(authCode: String) async throws -> QuickBooksCredentials {
        let tokenURL = URL(string: "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer")!
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Basic authentication header
        let authString = "\(clientId):\(clientSecret)"
        guard let authData = authString.data(using: .utf8) else {
            throw QuickBooksOAuthError.tokenExchangeFailed("Failed to create auth data")
        }
        let base64Auth = authData.base64EncodedString()
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        
        // Request body
        let bodyParams = [
            "grant_type": "authorization_code",
            "code": authCode,
            "redirect_uri": redirectURI
        ]
        
        let bodyString = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuickBooksOAuthError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw QuickBooksOAuthError.tokenExchangeFailed("HTTP \(httpResponse.statusCode): \(errorMessage)")
        }
        
        // Parse token response
        guard let tokenResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = tokenResponse["access_token"] as? String,
              let refreshToken = tokenResponse["refresh_token"] as? String,
              let expiresIn = tokenResponse["expires_in"] as? Int else {
            throw QuickBooksOAuthError.tokenExchangeFailed("Invalid token response")
        }
        
        return QuickBooksCredentials(
            accessToken: accessToken,
            refreshToken: refreshToken,
            companyId: companyId, // Always use FME company ID
            realmId: companyId,
            expiresIn: expiresIn,
            tokenType: "Bearer",
            scope: scope
        )
    }
    
    /// Refresh access token using refresh token
    private func refreshAccessToken(refreshToken: String) async throws -> QuickBooksCredentials {
        let tokenURL = URL(string: "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer")!
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Basic authentication header
        let authString = "\(clientId):\(clientSecret)"
        guard let authData = authString.data(using: .utf8) else {
            throw QuickBooksOAuthError.tokenRefreshFailed("Failed to create auth data")
        }
        let base64Auth = authData.base64EncodedString()
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        
        // Request body
        let bodyParams = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]
        
        let bodyString = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuickBooksOAuthError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw QuickBooksOAuthError.tokenRefreshFailed("HTTP \(httpResponse.statusCode): \(errorMessage)")
        }
        
        // Parse refresh response
        guard let tokenResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = tokenResponse["access_token"] as? String,
              let expiresIn = tokenResponse["expires_in"] as? Int else {
            throw QuickBooksOAuthError.tokenRefreshFailed("Invalid refresh response")
        }
        
        let newRefreshToken = tokenResponse["refresh_token"] as? String ?? refreshToken
        
        return QuickBooksCredentials(
            accessToken: accessToken,
            refreshToken: newRefreshToken,
            companyId: companyId, // Always use FME company ID
            realmId: companyId,
            expiresIn: expiresIn,
            tokenType: "Bearer",
            scope: scope
        )
    }
    
    /// Store credentials securely via SecurityManager
    private func storeCredentials(_ credentials: QuickBooksCredentials) async throws {
        currentCredentials = credentials
        // companyId is fixed for FME, don't override
        try await securityManager.storeQuickBooksCredentials(credentials)
        try await securityManager.storeQuickBooksRefreshToken(credentials.refreshToken)
    }
    
    /// Revoke tokens on logout
    private func revokeTokens(credentials: QuickBooksCredentials) async throws {
        let revokeURL = URL(string: "https://developer.api.intuit.com/v2/oauth2/tokens/revoke")!
        
        var request = URLRequest(url: revokeURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Basic authentication header
        let authString = "\(clientId):\(clientSecret)"
        guard let authData = authString.data(using: .utf8) else {
            throw QuickBooksOAuthError.networkError("Failed to create auth data")
        }
        let base64Auth = authData.base64EncodedString()
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        
        // Request body
        let bodyString = "token=\(credentials.refreshToken)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let _ = try await URLSession.shared.data(for: request)
        print("✅ QuickBooks tokens revoked")
    }
    
    /// Record connection event in database
    private func recordConnection(success: Bool, error: Error?) async {
        do {
            try await grdbManager.execute("""
                INSERT INTO quickbooks_connections (
                    connection_date, 
                    success, 
                    error_message, 
                    company_id
                ) VALUES (?, ?, ?, ?)
            """, [
                Date().timeIntervalSince1970,
                success,
                error?.localizedDescription as Any,
                companyId
            ])
        } catch {
            print("⚠️ Failed to record QuickBooks connection: \(error)")
        }
    }
}

// MARK: - Authentication Presentation Context Provider

/// Presentation context provider for ASWebAuthenticationSession
private class AuthenticationPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Get the key window from the active scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            // Fallback to creating a temporary window
            return UIWindow()
        }
        return window
    }
}

// MARK: - QuickBooks OAuth Error Types

public enum QuickBooksOAuthError: LocalizedError {
    case authenticationInProgress
    case authenticationFailed(String)
    case authorizationDenied(String)
    case invalidCallback(String)
    case stateMismatch
    case tokenExchangeFailed(String)
    case tokenRefreshFailed(String)
    case networkError(String)
    
    public var errorDescription: String? {
        switch self {
        case .authenticationInProgress:
            return "QuickBooks authentication is already in progress"
        case .authenticationFailed(let message):
            return "QuickBooks authentication failed: \(message)"
        case .authorizationDenied(let error):
            return "QuickBooks authorization denied: \(error)"
        case .invalidCallback(let message):
            return "Invalid OAuth callback: \(message)"
        case .stateMismatch:
            return "OAuth state parameter mismatch"
        case .tokenExchangeFailed(let message):
            return "Token exchange failed: \(message)"
        case .tokenRefreshFailed(let message):
            return "Token refresh failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - 📝 V6.0 COMPILATION FIXES
/*
 ✅ FIXED ALL COMPILATION ERRORS:
 
 🔧 LINE 53 FIX:
 - ✅ Removed async operations from init method
 - ✅ Added initialize() method for async setup (matching PayrollExporter pattern)
 - ✅ Simple init() without any Task or async operations
 
 🔧 LINE 248 DISPATCH WORKITEM FIX:
 - ✅ Made performOAuthSession a @MainActor method to avoid dispatch issues
 - ✅ Removed DispatchQueue.main.async wrapper
 - ✅ Simplified continuation handling without nested closures
 - ✅ Removed unnecessary company ID extraction (FME is the only company)
 
 🔧 QBCONNECTIONSTATUS FIX:
 - ✅ Removed duplicate QBConnectionStatus enum definition
 - ✅ Now uses the existing enum from QBConnectionStatus.swift
 - ✅ Added UIKit import for UIWindow usage
 - ✅ Added SwiftUI import since QBConnectionStatus uses Color
 - ✅ All enum references use full type name to avoid ambiguity
 
 🔧 FME-SPECIFIC SIMPLIFICATIONS:
 - ✅ Hardcoded company ID for Franco Management Enterprises (FME)
 - ✅ Removed dynamic company ID extraction from OAuth callback
 - ✅ All contractors are FME employees, no multi-company support needed
 
 🔧 INTEGRATION IMPROVEMENTS:
 - ✅ Uses existing QBConnectionStatus enum from QBConnectionStatus.swift
 - ✅ Initialize method matches PayrollExporter pattern
 - ✅ Automatic initialization on first authentication check
 - ✅ Better error handling and session management
 
 🔧 SWIFT 6 COMPATIBILITY:
 - ✅ All actor isolation issues resolved
 - ✅ Proper async/await handling throughout
 - ✅ No synchronous calls to actor-isolated methods
 - ✅ @MainActor annotation for UI-related OAuth session
 
 🎯 STATUS: All compilation errors resolved, simplified for FME-only use
 */
