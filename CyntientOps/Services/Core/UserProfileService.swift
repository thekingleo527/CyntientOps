//
//  UserProfileService.swift
//  CyntientOps
//
//  User profile management service
//  Handles profile updates, preferences, and settings
//

import Foundation
import GRDB

@MainActor
public final class UserProfileService: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var userPreferences: UserPreferences?
    
    // MARK: - Dependencies
    private let database: GRDBManager
    
    public init(database: GRDBManager) {
        self.database = database
    }
    
    // MARK: - Profile Management
    
    /// Load user profile and preferences
    public func loadUserProfile(for userId: String) async throws -> CoreTypes.User? {
        let workers = try await database.query("""
            SELECT id, name, email, role, isActive, lastLogin, created_at, updated_at
            FROM workers 
            WHERE id = ? AND isActive = 1
        """, [userId])
        
        guard let workerData = workers.first,
              let workerId = workerData["id"] as? String,
              let name = workerData["name"] as? String,
              let email = workerData["email"] as? String,
              let role = workerData["role"] as? String else {
            return nil
        }
        
        let user = CoreTypes.User(
            workerId: workerId,
            name: name,
            email: email,
            role: role
        )
        
        // Load preferences
        userPreferences = try await loadUserPreferences(userId: userId)
        
        return user
    }
    
    /// Update user profile information
    public func updateProfile(userId: String, name: String?, email: String?) async throws {
        var setClause: [String] = []
        var parameters: [Any] = []
        
        if let name = name, !name.isEmpty {
            setClause.append("name = ?")
            parameters.append(name)
        }
        
        if let email = email, !email.isEmpty {
            setClause.append("email = ?")
            parameters.append(email.lowercased())
        }
        
        if !setClause.isEmpty {
            setClause.append("updated_at = ?")
            parameters.append(ISO8601DateFormatter().string(from: Date()))
            parameters.append(userId)
            
            let sql = """
                UPDATE workers 
                SET \(setClause.joined(separator: ", "))
                WHERE id = ?
            """
            
            try await database.execute(sql, parameters)
            logInfo("✅ Profile updated for user: \(userId)")
        }
    }
    
    // MARK: - Preferences Management
    
    /// Load user preferences
    private func loadUserPreferences(userId: String) async throws -> UserPreferences {
        let preferences = try await database.query("""
            SELECT * FROM user_preferences WHERE user_id = ?
        """, [userId])
        
        if let prefData = preferences.first {
            return UserPreferences(
                userId: userId,
                theme: prefData["theme"] as? String ?? "dark",
                notifications: prefData["notifications"] as? Bool ?? true,
                autoClockOut: prefData["auto_clock_out"] as? Bool ?? false,
                mapZoomLevel: prefData["map_zoom_level"] as? Double ?? 15.0,
                defaultView: prefData["default_view"] as? String ?? "dashboard"
            )
        } else {
            // Create default preferences
            let defaultPrefs = UserPreferences(userId: userId)
            try await saveUserPreferences(defaultPrefs)
            return defaultPrefs
        }
    }
    
    /// Save user preferences
    public func saveUserPreferences(_ preferences: UserPreferences) async throws {
        try await database.execute("""
            INSERT OR REPLACE INTO user_preferences 
            (user_id, theme, notifications, auto_clock_out, map_zoom_level, default_view, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, [
            preferences.userId,
            preferences.theme,
            preferences.notifications,
            preferences.autoClockOut,
            preferences.mapZoomLevel,
            preferences.defaultView,
            ISO8601DateFormatter().string(from: Date())
        ])
        
        userPreferences = preferences
        logInfo("✅ Preferences saved for user: \(preferences.userId)")
    }
    
    /// Update specific preference
    public func updatePreference<T>(userId: String, key: String, value: T) async throws {
        guard let currentPrefs = userPreferences else {
            throw ProfileError.preferencesNotLoaded
        }
        
        var updatedPrefs = currentPrefs
        
        switch key {
        case "theme":
            if let theme = value as? String {
                updatedPrefs = UserPreferences(
                    userId: userId,
                    theme: theme,
                    notifications: currentPrefs.notifications,
                    autoClockOut: currentPrefs.autoClockOut,
                    mapZoomLevel: currentPrefs.mapZoomLevel,
                    defaultView: currentPrefs.defaultView
                )
            }
        case "notifications":
            if let notifications = value as? Bool {
                updatedPrefs = UserPreferences(
                    userId: userId,
                    theme: currentPrefs.theme,
                    notifications: notifications,
                    autoClockOut: currentPrefs.autoClockOut,
                    mapZoomLevel: currentPrefs.mapZoomLevel,
                    defaultView: currentPrefs.defaultView
                )
            }
        case "autoClockOut":
            if let autoClockOut = value as? Bool {
                updatedPrefs = UserPreferences(
                    userId: userId,
                    theme: currentPrefs.theme,
                    notifications: currentPrefs.notifications,
                    autoClockOut: autoClockOut,
                    mapZoomLevel: currentPrefs.mapZoomLevel,
                    defaultView: currentPrefs.defaultView
                )
            }
        case "mapZoomLevel":
            if let zoomLevel = value as? Double {
                updatedPrefs = UserPreferences(
                    userId: userId,
                    theme: currentPrefs.theme,
                    notifications: currentPrefs.notifications,
                    autoClockOut: currentPrefs.autoClockOut,
                    mapZoomLevel: zoomLevel,
                    defaultView: currentPrefs.defaultView
                )
            }
        case "defaultView":
            if let defaultView = value as? String {
                updatedPrefs = UserPreferences(
                    userId: userId,
                    theme: currentPrefs.theme,
                    notifications: currentPrefs.notifications,
                    autoClockOut: currentPrefs.autoClockOut,
                    mapZoomLevel: currentPrefs.mapZoomLevel,
                    defaultView: defaultView
                )
            }
        default:
            throw ProfileError.invalidPreferenceKey(key)
        }
        
        try await saveUserPreferences(updatedPrefs)
    }
}

// MARK: - Supporting Types

public struct UserPreferences {
    public let userId: String
    public let theme: String
    public let notifications: Bool
    public let autoClockOut: Bool
    public let mapZoomLevel: Double
    public let defaultView: String
    
    public init(
        userId: String,
        theme: String = "dark",
        notifications: Bool = true,
        autoClockOut: Bool = false,
        mapZoomLevel: Double = 15.0,
        defaultView: String = "dashboard"
    ) {
        self.userId = userId
        self.theme = theme
        self.notifications = notifications
        self.autoClockOut = autoClockOut
        self.mapZoomLevel = mapZoomLevel
        self.defaultView = defaultView
    }
}

public enum ProfileError: LocalizedError {
    case preferencesNotLoaded
    case invalidPreferenceKey(String)
    case updateFailed
    
    public var errorDescription: String? {
        switch self {
        case .preferencesNotLoaded:
            return "User preferences not loaded"
        case .invalidPreferenceKey(let key):
            return "Invalid preference key: \(key)"
        case .updateFailed:
            return "Failed to update profile"
        }
    }
}