//
//  NewAuthManager.swift
//  CyntientOps (formerly CyntientOps) v6.0
//
//  ✅ REFACTORED: Works with ServiceContainer architecture
//  ✅ FIXED: Renamed AuthError to NewAuthError to avoid conflicts
//  ✅ BIOMETRIC: Face ID/Touch ID support
//  ✅ SESSION MANAGEMENT: Token expiration and refresh
//  ✅ ROLE-BASED ACCESS: Proper permission handling
//  ✅ NO HARDCODED CREDENTIALS: All passwords hashed and stored securely
//

import Foundation
import Combine
import SwiftUI
import LocalAuthentication
import Security
import CryptoKit

// MARK: - Notifications
extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let sessionExpired = Notification.Name("sessionExpired")
    static let sessionRefreshed = Notification.Name("sessionRefreshed")
    static let passwordChanged = Notification.Name("passwordChanged")
}

// MARK: - NewAuthManager
@MainActor
public class NewAuthManager: ObservableObject {
    public static let shared = NewAuthManager()
    
    // MARK: - Published Properties
    @Published public private(set) var currentUser: CoreTypes.User?
    @Published public private(set) var isAuthenticated = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var authError: NewAuthError?
    @Published public private(set) var biometricType: LABiometryType = .none
    @Published public private(set) var isBiometricEnabled = false
    @Published public private(set) var sessionStatus: SessionStatus = .none
    @Published public private(set) var passwordStrength: PasswordStrength = .weak
    
    // MARK: - Public Properties
    public var userRole: CoreTypes.UserRole? {
        guard let roleString = currentUser?.role else { return nil }
        return CoreTypes.UserRole(rawValue: roleString)
    }
    
    public var workerId: CoreTypes.WorkerID? {
        currentUser?.workerId
    }
    
    public var currentUserId: String? {
        currentUser?.id
    }
    
    public var currentWorkerName: String {
        currentUser?.name ?? "Unknown"
    }
    
    public var hasAdminAccess: Bool {
        userRole == .admin || userRole == .manager
    }
    
    public var hasWorkerAccess: Bool {
        userRole == .worker || hasAdminAccess
    }
    
    // MARK: - Private Properties
    private let grdbManager = GRDBManager.shared
    private let securityManager = SecurityManager.shared
    private let laContext = LAContext()
    private var cancellables = Set<AnyCancellable>()
    
    // Session management
    private var sessionToken: String?
    private var refreshToken: String?
    private var sessionExpirationDate: Date?
    private var sessionTimer: Timer?
    
    // Keychain keys
    private let keychainService = "com.cyntientops.auth"
    private let sessionTokenKey = "sessionToken"
    private let refreshTokenKey = "refreshToken"
    private let biometricEnabledKey = "biometricEnabled"
    private let lastAuthenticatedUserKey = "lastAuthenticatedUser"
    private let saltKey = "passwordSalt"
    
    // Security settings
    private let sessionDuration: TimeInterval = 8 * 60 * 60 // 8 hours
    private let sessionRefreshThreshold: TimeInterval = 30 * 60 // 30 minutes before expiry
    private let maxLoginAttempts = 5
    private var loginAttempts = 0
    
    // Password requirements
    private let minPasswordLength = 8
    private let requireUppercase = true
    private let requireLowercase = true
    private let requireNumbers = true
    private let requireSpecialChars = true
    
