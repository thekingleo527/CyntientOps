//
//  SiteDepartureViewModel.swift
//  CyntientOps
//
//  ViewModel for managing site departure checklist and verification
//

import SwiftUI
import CoreLocation
import UIKit

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
    // New single-site API
    @Published public var section: DepartureSection?
    @Published public var errorMessage: String?
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
            
            // Convert to BuildingDepartureEntry objects (initial pass; requiresPhoto resolved below)
            let buildingList = Array(buildingsWorked).compactMap { buildingId -> BuildingDepartureEntry? in
                guard let buildingName = WorkerBuildingAssignments.getBuildingName(for: buildingId) else { return nil }
                return BuildingDepartureEntry(
                    id: buildingId,
                    name: buildingName,
                    address: nil, // Could be enhanced with actual addresses
                    tasksComplete: false,
                    photos: [],
                    requiresPhoto: false,
                    note: nil
                )
            }
            
            var finalList = buildingList

            // DSNY fallback: after 8pm, if sparse, include circuit buildings that require set‑out
            let cal = Calendar.current
            let hour = cal.component(.hour, from: date)
            if hour >= 20 && finalList.count <= 1 { // "sparse" threshold
                let day = CollectionDay.from(weekday: cal.component(.weekday, from: date))
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

            // Resolve per-building photo requirements based on actual tasks
            var enriched: [BuildingDepartureEntry] = []
            for var entry in finalList {
                entry.requiresPhoto = await requiresPhotoForBuilding(entry.id)
                enriched.append(entry)
            }

            self.buildingEntries = enriched
            recomputeSubmitState()
            isLoading = false
            
        } catch {
            self.error = error
            isLoading = false
        }
    }

    // MARK: - Single-site API (surgical)
    public var allTasksComplete: Bool {
        guard let s = section else { return false }
        return s.tasksRequired > 0 && s.tasksCompleted == s.tasksRequired
    }
    public var photosComplete: Bool {
        guard let s = section else { return false }
        return s.photosAttached >= s.photosRequired
    }
    public var checklistCountDone: Int { (allTasksComplete ? 1 : 0) + (photosComplete ? 1 : 0) }
    public var checklistCountTotal: Int { 2 }

    /// Hydrate from one source of truth
    public func hydrate() async {
        await MainActor.run { self.isLoading = true }
        defer { Task { await MainActor.run { self.isLoading = false } } }
        do {
            // Pick building: current clock-in or route fallback
            let status = await container.clockIn.getClockInStatus(for: workerId)
            var building = currentBuilding
            if let status = status, status.isClockedIn, let b = status.building { building = b }
            else if let b = await routeCurrentOrNext() { building = b }

            let today = Date()
            let tasks = try await container.tasks.fetchDailyTasks(workerId: workerId, buildingId: building.id, date: today)
            let tasksRequired = tasks.filter { !$0.isCancelled }.count
            let tasksCompleted = tasks.filter { $0.status == .completed }.count
            let photosRequired = max(1, tasks.filter { $0.requiresPhoto ?? false }.count)
            let photosAttached = try await container.photos.countFor(date: today, buildingId: building.id, workerId: workerId)
            await MainActor.run {
                self.section = DepartureSection(buildingId: building.id, buildingName: building.name, tasksRequired: tasksRequired, tasksCompleted: tasksCompleted, photosRequired: photosRequired, photosAttached: photosAttached)
            }
            log("picked building=\(building.id) \(building.name)")
            log("tasks r/c=\(tasksRequired)/\(tasksCompleted) photos r/c=\(photosRequired)/\(photosAttached)")
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription }
        }
    }

    public func markAllTasksComplete() async throws {
        guard let s = section else { return }
        await MainActor.run { self.isSaving = true }
        defer { await MainActor.run { self.isSaving = false } }
        try await container.tasks.completeAllFor(workerId: workerId, buildingId: s.buildingId, date: Date())
        await hydrate()
    }

    public func attachPhoto(_ image: UIImage) async throws {
        guard let s = section else { return }
        await MainActor.run { self.isSaving = true }
        defer { await MainActor.run { self.isSaving = false } }
        try await container.photos.attach(image: image, date: Date(), buildingId: s.buildingId, workerId: workerId)
        await hydrate()
    }

    public func canClockOut() -> Bool { allTasksComplete && photosComplete }

    private func routeCurrentOrNext() async -> CoreTypes.NamedCoordinate? {
        let weekday = Calendar.current.component(.weekday, from: Date())
        if let route = RouteManager.shared.getRoute(for: workerId, dayOfWeek: weekday) {
            let now = Date()
            if let active = route.sequences.first(where: { now >= $0.arrivalTime && now <= $0.arrivalTime.addingTimeInterval($0.estimatedDuration) }) {
                return try? await container.buildings.getBuilding(buildingId: active.buildingId)
            }
            if let next = route.sequences.sorted(by: { $0.arrivalTime < $1.arrivalTime }).first(where: { $0.arrivalTime > now }) {
                return try? await container.buildings.getBuilding(buildingId: next.buildingId)
            }
            if let first = route.sequences.first {
                return try? await container.buildings.getBuilding(buildingId: first.buildingId)
            }
        }
        return nil
    }

    private func log(_ msg: String) { print("🧭 SiteDepartureVM:", msg) }
    
    private func requiresPhotoForBuilding(_ buildingId: String) async -> Bool {
        do {
            let tasks = try await container.tasks.getTasksForBuilding(buildingId)
            // Require photo if any task explicitly requires it, or if sanitation/cleaning exists per worker policy
            if tasks.contains(where: { ($0.requiresPhoto ?? false) && !$0.isCompleted }) { return true }
            if tasks.contains(where: { ($0.category == .sanitation || $0.category == .cleaning) && !$0.isCompleted }) {
                return true
            }
            return false
        } catch {
            // On failure, err on the side of requiring photo to avoid missing evidence
            return true
        }
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
