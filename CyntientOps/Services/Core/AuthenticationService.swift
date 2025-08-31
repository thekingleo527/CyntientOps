//
//  AuthenticationService.swift
//  CyntientOps
//
//  DEPRECATED: Use NewAuthManager.swift instead
//  This service is kept for build compatibility but should not be used
//  Created by Shawn Magloire on 8/5/25.
//


import Foundation
import GRDB
import CryptoKit
import Security

@MainActor
public final class AuthenticationService: ObservableObject {
    @Published public var currentUser: CoreTypes.User?
    @Published public var isAuthenticated = false
    @Published public var currentUserId: String?
    @Published public var sessionToken: String?
    
    private let database: GRDBManager
    private let maxLoginAttempts = 5
    private let lockoutDuration: TimeInterval = 900 // 15 minutes
    private let sessionDuration: TimeInterval = 86400 // 24 hours
    private let keychainService = "com.cyntientops.app"
    
    public init(database: GRDBManager) {
        self.database = database
        Task {
            await initializeExistingSession()
        }
    }
    
    // MARK: - Session Management
    
    private func initializeExistingSession() async {
        guard let storedToken = getStoredSessionToken(),
              let userId = validateSessionToken(storedToken) else {
            return
        }
        
        do {
            let workers = try await database.query("""
                SELECT id, name, email, role, isActive 
                FROM workers 
                WHERE id = ? AND isActive = 1
            """, [userId])
            
            guard let workerData = workers.first,
                  let workerId = workerData["id"] as? String,
                  let workerName = workerData["name"] as? String,
                  let email = workerData["email"] as? String,
                  let roleString = workerData["role"] as? String else {
                // Invalid session, clear it
                clearStoredSession()
                return
            }
            
            let user = CoreTypes.User(
                workerId: workerId,
                name: workerName,
                email: email,
                role: roleString
            )
            
            currentUser = user
            currentUserId = workerId
            isAuthenticated = true
            sessionToken = storedToken
            
            print("✅ Session restored for user: \(workerName)")
            
        } catch {
            print("❌ Failed to restore session: \(error)")
            clearStoredSession()
        }
    }
    
    public func login(email: String, password: String) async throws -> CoreTypes.User {
        guard !email.isEmpty && !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        // Check for existing worker account
        let workers = try await database.query("""
            SELECT id, name, email, password, role, loginAttempts, lockedUntil, isActive 
            FROM workers 
            WHERE email = ? AND isActive = 1
        """, [email.lowercased()])
        
        guard let workerData = workers.first else {
            // Add delay to prevent timing attacks
            try await Task.sleep(nanoseconds: UInt64(Double.random(in: 0.1...0.3) * 1_000_000_000))
            throw AuthError.invalidCredentials
        }
        
        guard let workerId = workerData["id"] as? String,
              let workerName = workerData["name"] as? String,
              let storedPassword = workerData["password"] as? String,
              let roleString = workerData["role"] as? String else {
            throw AuthError.databaseError
        }
        
        let loginAttempts = workerData["loginAttempts"] as? Int ?? 0
        let lockedUntilString = workerData["lockedUntil"] as? String
        
        // Check if account is locked
        if let lockedUntilString = lockedUntilString,
           let lockedUntil = ISO8601DateFormatter().date(from: lockedUntilString),
           Date() < lockedUntil {
            throw AuthError.accountLocked(until: lockedUntil)
        }
        
        // Check if too many failed attempts
        if loginAttempts >= maxLoginAttempts {
            let lockUntil = Date().addingTimeInterval(lockoutDuration)
            try await lockAccount(workerId: workerId, until: lockUntil)
            throw AuthError.accountLocked(until: lockUntil)
        }
        
        // Verify password
        let isPasswordValid = verifyPassword(password, against: storedPassword)
        
        if !isPasswordValid {
            // Increment login attempts
            try await incrementLoginAttempts(workerId: workerId, currentAttempts: loginAttempts)
            throw AuthError.invalidCredentials
        }
        
        // Clear login attempts and unlock account on successful login
        try await clearLoginAttempts(workerId: workerId)
        
        // Update last login time
        try await updateLastLogin(workerId: workerId)
        
        // Create user object
        let role = CoreTypes.UserRole(rawValue: roleString) ?? .worker
        let user = CoreTypes.User(
            workerId: workerId,
            name: workerName,
            email: email.lowercased(),
            role: roleString
        )
        
        // Create session token
        let token = createSessionToken(for: workerId)
        storeSessionToken(token)
        
        // Update authentication state
        currentUser = user
        currentUserId = workerId
        isAuthenticated = true
        sessionToken = token
        
        print("✅ User authenticated: \(workerName) (role: \(roleString))")
        
        return user
    }
    
    public func logout() async {
        if let user = currentUser {
            print("👋 User logged out: \(user.name)")
        }
        
        clearStoredSession()
        currentUser = nil
        currentUserId = nil
        isAuthenticated = false
        sessionToken = nil
    }
    
    public func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        // Verify current password
        let workers = try await database.query("""
            SELECT password FROM workers WHERE id = ? AND isActive = 1
        """, [user.id])
        
