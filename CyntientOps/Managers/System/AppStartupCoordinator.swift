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
    private var containerCreationTask: Task<ServiceContainer, Error>?
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Start the app initialization sequence - fast and simple
    public func startInitialization() async throws {
        guard !isInitializing else {
            print("⚠️ Initialization already in progress")
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
            
            print("✅ App startup completed successfully")
            
        } catch {
            self.error = error
            isInitializing = false
            statusMessage = "Initialization failed"
            print("❌ App startup failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func createServiceContainer() async throws {
        // Return if already created
        if let existing = serviceContainer {
            print("✅ ServiceContainer already created")
            _ = existing // noop
            return
        }

        // Coalesce concurrent creation attempts
        if let task = containerCreationTask {
            let container = try await task.value
            serviceContainer = container
            print("✅ Reused in-flight ServiceContainer creation task")
            return
        }

        let task = Task { @MainActor in
            try await ServiceContainer()
        }
        containerCreationTask = task
        do {
            let container = try await task.value
            serviceContainer = container
            print("✅ ServiceContainer created and configured")
        } catch {
            containerCreationTask = nil
            throw error
        }
        containerCreationTask = nil
    }
    
    private func configureNetworkMonitoring() {
        // Start network monitoring without waiting
        networkMonitor.forceUpdate()
        print("✅ Network monitoring configured: \(networkMonitor.isConnected ? "Online" : "Offline")")
    }
    
    // MARK: - Background Task Verification
    
    /// Verify Kevin's tasks in background after login (not during startup)
    public func verifyKevinTasksInBackground() async {
        guard isReady else { return }
        
        Task {
            do {
                let operationalData = OperationalDataManager.shared
                guard operationalData.isInitialized else {
                    print("⚠️ OperationalDataManager not initialized, skipping Kevin tasks verification")
                    return
                }
                
                // Get Kevin's tasks
                let kevinTasks = operationalData.getRealWorldTasks(for: "Kevin Dutan")
                print("📊 Background verification - Kevin's tasks: \(kevinTasks.count)")
                
                // Verify Rubin Museum assignment
                let hasRubinMuseum = kevinTasks.contains { task in
                    task.buildingId == "14" || task.building.contains("Rubin")
                }
                
                if hasRubinMuseum {
                    print("✅ Background verification - Kevin has Rubin Museum assignment")
                } else {
                    print("⚠️ Background verification - Kevin missing Rubin Museum assignment")
                }
                
            } catch {
                print("❌ Background Kevin tasks verification failed: \(error)")
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
