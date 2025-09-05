//
//  UnifiedAuthenticationService.swift
//  CyntientOps
//
//  PRODUCTION READY: Single source of truth for all authentication
//  All authentication flows must use this service which delegates to NewAuthManager
//

import Foundation
import Combine
import SwiftUI

@MainActor
public final class UnifiedAuthenticationService: ObservableObject {
    public static let shared = UnifiedAuthenticationService()
    
    // MARK: - Published Properties (mirror NewAuthManager)
    @Published public private(set) var currentUser: CoreTypes.User?
    @Published public private(set) var isAuthenticated = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var authError: NewAuthError?
    @Published public private(set) var sessionStatus: SessionStatus = .none
    
    // MARK: - Private Properties
    private let authManager = NewAuthManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Mirror NewAuthManager state
        authManager.$currentUser
            .assign(to: &$currentUser)
        
        authManager.$isAuthenticated
            .assign(to: &$isAuthenticated)
        
        authManager.$isLoading
            .assign(to: &$isLoading)
        
        authManager.$authError
            .assign(to: &$authError)
        
        authManager.$sessionStatus
            .assign(to: &$sessionStatus)
    }
    
    // MARK: - Public Authentication Methods
    
    /// Primary authentication method - all login attempts must use this
    public func authenticate(email: String, password: String) async throws {
        try await authManager.authenticate(email: email, password: password)
    }
    
    /// Biometric authentication
    public func authenticateWithBiometrics() async throws {
        try await authManager.authenticateWithBiometrics()
    }
    
    /// Logout current user
    public func logout() async {
        await authManager.logout()
    }
    
    /// Change password for current user
    public func changePassword(currentPassword: String, newPassword: String) async throws {
        try await authManager.changePassword(currentPassword: currentPassword, newPassword: newPassword)
    }
    
    /// Reset password (admin function)
    public func resetPassword(for email: String, newPassword: String) async throws {
        try await authManager.resetPassword(for: email, newPassword: newPassword)
    }
    
    /// Enable biometric authentication
    public func enableBiometrics() async throws {
        try await authManager.enableBiometrics()
    }
    
    /// Disable biometric authentication
    public func disableBiometrics() {
        authManager.disableBiometrics()
    }
    
    /// Validate current session
    public func validateSession() async -> Bool {
        return await authManager.validateSession()
    }
    
    /// Check if user has permission for specific action
    public func hasPermission(for permission: Permission) -> Bool {
        return authManager.hasPermission(for: permission)
    }
    
    /// Get current authenticated user
    public func getCurrentUser() async -> AuthenticatedUser? {
        return await authManager.getCurrentUser()
    }
    
    // MARK: - Computed Properties
    
    public var userRole: CoreTypes.UserRole? {
        authManager.userRole
    }
    
    public var workerId: CoreTypes.WorkerID? {
        authManager.workerId
    }
    
    public var currentUserId: String? {
        authManager.currentUserId
    }
    
    public var currentWorkerName: String {
        authManager.currentWorkerName
    }
    
    public var hasAdminAccess: Bool {
        authManager.hasAdminAccess
    }
    
    public var hasWorkerAccess: Bool {
        authManager.hasWorkerAccess
    }
    
    public var biometricType: LABiometryType {
        authManager.biometricType
    }
    
    public var isBiometricEnabled: Bool {
        authManager.isBiometricEnabled
    }
    
    // MARK: - Development Helpers
    
    #if DEBUG
    /// Force logout for debugging purposes
    public func forceLogout() async {
        await authManager.forceLogout()
    }
    
    /// Check password strength for development
    public func checkPasswordStrength(_ password: String) -> PasswordStrength {
        return authManager.checkPasswordStrength(password)
    }
    #endif
}

// MARK: - Legacy Authentication Result (for migration)
public enum AuthenticationResult {
    case success(AuthenticatedUser)
    case failure(String)
}

// MARK: - Legacy AuthenticatedUser (for compatibility)
public struct AuthenticatedUser: Codable {
    public let id: Int
    public let name: String
    public let email: String
    public let role: String
    public let workerId: String
    public let displayName: String?
    public let timezone: String
    
    public init(id: Int, name: String, email: String, role: String, workerId: String, displayName: String?, timezone: String) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.workerId = workerId
        self.displayName = displayName
        self.timezone = timezone
    }
}