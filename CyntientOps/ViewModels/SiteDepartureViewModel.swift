//
//  SiteDepartureViewModel.swift
//  CyntientOps
//
//  ViewModel for managing site departure checklist and verification
//

import SwiftUI
import CoreLocation

@MainActor
public class SiteDepartureViewModel: ObservableObject {
    @Published var checklist: DepartureChecklist?
    @Published var checkmarkStates: [String: Bool] = [:]
    @Published var departureNotes = ""
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var showPhotoRequirement = false
    @Published var capturedPhoto: UIImage?
    @Published var selectedNextDestination: CoreTypes.NamedCoordinate?
    @Published var error: Error?
    
    let workerId: String
    let currentBuilding: CoreTypes.NamedCoordinate
    let workerCapabilities: WorkerCapability?
    let availableBuildings: [CoreTypes.NamedCoordinate]
    
    private let locationManager = LocationManager.shared
    
    // MARK: - Worker Capability Structure
    public struct WorkerCapability {
        let canUploadPhotos: Bool
        let canAddNotes: Bool
        let canViewMap: Bool
        let canAddEmergencyTasks: Bool
        let requiresPhotoForSanitation: Bool
        let simplifiedInterface: Bool
    }
    
    var requiresPhoto: Bool {
        guard let checklist = checklist,
              let capabilities = workerCapabilities else { return false }
        
        // Photo required if worker can take photos AND has sanitation tasks
        return capabilities.canUploadPhotos &&
               checklist.allTasks.contains { $0.category == .sanitation || $0.category == .cleaning }
    }
    
    var canDepart: Bool {
        // All incomplete tasks must be checked
        guard let checklist = checklist else { return false }
        
        let allIncompleteChecked = checklist.incompleteTasks.allSatisfy { task in
            checkmarkStates[task.id] ?? false
        }
        
        let photoRequirementMet = !requiresPhoto || capturedPhoto != nil
        
        return allIncompleteChecked && photoRequirementMet && !isSaving
    }
    
    var isFullyCompliant: Bool {
        guard let checklist = checklist else { return false }
        return checklist.incompleteTasks.isEmpty &&
               (!requiresPhoto || capturedPhoto != nil)
    }
    
    init(workerId: String,
         currentBuilding: CoreTypes.NamedCoordinate,
         capabilities: WorkerCapability?,
         availableBuildings: [CoreTypes.NamedCoordinate]) {
        self.workerId = workerId
        self.currentBuilding = currentBuilding
        self.workerCapabilities = capabilities
        self.availableBuildings = availableBuildings.filter { $0.id != currentBuilding.id }
    }
    
    func loadChecklist() async {
        isLoading = true
        error = nil
        
        do {
            let checklist = try await TaskService.shared.getDepartureChecklistItems(
                for: workerId,
                buildingId: currentBuilding.id
            )
            
            self.checklist = checklist
            
            // Initialize checkmarks for incomplete tasks
            for task in checklist.incompleteTasks {
                checkmarkStates[task.id] = false
            }
            
            isLoading = false
            
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    func finalizeDeparture(method: DepartureMethod = .normal) async -> Bool {
        guard let checklist = checklist else { return false }
        
        isSaving = true
        error = nil
        
        do {
            // Save photo if captured
            if let photo = capturedPhoto, requiresPhoto {
                // Create a synthetic task for the departure photo
                let departureTask = CoreTypes.ContextualTask(
                    id: "departure-\(currentBuilding.id)-\(Date().timeIntervalSince1970)",
                    title: "Site Departure - \(currentBuilding.name)",
                    description: "Departure verification photo",
                    status: .completed,
                    dueDate: Date(),
                    category: .administrative,
                    urgency: .medium,
                    buildingId: currentBuilding.id
                )
                
                let worker = CoreTypes.WorkerProfile(
                    id: workerId,
                    name: "Worker \(workerId)", // Would be fetched from context
                    email: "",
                    phone: nil,
                    role: .worker,
                    isActive: true
                )
                
                let evidence = try await PhotoEvidenceService.shared.captureEvidence(
                    image: photo,
                    for: departureTask,
                    worker: worker,
                    location: locationManager.location,
                    notes: "Departure photo for \(currentBuilding.name)"
                )
                
                print("✅ Departure photo saved: \(evidence.id)")
            }
            
            // Create departure log
            let logId = try await SiteLogService.shared.createDepartureLog(
                workerId: workerId,
                buildingId: currentBuilding.id,
                checklist: checklist,
                isCompliant: isFullyCompliant,
                notes: departureNotes.isEmpty ? nil : departureNotes,
                nextDestination: selectedNextDestination?.id,
                departureMethod: method,
                location: locationManager.location
            )
            
            print("✅ Departure log created: \(logId)")
            
            isSaving = false
            return true
            
        } catch {
            self.error = error
            isSaving = false
            return false
        }
    }
}