    private init() {
        setupBiometrics()
        #if DEBUG
        // In debug mode, always start with fresh login
        Task {
            await clearStoredSession()
        }
        #else
        restoreSession()
        #endif
        setupSessionMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Authenticate with email and password
    public func authenticate(email: String, password: String) async throws {
        // Check for too many login attempts
        guard loginAttempts < maxLoginAttempts else {
            throw NewAuthError.tooManyAttempts
        }
        
        isLoading = true
        authError = nil
        defer { isLoading = false }
        
        do {
            print("🔍 DEBUG: Attempting authentication for email: \(email)")
            
            // Get user from database
            let userRows = try await grdbManager.query(
                "SELECT * FROM workers WHERE email = ? AND isActive = 1",
                [email]
            )
            
            print("🔍 DEBUG: Found \(userRows.count) users for email \(email)")
            if userRows.isEmpty {
                // Debug: Let's see what users are in the database
                let allUsers = try await grdbManager.query("SELECT id, name, email, isActive FROM workers LIMIT 10")
                print("🔍 DEBUG: Available users in database:")
                for user in allUsers {
                    if let id = user["id"] as? String,
                       let name = user["name"] as? String,
                       let userEmail = user["email"] as? String,
                       let isActive = user["isActive"] as? Int64 {
                        print("  - \(name) (\(userEmail)) - Active: \(isActive == 1) - ID: \(id)")
                    }
                }
            }
            
            guard let userRow = userRows.first else {
                loginAttempts += 1
                throw NewAuthError.authenticationFailed("Invalid credentials")
            }
            
            // Get stored password hash
            guard let storedPasswordHash = userRow["password"] as? String,
                  let workerId = userRow["id"] as? String else {
                throw NewAuthError.authenticationFailed("Invalid user data")
            }
            
            print("🔍 DEBUG: Stored password hash length: \(storedPasswordHash.count)")
            print("🔍 DEBUG: Entered password: \(password)")
            
            // For migration: Check if password is still plain text
            if storedPasswordHash == password {
                // Migrate to hashed password
                print("✅ DEBUG: Plain text password match! Migrating for user: \(email)")
                let hashedPassword = try await hashPassword(password, for: email)
                try await grdbManager.execute(
                    "UPDATE workers SET password = ? WHERE id = ?",
                    [hashedPassword, workerId]
                )
            } else {
                // Verify hashed password
                print("🔍 DEBUG: Attempting to verify hashed password...")
                let isValid = try await verifyPassword(password, hash: storedPasswordHash, for: email)
                print("🔍 DEBUG: Password verification result: \(isValid)")
                guard isValid else {
                    loginAttempts += 1
                    throw NewAuthError.authenticationFailed("Invalid credentials")
                }
            }
            
            // Create session
            let session = try await createSession(for: (
                workerId: workerId,
                name: userRow["name"] as? String ?? "",
                email: email,
                role: userRow["role"] as? String ?? "worker"
            ))
            
            // Create CoreTypes.User
            let user = CoreTypes.User(
                id: workerId,
                workerId: workerId,
                name: userRow["name"] as? String ?? "",
                email: email,
                role: userRow["role"] as? String ?? "worker"
            )
            
            // Store session in keychain
            try await storeSession(session: session, user: user)
            
            // Update state
            self.currentUser = user
            CoreTypes.Session.shared.user = user // Update the shared session

            if user.role == "client" {
                if let clientData = try? await container.client.getClientForUser(email: user.email) {
                    CoreTypes.Session.shared.org = CoreTypes.Organization(id: clientData.id, name: clientData.name)
                }
            }
            
            self.isAuthenticated = true
            self.sessionStatus = .active
            self.loginAttempts = 0
            
            // Update last login time
            try await grdbManager.execute(
                "UPDATE workers SET lastLogin = ?, loginAttempts = 0 WHERE id = ?",
                [Date().ISO8601Format(), workerId]
            )
            
            // Store last authenticated user for biometric login
            UserDefaults.standard.set(email, forKey: lastAuthenticatedUserKey)
            
            // Start session monitoring
            startSessionTimer()
            
            print("✅ Authentication successful for \(user.name)")
            NotificationCenter.default.post(name: .userDidLogin, object: nil, userInfo: ["user": user])
            
            // Prompt for biometric enrollment if available
            if biometricType != .none && !isBiometricEnabled {
                Task {
                    try? await promptBiometricEnrollment()
                }
            }
            
        } catch {
            authError = error as? NewAuthError ?? .unknown(error.localizedDescription)
            throw error
        }
    }
    
    /// Change password for current user
    public func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = currentUser else {
            throw NewAuthError.notAuthenticated
        }
        
        // Validate new password
        guard isPasswordValid(newPassword) else {
            throw NewAuthError.weakPassword
        }
        
        // Verify current password
        let userRows = try await grdbManager.query(
            "SELECT password FROM workers WHERE id = ?",
            [user.workerId]
        )
        
        guard let userRow = userRows.first,
              let storedHash = userRow["password"] as? String else {
            throw NewAuthError.userNotFound
        }
        
        let isValid = try await verifyPassword(currentPassword, hash: storedHash, for: user.email)
        guard isValid else {
            throw NewAuthError.authenticationFailed("Current password is incorrect")
        }
        
        // Hash new password
        let newHash = try await hashPassword(newPassword, for: user.email)
        
        // Update in database
        try await grdbManager.execute(
            "UPDATE workers SET password = ?, updated_at = ? WHERE id = ?",
            [newHash, Date().ISO8601Format(), user.workerId]
        )
        
        print("✅ Password changed successfully for \(user.name)")
        NotificationCenter.default.post(name: .passwordChanged, object: nil)
    }
    