        guard let workerData = workers.first,
              let storedPassword = workerData["password"] as? String else {
            throw AuthError.userNotFound
        }
        
        guard verifyPassword(currentPassword, against: storedPassword) else {
            throw AuthError.invalidCredentials
        }
        
        // Hash new password
        let hashedNewPassword = hashPassword(newPassword)
        
        // Update password in database
        try await database.execute("""
            UPDATE workers 
            SET password = ?, updated_at = ? 
            WHERE id = ?
        """, [
            hashedNewPassword,
            ISO8601DateFormatter().string(from: Date()),
            user.id
        ])
        
        print("🔐 Password changed successfully for user: \\(user.name)")
    }
    
    public func resetPassword(email: String) async throws -> String {
        let workers = try await database.query("""
            SELECT id, name FROM workers WHERE email = ? AND isActive = 1
        """, [email.lowercased()])
        
        guard let workerData = workers.first,
              let workerId = workerData["id"] as? String,
              let workerName = workerData["name"] as? String else {
            // Don't reveal if email exists
            throw AuthError.invalidCredentials
        }
        
        // Generate temporary password
        let tempPassword = generateTemporaryPassword()
        let hashedTempPassword = hashPassword(tempPassword)
        
        // Update password and clear login attempts
        try await database.execute("""
            UPDATE workers 
            SET password = ?, loginAttempts = 0, lockedUntil = NULL, updated_at = ?
            WHERE id = ?
        """, [
            hashedTempPassword,
            ISO8601DateFormatter().string(from: Date()),
            workerId
        ])
        
        print("🔄 Password reset for user: \\(workerName)")
        
        // In production, you would send this via email instead of returning it
        return tempPassword
    }
    
    // MARK: - Private Methods
    
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func verifyPassword(_ password: String, against hashedPassword: String) -> Bool {
        let hashedInput = hashPassword(password)
        return hashedInput == hashedPassword
    }
    
    private func incrementLoginAttempts(workerId: String, currentAttempts: Int) async throws {
        let newAttempts = currentAttempts + 1
        
        try await database.execute("""
            UPDATE workers 
            SET loginAttempts = ?, updated_at = ?
            WHERE id = ?
        """, [
            newAttempts,
            ISO8601DateFormatter().string(from: Date()),
            workerId
        ])
    }
    
    private func clearLoginAttempts(workerId: String) async throws {
        try await database.execute("""
            UPDATE workers 
            SET loginAttempts = 0, lockedUntil = NULL, updated_at = ?
            WHERE id = ?
        """, [
            ISO8601DateFormatter().string(from: Date()),
            workerId
        ])
    }
    
    private func lockAccount(workerId: String, until: Date) async throws {
        try await database.execute("""
            UPDATE workers 
            SET lockedUntil = ?, updated_at = ?
            WHERE id = ?
        """, [
            ISO8601DateFormatter().string(from: until),
            ISO8601DateFormatter().string(from: Date()),
            workerId
        ])
        
        print("🔒 Account locked until: \\(ISO8601DateFormatter().string(from: until))")
    }
    
    private func updateLastLogin(workerId: String) async throws {
        try await database.execute("""
            UPDATE workers 
            SET lastLogin = ?, updated_at = ?
            WHERE id = ?
        """, [
            ISO8601DateFormatter().string(from: Date()),
            ISO8601DateFormatter().string(from: Date()),
            workerId
        ])
    }
    
    private func generateTemporaryPassword() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map{ _ in characters.randomElement()! })
    }
    
    // MARK: - Session Token Management
    
    private func createSessionToken(for userId: String) -> String {
        let tokenData = "\(userId):\(Date().timeIntervalSince1970 + sessionDuration)"
        let data = Data(tokenData.utf8)
        let encoded = data.base64EncodedString()
        return encoded
    }
    
    private func validateSessionToken(_ token: String) -> String? {
        guard let data = Data(base64Encoded: token),
              let tokenString = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        let components = tokenString.components(separatedBy: ":")
        guard components.count == 2,
              let userId = components.first,
              let expirationTimeInterval = Double(components[1]) else {
            return nil
        }
        
        let expirationDate = Date(timeIntervalSince1970: expirationTimeInterval)
        guard Date() < expirationDate else {
            return nil // Token expired
        }
        
        return userId
    }
    
    private func storeSessionToken(_ token: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "session_token",
            kSecValueData as String: token.data(using: .utf8)!
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func getStoredSessionToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "session_token",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    private func clearStoredSession() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "session_token"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Error Types

public enum AuthError: LocalizedError {
    case invalidCredentials
    case accountLocked(until: Date)
    case notAuthenticated
    case userNotFound
    case databaseError
    case weakPassword
    
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .accountLocked(let until):
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "Account locked until \\(formatter.string(from: until))"
        case .notAuthenticated:
            return "User not authenticated"
        case .userNotFound:
            return "User not found"
        case .databaseError:
            return "Database error occurred"
        case .weakPassword:
            return "Password does not meet security requirements"
        }
    }
}
