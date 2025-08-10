//  InitializationViewModel.swift
//  CyntientOps
//
//  Simple initialization view model without progress tracking
//  Used only for the brief splash screen during app startup
//

import Foundation
import SwiftUI
import Combine

@MainActor
class InitializationViewModel: ObservableObject {
    @Published var isInitializing: Bool = false
    @Published var isComplete: Bool = false
    @Published var initializationError: String?
    
    // Dependencies
    private let appStartup = AppStartupCoordinator.shared
    
    init() {}
    
    // MARK: - Public Methods
    
    func startInitialization() async {
        guard !isInitializing else { return }
        
        isInitializing = true
        isComplete = false
        initializationError = nil
        
        do {
            // Use the simplified AppStartupCoordinator
            try await appStartup.startInitialization()
            
            // Complete
            isComplete = true
            isInitializing = false
            
            print("✅ App initialization completed successfully")
            
        } catch {
            initializationError = error.localizedDescription
            isInitializing = false
            print("❌ App initialization failed: \(error)")
        }
    }
    
    func retryInitialization() async {
        initializationError = nil
        await startInitialization()
    }
}