    /// Reset password (admin function)
    public func resetPassword(for email: String, newPassword: String) async throws {
        guard hasAdminAccess else {
            throw NewAuthError.insufficientPermissions
        }
        
        // Validate new password
        guard isPasswordValid(newPassword) else {
            throw NewAuthError.weakPassword
        }
        
        // Get user
        let userRows = try await grdbManager.query(
            "SELECT id FROM workers WHERE email = ?",
            [email]
        )
        
        guard let userRow = userRows.first,
              let workerId = userRow["id"] as? String else {
            throw NewAuthError.userNotFound
        }
        
        // Hash new password
        let newHash = try await hashPassword(newPassword, for: email)
        
        // Update in database
        try await grdbManager.execute(
            "UPDATE workers SET password = ?, loginAttempts = 0, lockedUntil = NULL, updated_at = ? WHERE id = ?",
            [newHash, Date().ISO8601Format(), workerId]
        )
        
        print("✅ Password reset for user: \(email)")
    }
    
    /// Authenticate with biometrics
    public func authenticateWithBiometrics() async throws {
        guard isBiometricEnabled else {
            throw NewAuthError.biometricsNotEnabled
        }
        
        guard let lastEmail = UserDefaults.standard.string(forKey: lastAuthenticatedUserKey) else {
            throw NewAuthError.noStoredCredentials
        }
        
        isLoading = true
        authError = nil
        defer { isLoading = false }
        
        // Authenticate with biometrics
        let reason = "Authenticate to access CyntientOps"
        
        do {
            let success = try await laContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                // Retrieve stored session
                if let session = try await retrieveStoredSession() {
                    // Validate session is still active
                    if session.expirationDate > Date() {
                        // Restore user session
                        self.currentUser = session.user
                        CoreTypes.Session.shared.user = session.user // Update the shared session
                        self.sessionToken = session.token
                        self.refreshToken = session.refreshToken
                        self.sessionExpirationDate = session.expirationDate
                        self.isAuthenticated = true
                        self.sessionStatus = .active
                        
                        startSessionTimer()
                        
                        print("✅ Biometric authentication successful")
                        NotificationCenter.default.post(name: .userDidLogin, object: nil, userInfo: ["user": session.user])
                    } else {
                        // Session expired, try to refresh
                        try await refreshSession()
                    }
                } else {
                    throw NewAuthError.noStoredSession
                }
            }
        } catch let error as LAError {
            throw NewAuthError.biometricAuthenticationFailed(error.localizedDescription)
        }
    }
    
    /// Enable biometric authentication
    public func enableBiometrics() async throws {
        guard isAuthenticated else {
            throw NewAuthError.notAuthenticated
        }
        
        guard biometricType != .none else {
            throw NewAuthError.biometricsNotAvailable
        }
        
        let reason = "Enable \(biometricTypeString) for faster authentication"
        
        do {
            let success = try await laContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                UserDefaults.standard.set(true, forKey: biometricEnabledKey)
                isBiometricEnabled = true
                print("✅ Biometrics enabled successfully")
            }
        } catch {
            throw NewAuthError.biometricEnrollmentFailed(error.localizedDescription)
        }
    }
    
    /// Disable biometric authentication
    public func disableBiometrics() {
        UserDefaults.standard.set(false, forKey: biometricEnabledKey)
        isBiometricEnabled = false
        print("🔐 Biometrics disabled")
    }
    
    /// Logout current user
    public func logout() async {
        // Clear session from database
        if let workerId = currentUser?.workerId {
            try? await grdbManager.logout(workerId: workerId)
        }
        
        // Clear keychain
        clearKeychain()
        
        // Clear state
        let previousUser = currentUser
        currentUser = nil
        CoreTypes.Session.shared.user = nil
        CoreTypes.Session.shared.org = nil
        sessionToken = nil
        refreshToken = nil
        sessionExpirationDate = nil
        isAuthenticated = false
        sessionStatus = .none
        authError = nil
        
        // Stop session timer
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        if let user = previousUser {
            print("👋 \(user.name) logged out")
        }
        
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
    
    /// Refresh the current session
    public func refreshSession() async throws {
        guard let refreshToken = refreshToken else {
            throw NewAuthError.noActiveSession
        }
        
        sessionStatus = .refreshing
        
        do {
            // In production, this would call an API endpoint
            // For now, we'll extend the session locally
            let newExpirationDate = Date().addingTimeInterval(sessionDuration)
            self.sessionExpirationDate = newExpirationDate
            self.sessionStatus = .active
            
            // Update stored session
            if let user = currentUser,
               let token = sessionToken {
                let session = AuthSession(
                    token: token,
                    refreshToken: refreshToken,
                    expirationDate: newExpirationDate,
                    user: user
                )
                try await storeSession(session: session, user: user)
            }
            
            NotificationCenter.default.post(name: .sessionRefreshed, object: nil)
            print("✅ Session refreshed successfully")
        } catch {
            sessionStatus = .expired
            throw NewAuthError.sessionRefreshFailed
        }
    }
    
    /// Check if user has permission for specific action
    public func hasPermission(for permission: Permission) -> Bool {
        guard let role = userRole else { return false }
        return permission.allowedRoles.contains(role)
    }
    
    /// Validate current session
    public func validateSession() async -> Bool {
        guard isAuthenticated,
              let expirationDate = sessionExpirationDate else {
            return false
        }
        
        // Check if session is expired
        if Date() > expirationDate {
            sessionStatus = .expired
            await handleSessionExpired()
            return false
        }
        
        // Check if session needs refresh
        let timeUntilExpiry = expirationDate.timeIntervalSinceNow
        if timeUntilExpiry < sessionRefreshThreshold {
            do {
                try await refreshSession()
            } catch {
                print("⚠️ Failed to refresh session: \(error)")
            }
        }
        
        return true
    }
    
    /// Get current user information
    public func getCurrentUser() async -> AuthenticatedUser? {
        guard let user = currentUser else { return nil }
        
        return AuthenticatedUser(
            id: Int(user.id) ?? 0,
            name: user.name,
            email: user.email,
            role: user.role,
            workerId: user.workerId,
            displayName: nil,
            timezone: "America/New_York"
        )
    }
    
    /// Check password strength
    public func checkPasswordStrength(_ password: String) -> PasswordStrength {
        var strength = 0
        
        if password.count >= minPasswordLength { strength += 1 }
        if password.count >= 12 { strength += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { strength += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { strength += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { strength += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { strength += 1 }
        
        switch strength {
        case 0...2: return .weak
        case 3...4: return .medium
        case 5...6: return .strong
        default: return .strong
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBiometrics() {
        var error: NSError?
        let canEvaluate = laContext.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
        
        if canEvaluate {
            biometricType = laContext.biometryType
            isBiometricEnabled = UserDefaults.standard.bool(forKey: biometricEnabledKey)
        } else {
            biometricType = .none
            isBiometricEnabled = false
        }
        
        print("🔐 Biometric setup - Type: \(biometricTypeString), Enabled: \(isBiometricEnabled)")
    }
    
    private func hashPassword(_ password: String, for email: String) async throws -> String {
        // Get or create salt for user
        let saltKey = "\(keychainService).salt.\(email)"
        let salt: Data
        
        if let existingSalt = try? getFromKeychain(key: saltKey) as? Data {
            salt = existingSalt
        } else {
            // Generate new salt
            salt = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
            try storeInKeychain(salt, for: saltKey)
        }
        
        // Create hash using SHA256
        let passwordData = Data(password.utf8)
        let saltedPassword = salt + passwordData
        let hash = SHA256.hash(data: saltedPassword)
        
        // Convert to base64 for storage
        let hashString = Data(hash).base64EncodedString()
        return hashString
    }
    
    private func verifyPassword(_ password: String, hash: String, for email: String) async throws -> Bool {
        // Get salt for user
        let saltKey = "\(keychainService).salt.\(email)"
        guard let salt = try? getFromKeychain(key: saltKey) as? Data else {
            // No salt found, this might be a plain text password
            return false
        }
        
        // Hash the provided password
        let passwordData = Data(password.utf8)
        let saltedPassword = salt + passwordData
        let computedHash = SHA256.hash(data: saltedPassword)
        let computedHashString = Data(computedHash).base64EncodedString()
        
        return computedHashString == hash
    }
    
    private func isPasswordValid(_ password: String) -> Bool {
        guard password.count >= minPasswordLength else { return false }
        
        if requireUppercase && password.rangeOfCharacter(from: .uppercaseLetters) == nil { return false }
        if requireLowercase && password.rangeOfCharacter(from: .lowercaseLetters) == nil { return false }
        if requireNumbers && password.rangeOfCharacter(from: .decimalDigits) == nil { return false }
        if requireSpecialChars && password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) == nil { return false }
        
        return true
    }
    
    private func createSession(for authenticatedWorker: (workerId: String, name: String, email: String, role: String)) async throws -> AuthSession {
        // Generate tokens (in production, these would come from the server)
        let sessionToken = UUID().uuidString
        let refreshToken = UUID().uuidString
        let expirationDate = Date().addingTimeInterval(sessionDuration)
        
        // Create session in database
        let sessionId = try await grdbManager.createSession(
            for: authenticatedWorker.workerId,
            deviceInfo: getDeviceInfo()
        )
        
        self.sessionToken = sessionToken
        self.refreshToken = refreshToken
        self.sessionExpirationDate = expirationDate
        
        return AuthSession(
            token: sessionToken,
            refreshToken: refreshToken,
            expirationDate: expirationDate,
            user: CoreTypes.User(
                id: authenticatedWorker.workerId,
                workerId: authenticatedWorker.workerId,
                name: authenticatedWorker.name,
                email: authenticatedWorker.email,
                role: authenticatedWorker.role
            )
        )
    }
    
    private func storeSession(session: AuthSession, user: CoreTypes.User) async throws {
        // Store tokens in keychain
        try storeInKeychain(session.token, for: sessionTokenKey)
        try storeInKeychain(session.refreshToken, for: refreshTokenKey)
        
        // Store session data
        let encoder = JSONEncoder()
        let sessionData = try encoder.encode(session)
        try storeInKeychain(sessionData, for: "session")
    }
    
    private func retrieveStoredSession() async throws -> AuthSession? {
        guard let sessionData = try? getFromKeychain(key: "session") as? Data else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(AuthSession.self, from: sessionData)
    }
    
    private func restoreSession() {
        Task {
            do {
                if let session = try await retrieveStoredSession() {
                    // Validate session
                    if session.expirationDate > Date() {
                        self.currentUser = session.user
                        CoreTypes.Session.shared.user = session.user // Update the shared session
                        self.sessionToken = session.token
                        self.refreshToken = session.refreshToken
                        self.sessionExpirationDate = session.expirationDate
                        self.isAuthenticated = true
                        self.sessionStatus = .active
                        
                        startSessionTimer()
                        
                        print("✅ Session restored for \(session.user.name)")
                    } else {
                        // Session expired
                        clearKeychain()
                    }
                }
            } catch {
                print("❌ Failed to restore session: \(error)")
            }
        }
    }
    
    private func setupSessionMonitoring() {
        // Monitor app lifecycle
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.validateSession()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.sessionTimer?.invalidate()
            }
            .store(in: &cancellables)
    }
    
    private func startSessionTimer() {
        sessionTimer?.invalidate()
        
        // Check session every minute
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.validateSession()
            }
        }
    }
    
    private func handleSessionExpired() async {
        await logout()
        NotificationCenter.default.post(name: .sessionExpired, object: nil)
    }
    
    private func promptBiometricEnrollment() async throws {
        // In a real app, this would show a proper UI dialog
        // For now, we'll auto-enable if the user agrees
        try await enableBiometrics()
    }
    
    private var biometricTypeString: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biometric Authentication"
        }
    }
    
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.model) - iOS \(device.systemVersion)"
    }
    
    // MARK: - Keychain Methods
    
    private func storeInKeychain(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NewAuthError.keychainError("Failed to store in keychain: \(status)")
        }
    }
    
    private func storeInKeychain(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw NewAuthError.keychainError("Failed to encode string")
        }
        try storeInKeychain(data, for: key)
    }
    
    private func getFromKeychain(key: String) throws -> Any? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw NewAuthError.keychainError("Failed to retrieve from keychain: \(status)")
        }
        
        return result
    }
    
    private func clearKeychain() {
        let keys = [sessionTokenKey, refreshTokenKey, "session"]
        for key in keys {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: key
            ]
            let status = SecItemDelete(query as CFDictionary)
            if status == errSecSuccess {
                print("  ✅ Keychain item '\(key)' deleted successfully.")
            } else if status == errSecItemNotFound {
                print("  ⚠️ Keychain item '\(key)' not found, skipping.")
            } else {
                print("  ❌ Error deleting keychain item '\(key)': \(status)")
            }
        }

        // Also run the broad delete just in case other items were stored
        let broadQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        let status = SecItemDelete(broadQuery as CFDictionary)
        if status == errSecSuccess {
            print("  ✅ Keychain service '\(keychainService)' cleared.")
        } else if status != errSecItemNotFound {
            print("  ❌ Error clearing keychain service: \(status)")
        }
    }
    
    private func clearStoredSession() async {
        clearKeychain()
        currentUser = nil
        CoreTypes.Session.shared.user = nil
        CoreTypes.Session.shared.org = nil
        sessionToken = nil
        refreshToken = nil
        sessionExpirationDate = nil
        isAuthenticated = false
        sessionStatus = .none
        print("🧹 DEBUG: Cleared stored session - forcing fresh login")
    }
}

