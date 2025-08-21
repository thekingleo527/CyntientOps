//
//  InitializationViewModel.swift
//  CyntientOps
//
//  Simple initialization view model that uses the existing DatabaseInitializer
//

import Foundation
import SwiftUI
import Combine

@MainActor
public class InitializationViewModel: ObservableObject {
    @Published public var isInitializing = false
    @Published public var isComplete = false
    @Published public var progress: Double = 0.0
    @Published public var statusMessage = "Preparing to initialize..."
    @Published public var error: Error?
    
    private let databaseInitializer = DatabaseInitializer.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // Observe the existing DatabaseInitializer
        databaseInitializer.$isInitialized
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isInitialized in
                self?.isComplete = isInitialized
                if isInitialized {
                    self?.progress = 1.0
                    self?.statusMessage = "Initialization complete!"
                }
            }
            .store(in: &cancellables)
        
        databaseInitializer.$initializationProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.progress = progress
            }
            .store(in: &cancellables)
        
        databaseInitializer.$currentStep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] step in
                self?.statusMessage = step
            }
            .store(in: &cancellables)
        
        databaseInitializer.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
    }
    
    public func startInitialization() async {
        guard !isInitializing && !isComplete else { return }
        
        isInitializing = true
        error = nil
        
        do {
            try await databaseInitializer.initializeIfNeeded()
        } catch {
            self.error = error
            print("❌ Initialization failed: \(error)")
        }
        
        isInitializing = false
    }
    
    public func retry() async {
        error = nil
        await startInitialization()
    }
}