//
//  AppStartupCoordinator.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 8/4/25.
//
//  Fast startup coordinator for new installations
//  Replaces complex phases with single initialization
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppStartupCoordinator: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = AppStartupCoordinator()
    
    // MARK: - Published State
    @Published public private(set) var isInitializing: Bool = false
    @Published public private(set) var statusMessage: String = "Ready"
    @Published public private(set) var error: Error?
    @Published public private(set) var isReady: Bool = false
    
    // MARK: - Dependencies
    private let databaseInitializer = DatabaseInitializer.shared
    private let networkMonitor = NetworkMonitor.shared
    
    // MARK: - Service Container
    @Published public private(set) var serviceContainer: ServiceContainer?
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Start the app initialization sequence - fast and simple
    public func startInitialization() async throws {
        guard !isInitializing else {
            logInfo("⚠️ Initialization already in progress")
            return
        }
        
        isInitializing = true
        statusMessage = "Initializing..."
        error = nil
        
        do {
            // Quick database setup (< 500ms)
            if !databaseInitializer.isInitialized {
                try await databaseInitializer.initializeIfNeeded()
            }
            
            // Create service container
            try await createServiceContainer()
            
            // Configure network (no waiting)
            configureNetworkMonitoring()
            
            // Complete
            isReady = true
            isInitializing = false
            statusMessage = "Ready"
            
            logInfo("✅ App startup completed successfully")
            
        } catch {
            self.error = error
            isInitializing = false
            statusMessage = "Initialization failed"
            logInfo("❌ App startup failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func createServiceContainer() async throws {
        // Create ServiceContainer with all dependencies
        serviceContainer = try await ServiceContainer()
        
        // Verify container is properly initialized
        guard let container = serviceContainer else {
            throw StartupError.servicesInitializationFailed("ServiceContainer creation failed")
        }
        
        // Nova AI manager is already created and owned by ServiceContainer
        
        logInfo("✅ ServiceContainer created and configured")
    }
    
    private func configureNetworkMonitoring() {
        // Start network monitoring without waiting
        networkMonitor.forceUpdate()
        logInfo("✅ Network monitoring configured: \(networkMonitor.isConnected ? "Online" : "Offline")")
    }
    
    // MARK: - Background Task Verification
    
    /// Verify Kevin's tasks in background after login (not during startup)
    public func verifyKevinTasksInBackground() async {
        guard isReady else { return }
        
        Task {
            do {
                let operationalData = OperationalDataManager.shared
                guard operationalData.isInitialized else {
                    logInfo("⚠️ OperationalDataManager not initialized, skipping Kevin tasks verification")
                    return
                }
                
                // Get Kevin's tasks
                let kevinTasks = operationalData.getRealWorldTasks(for: "Kevin Dutan")
                logInfo("📊 Background verification - Kevin's tasks: \(kevinTasks.count)")
                
                // Verify Rubin Museum assignment
                let hasRubinMuseum = kevinTasks.contains { task in
                    task.buildingId == "14" || task.building.contains("Rubin")
                }
                
                if hasRubinMuseum {
                    logInfo("✅ Background verification - Kevin has Rubin Museum assignment")
                } else {
                    logInfo("⚠️ Background verification - Kevin missing Rubin Museum assignment")
                }
                
            } catch {
                logInfo("❌ Background Kevin tasks verification failed: \(error)")
            }
        }
    }
}

// MARK: - Startup Errors

public enum StartupError: LocalizedError {
    case databaseSetupFailed(String)
    case servicesInitializationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .databaseSetupFailed(let reason):
            return "Database setup failed: \(reason)"
        case .servicesInitializationFailed(let service):
            return "Failed to initialize \(service)"
        }
    }
}