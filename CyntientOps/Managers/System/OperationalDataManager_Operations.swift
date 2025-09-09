import Foundation
import GRDB
import Combine

// MARK: - Date Extension (Fix for iso8601String)
// Date extension is in OperationalDataManager.swift

// SystemConfiguration is defined in OperationalDataManager.swift

// MARK: - Admin Fetch Helpers
// Lightweight, read-only helpers to support Admin dashboards.

public extension OperationalDataManager {
    struct AdminSummary {
        public let buildings: [CoreTypes.NamedCoordinate]
        public let workers: [CoreTypes.WorkerProfile]
        public init(buildings: [CoreTypes.NamedCoordinate], workers: [CoreTypes.WorkerProfile]) {
            self.buildings = buildings
            self.workers = workers
        }
    }

    /// Fetch all active buildings for admin views (GRDB-backed; lightweight mapping)
    @MainActor
    func fetchAllBuildings() async throws -> [CoreTypes.NamedCoordinate] {
        do {
            let rows = try await GRDBManager.shared.query(
                """
                SELECT * FROM buildings
                WHERE isActive = 1
                ORDER BY name
                """
            )

            let result: [CoreTypes.NamedCoordinate] = rows.compactMap { row in
                let idString: String
                if let idInt = row["id"] as? Int64 {
                    idString = String(idInt)
                } else if let idStr = row["id"] as? String {
                    idString = idStr
                } else { return (nil as CoreTypes.NamedCoordinate?) }

                guard let name = row["name"] as? String,
                      let address = row["address"] as? String,
                      let latitude = row["latitude"] as? Double,
                      let longitude = row["longitude"] as? Double else { return nil }

                return CoreTypes.NamedCoordinate(
                    id: idString,
                    name: name,
                    address: address,
                    latitude: latitude,
                    longitude: longitude
                )
            }
            return result
        } catch {
            // Fallback: return empty list (or seed if available in-memory)
            return []
        }
    }

    /// Fetch all active worker profiles for admin views (GRDB-backed; lightweight mapping)
    @MainActor
    func fetchAllWorkers() async throws -> [CoreTypes.WorkerProfile] {
        do {
            let rows = try await GRDBManager.shared.query(
                """
                SELECT * FROM workers
                WHERE isActive = 1 AND role = 'worker'
                ORDER BY name
                """
            )

            let result: [CoreTypes.WorkerProfile] = rows.compactMap { row in
                // id
                let idString: String
                if let idInt = row["id"] as? Int64 {
                    idString = String(idInt)
                } else if let idStr = row["id"] as? String {
                    idString = idStr
                } else { return (nil as CoreTypes.WorkerProfile?) }

                // required fields
                guard let name = row["name"] as? String,
                      let email = row["email"] as? String else { return nil }

                let roleStr = (row["role"] as? String) ?? CoreTypes.UserRole.worker.rawValue
                let role = CoreTypes.UserRole(rawValue: roleStr) ?? .worker
                let isActive = ((row["isActive"] as? Int64).map { $0 != 0 }) ?? true

                // optional/derived
                let assigned: [String] = [] // lightweight; can be filled by separate query if needed

                return CoreTypes.WorkerProfile(
                    id: idString,
                    name: name,
                    email: email,
                    role: role,
                    isActive: isActive,
                    assignedBuildingIds: assigned,
                    status: .offline,
                    isClockedIn: false
                )
            }
            return result
        } catch {
            // Fallback: return empty list
            return []
        }
    }

    /// Fetch a combined admin summary (runs building + worker fetch concurrently)
    @MainActor
    func fetchAdminSummary() async throws -> AdminSummary {
        async let b = fetchAllBuildings()
        async let w = fetchAllWorkers()
        return AdminSummary(buildings: try await b, workers: try await w)
    }
}

// MARK: - Compatibility Shims
// Provide temporary shims to preserve older call sites while migrating.
@MainActor
extension OperationalDataManager {
    public func getAllBuildings() -> [CoreTypes.NamedCoordinate] {
        let result = try? awaitResult { try await self.fetchAllBuildings() }
        return result ?? []
    }

    public func getAllWorkers() -> [CoreTypes.WorkerProfile] {
        let result = try? awaitResult { try await self.fetchAllWorkers() }
        return result ?? []
    }

    /// Helper to bridge async calls into a synchronous context safely on MainActor
    private func awaitResult<T>(_ operation: @escaping () async throws -> T) throws -> T {
        var output: Result<T, Error>?
        let semaphore = DispatchSemaphore(value: 0)
        Task { @MainActor in
            do { output = .success(try await operation()) } catch { output = .failure(error) }
            semaphore.signal()
        }
        semaphore.wait()
        switch output! {
        case .success(let value): return value
        case .failure(let err): throw err
        }
    }
}
