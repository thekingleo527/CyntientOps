//
//  WorkerManager.swift
//  CyntientOps
//
//  ✅ FIXED: Added proper CoreTypes references
//  ✅ FIXED: Corrected shared instance reference
//  ✅ FIXED: All type references use CoreTypes prefix
//

import Foundation
import Combine

@MainActor
public class WorkerManager: ObservableObject {
    public static let shared = WorkerManager()  // ✅ FIXED: Should be WorkerManager, not WorkerService
    
    @Published public var currentWorker: CoreTypes.WorkerProfile?  // ✅ FIXED: Added CoreTypes prefix
    @Published public var allWorkers: [CoreTypes.WorkerProfile] = []  // ✅ FIXED: Added CoreTypes prefix
    @Published public var isLoading = false
    @Published public var error: Error?
    
    // Worker data is currently loaded directly from GRDBManager
    
    private init() {
        loadWorkers()
    }
    
    private func loadWorkers() {
        // ✅ FIXED: Load from actual data or use empty array initially
        Task {
            do {
                // Load workers directly from database since workerService isn't available
                let rows = try await GRDBManager.shared.query("""
                    SELECT id, name, email, role, isActive, currentBuildingId, clockStatus 
                    FROM workers WHERE isActive = 1
                """, [])
                
                self.allWorkers = rows.compactMap { row -> CoreTypes.WorkerProfile? in
                    guard let id = row["id"] as? String,
                          let name = row["name"] as? String,
                          let email = row["email"] as? String,
                          let roleString = row["role"] as? String,
                          let role = CoreTypes.UserRole(rawValue: roleString) else { return nil }
                    
                    return CoreTypes.WorkerProfile(
                        id: id,
                        name: name,
                        email: email,
                        role: role,
                        isActive: (row["isActive"] as? Int64 ?? 0) == 1,
                        currentBuildingId: row["currentBuildingId"] as? String,
                        clockStatus: CoreTypes.ClockStatus(rawValue: row["clockStatus"] as? String ?? "clockedOut") ?? .clockedOut
                    )
                }
            } catch {
                self.error = error
                self.allWorkers = []
            }
        }
    }
    
    public func getWorker(by id: String) -> CoreTypes.WorkerProfile? {  // ✅ FIXED: Added CoreTypes prefix
        return allWorkers.first { $0.id == id }
    }
    
    public func setCurrentWorker(_ workerId: String) {
        currentWorker = getWorker(by: workerId)
    }
    
    public func getAllActiveWorkers() -> [CoreTypes.WorkerProfile] {  // ✅ FIXED: Added CoreTypes prefix
        return allWorkers.filter { $0.isActive }
    }
    
    public func loadWorkerBuildings(_ workerId: String) async throws -> [CoreTypes.NamedCoordinate] {  // ✅ FIXED: Added CoreTypes prefix
        // Load worker's assigned buildings directly from database
        let rows = try await GRDBManager.shared.query("""
            SELECT b.id, b.name, b.address, b.latitude, b.longitude FROM buildings b
            JOIN worker_building_assignments wba ON b.id = wba.building_id
            WHERE wba.worker_id = ? AND wba.is_active = 1
        """, [workerId])
        
        return rows.compactMap { row -> CoreTypes.NamedCoordinate? in
            guard let id = row["id"] as? String,
                  let name = row["name"] as? String,
                  let address = row["address"] as? String else { return nil }
            
            return CoreTypes.NamedCoordinate(
                id: id,
                name: name,
                address: address,
                latitude: row["latitude"] as? Double ?? 0,
                longitude: row["longitude"] as? Double ?? 0
            )
        }
    }
    
    public func getWorkerTasks(for workerId: String, date: Date) async throws -> [CoreTypes.ContextualTask] {  // ✅ FIXED: Added CoreTypes prefix
        // Load tasks directly from database since TaskService isn't available
        let dateFormatter = ISO8601DateFormatter()
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let rows = try await GRDBManager.shared.query("""
            SELECT * FROM tasks 
            WHERE assignee_id = ? AND scheduled_date >= ? AND scheduled_date < ?
        """, [workerId, dateFormatter.string(from: startOfDay), dateFormatter.string(from: endOfDay)])
        
        return rows.compactMap { row -> CoreTypes.ContextualTask? in
            guard let id = row["id"] as? String,
                  let title = row["title"] as? String else { return nil }
            
            return CoreTypes.ContextualTask(
                id: id,
                title: title,
                description: row["description"] as? String,
                status: CoreTypes.TaskStatus(rawValue: row["status"] as? String ?? "pending") ?? .pending,
                createdAt: Date()
            )
        }
    }
}
