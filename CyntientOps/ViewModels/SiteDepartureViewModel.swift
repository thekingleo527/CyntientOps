//
//  SiteDepartureViewModel.swift
//  CyntientOps
//
//  ViewModel for managing site departure checklist and verification
//

import SwiftUI
import CoreLocation

// MARK: - Building Departure Entry Model
public struct BuildingDepartureEntry: Identifiable {
    public let id: String           // buildingId
    public let name: String
    public let address: String?
    public var tasksComplete: Bool
    public var photos: [UIImage]    // attach here - could be enhanced to PhotoEvidence
    public var requiresPhoto: Bool
    public var note: String?
    
    public init(id: String, name: String, address: String?, tasksComplete: Bool, photos: [UIImage], requiresPhoto: Bool, note: String?) {
        self.id = id
        self.name = name
        self.address = address
        self.tasksComplete = tasksComplete
        self.photos = photos
        self.requiresPhoto = requiresPhoto
        self.note = note
    }
}

@MainActor
public class SiteDepartureViewModel: ObservableObject {
    @Published var checklist: DepartureChecklist?
    @Published var checkmarkStates: [String: Bool] = [:]
    @Published var departureNotes = ""
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var showPhotoRequirement = false
    @Published var capturedPhotos: [UIImage] = []
    @Published var capturedPhoto: UIImage?
    @Published var selectedNextDestination: CoreTypes.NamedCoordinate?
    @Published var error: Error?
    
    // NEW: Building-based departure flow
    @Published var buildingEntries: [BuildingDepartureEntry] = []
    @Published var canSubmit = false
    
    let workerId: String
    let currentBuilding: CoreTypes.NamedCoordinate
    let workerCapabilities: WorkerCapability?
    let availableBuildings: [CoreTypes.NamedCoordinate]
    
    private let locationManager = LocationManager.shared
    private let container: ServiceContainer
    
    // MARK: - Initialization
    
    public init(
        workerId: String,
        currentBuilding: CoreTypes.NamedCoordinate,
        workerCapabilities: WorkerCapability? = nil,
        availableBuildings: [CoreTypes.NamedCoordinate] = [],
        container: ServiceContainer
    ) {
        self.workerId = workerId
        self.currentBuilding = currentBuilding
        self.workerCapabilities = workerCapabilities
        self.availableBuildings = availableBuildings
        self.container = container
    }
    
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
        
        let photoRequirementMet = !requiresPhoto || !capturedPhotos.isEmpty || capturedPhoto != nil
        
