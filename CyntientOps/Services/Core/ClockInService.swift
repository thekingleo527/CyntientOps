
//  ClockInService.swift
//  CyntientOps (formerly CyntientOps)
//
//  Phase 0.2: ClockInService ObservableObject Wrapper
//  Wraps the existing ClockInManager actor for SwiftUI compatibility
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

@MainActor
public final class ClockInService: ObservableObject {
    
    // MARK: - Published State
    @Published public private(set) var clockedInWorkers: [String: ClockInStatus] = [:]
    @Published public private(set) var isProcessing = false
    @Published public private(set) var lastError: Error?
    @Published public private(set) var currentWorkerSession: ClockInSession?
    
    // MARK: - Clock In Status
    public struct ClockInStatus {
        public let workerId: String
        public let workerName: String
        public let buildingId: String
        public let buildingName: String
        public let clockInTime: Date
        public let location: CLLocation?
        public let sessionId: String
        
        public var duration: TimeInterval {
            Date().timeIntervalSince(clockInTime)
        }
        
        public var formattedDuration: String {
            let hours = Int(duration) / 3600
            let minutes = Int(duration) % 3600 / 60
            return String(format: "%02d:%02d", hours, minutes)
        }
    }
    
    // MARK: - Clock In Session (matches ClockInManager.ClockInSession)
    public struct ClockInSession {
        public let id: String
        public let workerId: String
        public let buildingId: String
        public let buildingName: String
        public let startTime: Date
        public let location: CLLocationCoordinate2D?
        
        public init(workerId: String, buildingId: String, buildingName: String, startTime: Date, location: CLLocationCoordinate2D?) {
            self.id = UUID().uuidString
            self.workerId = workerId
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.startTime = startTime
            self.location = location
        }
    }
    
    // MARK: - Dependencies
    private let clockInManager = ClockInManager.shared
    private let workerService = WorkerService.shared
    private let buildingService = BuildingService.shared
    private let locationManager = LocationManager.shared
    private let dashboardSync = DashboardSyncService.shared
    
    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    
    // MARK: - Initialization
    public init() {
        setupSubscriptions()
        startUpdateTimer()
        
        Task {
            await refreshClockInStatus()
        }
    }
    
    // MARK: - Public Methods
    
    /// Clock in a worker at a building
    public func clockIn(workerId: String, buildingId: String) async throws {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Get building details
            let building = try await buildingService.getBuilding(buildingId: buildingId)
            
            // Get current location if available
            let location = locationManager.location
            
            // Clock in through the actor
            try await clockInManager.clockIn(
                workerId: workerId,
                building: building,
                location: location?.coordinate
            )
            
            // Update local state
            await refreshClockInStatus()
            
            // Get worker name for status
            let workerProfile = try await workerService.getWorkerProfile(for: workerId)
            let workerName = workerProfile.name
            
            // Update current worker session if it's the current user
            if let currentUser = NewAuthManager.shared.currentUser,
               currentUser.workerId == workerId {
                currentWorkerSession = ClockInSession(
                    workerId: workerId,
                    buildingId: buildingId,
                    buildingName: building.name,
                    startTime: Date(),
                    location: location?.coordinate
                )
            }
            
            // Broadcast update
            dashboardSync.onWorkerClockedIn(
                workerId: workerId,
                buildingId: buildingId,
                buildingName: building.name
            )
            
            print("✅ Worker \(workerName) clocked in at \(building.name)")
            
        } catch {
            lastError = error
            throw error
        }
    }
    
    /// Clock out a worker
    public func clockOut(workerId: String) async throws {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Get current session before clocking out
            let status = await clockInManager.getClockInStatus(for: workerId)
            guard status.isClockedIn else {
                throw ClockInError.notClockedIn
            }
            
            // Get session info before clocking out
            let sessionBuildingId = status.building?.id ?? "unknown"
            let sessionBuildingName = status.building?.name ?? "Unknown Building"
            
            // Clock out through the actor
            try await clockInManager.clockOut(workerId: workerId)
            
            // Clear current worker session if it's the current user
            if currentWorkerSession?.workerId == workerId {
                currentWorkerSession = nil
            }
            
            // Update local state
            await refreshClockInStatus()
            
            // Broadcast update
            dashboardSync.onWorkerClockedOut(
                workerId: workerId,
                buildingId: sessionBuildingId
            )
            
            print("✅ Worker clocked out from \(sessionBuildingName)")
            
        } catch {
            lastError = error
            throw error
        }
    }
    
    /// Get available buildings for clock in
    public func getAvailableBuildings(for workerId: String) async throws -> [NamedCoordinate] {
        // Use building service to get all available buildings for this worker
        return try await buildingService.getBuildingsForWorker(workerId)
    }
    
    /// Get assigned buildings (for UI display)
    public func getAssignedBuildings(for workerId: String) async throws -> [NamedCoordinate] {
        // Same as available buildings - workers can only clock into assigned buildings
        return try await buildingService.getBuildingsForWorker(workerId)
    }
    
    /// Check if worker is clocked in
    public func isWorkerClockedIn(_ workerId: String) -> Bool {
        return clockedInWorkers[workerId] != nil
    }
    
    /// Get clock in status for a worker
    public func getClockInStatus(for workerId: String) -> ClockInStatus? {
        return clockedInWorkers[workerId]
    }
    
    /// Refresh all clock in statuses
    public func refreshClockInStatus() async {
        do {
            // Get all active sessions
            let sessions = await clockInManager.getAllActiveSessions()
            
            // Convert to our status format
            var newStatuses: [String: ClockInStatus] = [:]
            
            for session in sessions {
                // Get worker name
                let workerProfile = try? await workerService.getWorkerProfile(for: session.workerId)
                let workerName = workerProfile?.name ?? "Unknown"
                
                let status = ClockInStatus(
                    workerId: session.workerId,
                    workerName: workerName,
                    buildingId: session.buildingId,
                    buildingName: session.buildingName,
                    clockInTime: session.startTime,
                    location: session.location.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) },
                    sessionId: session.id
                )
                
                newStatuses[session.workerId] = status
            }
            
            // Update published state
            clockedInWorkers = newStatuses
            
        } catch {
            print("❌ Failed to refresh clock in status: \(error)")
            lastError = error
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Listen for clock in/out notifications
        NotificationCenter.default.publisher(for: .workerClockInChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshClockInStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    private func startUpdateTimer() {
        // Update clock in durations every minute
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.objectWillChange.send()
            }
        }
    }
}

// MARK: - Clock In Error (matching ClockInManager)

public enum ClockInError: LocalizedError {
    case alreadyClockedIn
    case notClockedIn
    case invalidLocation
    case buildingNotFound
    case databaseError(String)
    
    public var errorDescription: String? {
        switch self {
        case .alreadyClockedIn:
            return "Already clocked in at another building"
        case .notClockedIn:
            return "Not currently clocked in"
        case .invalidLocation:
            return "Invalid location for clock in"
        case .buildingNotFound:
            return "Building not found"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let workerClockInChanged = Notification.Name("workerClockInChanged")
}
