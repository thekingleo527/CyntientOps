//
//  LanguageManager.swift
//  CyntientOps
//
//  Manages language switching based on user preferences after login
//

import Foundation
import SwiftUI
import Combine

@MainActor
public class LanguageManager: ObservableObject {
    public static let shared = LanguageManager()
    
    // Published properties for UI updates
    @Published public var currentLanguage: String = "en"
    @Published public var canToggleLanguage: Bool = false
    @Published public var availableLanguages: [String] = ["en", "es"]
    
    // User capabilities
    private var userLanguageToggle: Bool = false
    private var userPrimaryLanguage: String = "en"
    
    private let authManager = NewAuthManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Always start with English (for LoginView)
        currentLanguage = "en"
        canToggleLanguage = false
        
        // Listen for authentication changes
        authManager.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    Task { @MainActor in
                        await self?.loadUserLanguagePreferences()
                    }
                } else {
                    // Reset to English when logged out
                    self?.resetToEnglish()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Load user language preferences after successful login
    private func loadUserLanguagePreferences() async {
        guard let user = authManager.currentUser else {
            resetToEnglish()
            return
        }
        
        do {
            // Get user capabilities from database
            let capabilities = try await getUserCapabilities(for: user.id)
            
            // Set language preferences
            userPrimaryLanguage = capabilities.language
            userLanguageToggle = capabilities.languageToggle
            
            // Apply user preferences
            currentLanguage = userPrimaryLanguage
            canToggleLanguage = userLanguageToggle
            
            print("✅ Language preferences loaded for \(user.name):")
            print("   - Primary language: \(userPrimaryLanguage)")
            print("   - Can toggle: \(userLanguageToggle)")
            print("   - Current language: \(currentLanguage)")
            
        } catch {
            print("❌ Failed to load language preferences: \(error)")
            // Fallback to English
            resetToEnglish()
        }
    }
    
    /// Get user capabilities from database
    private func getUserCapabilities(for userId: String) async throws -> UserLanguageCapabilities {
        let results = try await GRDBManager.shared.query(
            "SELECT preferred_language as language, requires_photo_for_sanitation FROM worker_capabilities WHERE worker_id = ?",
            [userId]
        )
        
        guard let result = results.first else {
            // Return default capabilities if not found
            return UserLanguageCapabilities(language: "en", languageToggle: false)
        }
        
        let language = result["language"] as? String ?? "en"
        // For now, determine toggle capability based on user (this should come from DB)
        let canToggle = getLanguageToggleCapability(for: userId)
        
        return UserLanguageCapabilities(language: language, languageToggle: canToggle)
    }
    
    /// Determine if user can toggle languages (based on UserAccountSeeder configuration)
    private func getLanguageToggleCapability(for userId: String) -> Bool {
        // Based on UserAccountSeeder configuration
        switch userId {
        case "2": return true  // Edwin - can toggle
        case "4": return true  // Kevin - can toggle  
        case "6": return true  // Luis - can toggle
        case "7": return true  // Angel - can toggle
        case "5": return false // Mercedes - Spanish only, no toggle
        default: return false // Default no toggle
        }
    }
    
    /// Toggle between English and Spanish (only if user has toggle capability)
    public func toggleLanguage() {
        guard canToggleLanguage else {
            print("⚠️ User cannot toggle language")
            return
        }
        
        let newLanguage = currentLanguage == "en" ? "es" : "en"
        currentLanguage = newLanguage
        
        print("🌐 Language toggled to: \(newLanguage)")
        
        // Save preference
        UserDefaults.standard.set(newLanguage, forKey: "user_current_language_\(authManager.currentUser?.id ?? "")")
    }
    
    /// Reset to English (used on logout or initialization)
    private func resetToEnglish() {
        currentLanguage = "en"
        canToggleLanguage = false
        userPrimaryLanguage = "en"
        userLanguageToggle = false
    }
    
    /// Get localized string for current language
    public func localizedString(_ key: String) -> String {
        // For now, return English strings
        // This would be replaced with actual localization system
        return NSLocalizedString(key, comment: "")
    }
    
    /// Check if current language is Spanish
    public var isSpanish: Bool {
        return currentLanguage == "es"
    }
    
    /// Check if current language is English
    public var isEnglish: Bool {
        return currentLanguage == "en"
    }
}

// MARK: - Supporting Types

private struct UserLanguageCapabilities {
    let language: String
    let languageToggle: Bool
}