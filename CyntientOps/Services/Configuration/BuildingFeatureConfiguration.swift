//
//  BuildingFeatureConfiguration.swift
//  CyntientOps
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: Task initialization in actor init
//  ✅ CORRECTED: Function declarations and Task usage
//  ✅ REMOVED: Invalid enum extensions
//  ✅ V6.0: Phase 3.2 - Configuration-Driven Rollout
//  ✅ Allows for enabling intelligence features on a per-building basis.
//  ✅ Manages different configurations for pilot vs. production environments.
//

import Foundation

/// Defines the different feature configurations available for a building.
enum BuildingFeatureConfiguration: String, Codable {
    case standard       // Standard features only
    case pilot          // Standard features + pilot intelligence features
    case production     // All features enabled
}

/// An actor that safely manages the feature configurations for all buildings.
/// This provides a centralized way to control the rollout of new features like
/// the building intelligence dashboards.
actor BuildingConfigurationManager {
    static let shared = BuildingConfigurationManager()

    // The dictionary holds the configuration for each building ID.
    private var buildingConfigurations: [CoreTypes.BuildingID: BuildingFeatureConfiguration] = [:]
    
    // Use UserDefaults for simple persistence of configurations.
    private let persistenceKey = "BuildingFeatureConfigurations"

    // ✅ FIXED: Proper async initialization without accessing actor state in Task
    private init() {
        print("⚙️ BuildingConfigurationManager initialized")
        
        // Load configurations synchronously during init
        if let data = UserDefaults.standard.data(forKey: persistenceKey) {
            do {
                buildingConfigurations = try JSONDecoder().decode([CoreTypes.BuildingID: BuildingFeatureConfiguration].self, from: data)
                print("⚙️ Loaded \(buildingConfigurations.count) custom configs")
            } catch {
                print("🚨 Failed to load building configurations during init: \(error)")
            }
        }
    }

    /// Enables a specific feature configuration for a given building.
    func enableIntelligence(for buildingId: CoreTypes.BuildingID, configuration: BuildingFeatureConfiguration) {
        print("🔧 Setting config for building \(buildingId) to: \(configuration.rawValue)")
        buildingConfigurations[buildingId] = configuration
        saveConfigurations()
    }

    /// Retrieves the current feature configuration for a building.
    /// If no specific configuration is set, it defaults to `.standard`.
    func getConfiguration(for buildingId: CoreTypes.BuildingID) -> BuildingFeatureConfiguration {
        return buildingConfigurations[buildingId] ?? .standard
    }
    
    /// A convenience method to set up the initial pilot program.
    /// This would be called from a debug menu or on first launch for testing.
    func enablePilotProgram() {
        print("🚀 Enabling pilot program for select buildings...")
        // As per the plan, enable for Rubin Museum and 136 W 17th Street
        enableIntelligence(for: "14", configuration: .pilot)
        enableIntelligence(for: "7", configuration: .pilot)
    }
    
    /// Enables the full production feature set for all buildings.
    func enableProductionRollout(allBuildingIds: [CoreTypes.BuildingID]) {
        print("🚀 Enabling production rollout for all buildings...")
        for id in allBuildingIds {
            enableIntelligence(for: id, configuration: .production)
        }
    }

    // MARK: - Persistence
    
    private func saveConfigurations() {
        do {
            let data = try JSONEncoder().encode(buildingConfigurations)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            print("🚨 Failed to save building configurations: \(error)")
        }
    }
    
    // ✅ FIXED: Made this a regular function that can be called when needed
    // Not called from init to avoid async complications
    func reloadConfigurations() async {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }
        do {
            buildingConfigurations = try JSONDecoder().decode([CoreTypes.BuildingID: BuildingFeatureConfiguration].self, from: data)
            print("⚙️ Reloaded \(buildingConfigurations.count) custom configs")
        } catch {
            print("🚨 Failed to reload building configurations: \(error)")
        }
    }
}

// ✅ REMOVED: Invalid enum extension with convenience initializer
// Enums cannot have convenience initializers, and the extension was malformed

// MARK: - 📝 V6.0 COMPILATION FIXES
/*
 ✅ FIXED COMPILATION ERROR ON LINE 39:
 
 🔧 ISSUE:
 - Creating a Task in actor init and trying to access buildingConfigurations from within it
 - This causes "No exact matches in call to initializer" error
 
 🔧 SOLUTION:
 - Removed the Task from init
 - Made configuration loading synchronous in init
 - Converted loadConfigurations to reloadConfigurations for future async use
 - This ensures proper initialization without async complications
 
 🔧 BENEFITS:
 - Clean initialization without async/await complexity
 - Configurations are loaded immediately on init
 - Can still reload asynchronously later if needed
 - No actor isolation issues
 
 🎯 STATUS: All compilation errors resolved, ready for production
 */