        return allIncompleteChecked && photoRequirementMet && !isSaving
    }
    
    var isFullyCompliant: Bool {
        guard let checklist = checklist else { return false }
        return checklist.incompleteTasks.isEmpty &&
               (!requiresPhoto || !capturedPhotos.isEmpty || capturedPhoto != nil)
    }
    
    
    func loadChecklist() async {
        isLoading = true
        error = nil
        
        do {
            let checklist = try await container.tasks.getDepartureChecklistItems(
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
    
    // MARK: - NEW Building-Based Departure Methods
    
    func load(for workerId: String, on date: Date) async {
        isLoading = true
        error = nil
        
        do {
            // Get routes for the worker on the specified date
            let routes = await RouteManager.shared.getRoutes(for: workerId).filter { route in
                Calendar.current.component(.weekday, from: date) == route.dayOfWeek
            }
            
            // Extract unique buildings from routes
            var buildingsWorked = Set<String>()
            for route in routes {
                for sequence in route.sequences {
                    buildingsWorked.insert(sequence.buildingId)
                }
            }
            
            // Convert to BuildingDepartureEntry objects
            let buildingList = Array(buildingsWorked).compactMap { buildingId -> BuildingDepartureEntry? in
                guard let buildingName = WorkerBuildingAssignments.getBuildingName(for: buildingId) else { return nil }
                return BuildingDepartureEntry(
                    id: buildingId,
                    name: buildingName,
                    address: nil, // Could be enhanced with actual addresses
                    tasksComplete: false,
                    photos: [],
                    requiresPhoto: requiresPhotoForBuilding(buildingId),
                    note: nil
                )
            }
            
            var finalList = buildingList

            // DSNY fallback: after 8pm, if sparse, include circuit buildings that require set‑out
            let cal = Calendar.current
            let hour = cal.component(.hour, from: date)
            if hour >= 20 && finalList.count <= 1 { // "sparse" threshold
                let day = DSNYCollectionSchedule.CollectionDay.from(weekday: cal.component(.weekday, from: date))
                let setout = DSNYCollectionSchedule.getBuildingsForBinSetOut(on: day)
                let dsnyEntries: [BuildingDepartureEntry] = setout.map { sched in
                    BuildingDepartureEntry(
                        id: sched.buildingId,
                        name: sched.buildingName,
                        address: nil,
                        tasksComplete: false,
                        photos: [],
                        requiresPhoto: true,
                        note: "DSNY set‑out"
                    )
                }
                // Merge, avoiding duplicates by id
                var seen = Set(finalList.map { $0.id })
                for e in dsnyEntries where !seen.contains(e.id) {
                    finalList.append(e)
                    seen.insert(e.id)
                }
            }

            self.buildingEntries = finalList
            recomputeSubmitState()
            isLoading = false
            
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    private func requiresPhotoForBuilding(_ buildingId: String) -> Bool {
        // Check if any tasks for this building require photos
        // For now, default to true for sanitation/cleaning tasks
        return true // Simplified logic - could be enhanced with task-specific requirements
    }
    
    public func recomputeSubmitState() {
        canSubmit = buildingEntries.allSatisfy { entry in
            entry.tasksComplete && (!entry.requiresPhoto || !entry.photos.isEmpty)
        }
    }
    
    func submit(workerId: String) async throws {
        isSaving = true
        error = nil
        
        do {
            for entry in buildingEntries {
                // Create a departure checklist for this building
                let checklist = DepartureChecklist(
                    allTasks: [],
                    completedTasks: [],
                    incompleteTasks: [],
                    photoCount: entry.photos.count,
                    timeSpentMinutes: 30, // Placeholder
                    requiredPhotoCount: entry.requiresPhoto ? 1 : 0
                )
                
                _ = try await SiteLogService.shared.createDepartureLog(
                    workerId: workerId,
                    buildingId: entry.id,
                    checklist: checklist,
                    isCompliant: entry.tasksComplete && (!entry.requiresPhoto || !entry.photos.isEmpty),
                    notes: entry.note,
                    dashboardSync: container.dashboardSync
                )
            }
            isSaving = false
        } catch {
            self.error = error
            isSaving = false
            throw error
        }
    }
    
    // MARK: - Legacy Methods (kept for compatibility)
    
    func finalizeDeparture(method: DepartureMethod = .normal) async -> Bool {
        guard let checklist = checklist else { return false }
        
        isSaving = true
        error = nil
        
        do {
            // Save photos if captured (up to 3). Fall back to single legacy capturedPhoto.
            let worker = CoreTypes.WorkerProfile(
                id: workerId,
                name: "Worker \(workerId)", // Ideally from context
                email: "",
                phone: nil,
                role: .worker,
                isActive: true
            )
            if !capturedPhotos.isEmpty {
                for (idx, photo) in capturedPhotos.prefix(10).enumerated() {
                    let evidence = try await container.photos.captureQuick(
                        image: photo,
                        category: .afterWork,
                        buildingId: currentBuilding.id,
                        workerId: worker.id,
                        notes: idx == 0 ? "Departure photo for \(currentBuilding.name)" : "Departure photo #\(idx+1) for \(currentBuilding.name)"
                    )
                    print("✅ Departure photo saved: \(evidence.id)")
                }
            } else if let photo = capturedPhoto {
                let evidence = try await container.photos.captureQuick(
                    image: photo,
                    category: .afterWork,
                    buildingId: currentBuilding.id,
                    workerId: worker.id,
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
                location: locationManager.location,
                dashboardSync: container.dashboardSync
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