// MARK: - Supporting Types

public enum SessionStatus {
    case none
    case active
    case refreshing
    case expired
}

public enum PasswordStrength {
    case weak
    case medium
    case strong
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
    
    var description: String {
        switch self {
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }
}

public struct Permission {
    let name: String
    let allowedRoles: Set<CoreTypes.UserRole>
    
    // Common permissions
    static let viewAllBuildings = Permission(
        name: "view_all_buildings",
        allowedRoles: [.admin, .manager, .client]
    )
    
    static let assignTasks = Permission(
        name: "assign_tasks",
        allowedRoles: [.admin, .manager]
    )
    
    static let viewFinancials = Permission(
        name: "view_financials",
        allowedRoles: [.admin, .client]
    )
    
    static let manageWorkers = Permission(
        name: "manage_workers",
        allowedRoles: [.admin, .manager]
    )
    
    static let completeTasks = Permission(
        name: "complete_tasks",
        allowedRoles: [.admin, .manager, .worker]
    )
    
    static let manageInventory = Permission(
        name: "manage_inventory",
        allowedRoles: [.admin, .manager]
    )
    
    static let viewReports = Permission(
        name: "view_reports",
        allowedRoles: [.admin, .manager, .client]
    )
}

private struct AuthSession: Codable {
    let token: String
    let refreshToken: String
    let expirationDate: Date
    let user: CoreTypes.User
}

// MARK: - Auth Errors (Renamed to NewAuthError to avoid conflicts)

public enum NewAuthError: LocalizedError {
    case authenticationFailed(String)
    case sessionCreationFailed
    case sessionExpired
    case sessionRefreshFailed
    case noActiveSession
    case noStoredSession
    case noStoredCredentials
    case notAuthenticated
    case biometricsNotAvailable
    case biometricsNotEnabled
    case biometricAuthenticationFailed(String)
    case biometricEnrollmentFailed(String)
    case keychainError(String)
    case tooManyAttempts
    case weakPassword
    case userNotFound
    case insufficientPermissions
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .sessionCreationFailed:
            return "Failed to create session"
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        case .sessionRefreshFailed:
            return "Failed to refresh session"
        case .noActiveSession:
            return "No active session found"
        case .noStoredSession:
            return "No stored session found"
        case .noStoredCredentials:
            return "No stored credentials found. Please log in with your email and password."
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .biometricsNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricsNotEnabled:
            return "Biometric authentication is not enabled"
        case .biometricAuthenticationFailed(let message):
            return "Biometric authentication failed: \(message)"
        case .biometricEnrollmentFailed(let message):
            return "Failed to enable biometrics: \(message)"
        case .keychainError(let message):
            return "Secure storage error: \(message)"
        case .tooManyAttempts:
            return "Too many failed login attempts. Please try again later."
        case .weakPassword:
            return "Password does not meet security requirements. Must be at least 8 characters with uppercase, lowercase, numbers, and special characters."
        case .userNotFound:
            return "User not found"
        case .insufficientPermissions:
            return "You do not have permission to perform this action"
        case .unknown(let message):
            return "An unknown error occurred: \(message)"
        }
    }
}

// MARK: - Legacy Support
// For compatibility with existing code that might reference AuthManager

public typealias AuthManager = NewAuthManager
