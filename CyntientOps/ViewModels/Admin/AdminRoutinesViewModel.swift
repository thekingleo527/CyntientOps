
//
//  AdminRoutinesViewModel.swift
//  CyntientOps
//
//  Created by Gemini on 2025-09-08.
//

import Foundation
import Combine

@MainActor
final class AdminRoutinesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var routines: [WorkerRoutine] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let routeManager: RouteManager
    private let workerService: WorkerService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        routeManager: RouteManager = .shared,
        workerService: WorkerService
    ) {
        self.routeManager = routeManager
        self.workerService = workerService
    }
    
    // MARK: - Public Methods
    
    func loadRoutines() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let workers = try await workerService.getAllActiveWorkers()
            var routines: [WorkerRoutine] = []
            
            for worker in workers {
                if let route = routeManager.getCurrentRoute(for: worker.id) {
                    routines.append(WorkerRoutine(workerId: worker.id, workerName: worker.name, route: route))
                }
            }
            
            self.routines = routines
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Supporting Types
    
    struct WorkerRoutine {
        let workerId: String
        let workerName: String
        let route: WorkerRoute
    }
}
