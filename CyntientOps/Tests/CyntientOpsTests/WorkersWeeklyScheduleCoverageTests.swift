import XCTest
@testable import CyntientOps

@MainActor
final class WorkersWeeklyScheduleCoverageTests: XCTestCase {
    func testWeeklySchedulesExistForCoreWorkers() async throws {
        let op = OperationalDataManager.shared
        let status = await op.getInitializationStatus()
        if !status.routinesSeeded {
            try await op.initializeOperationalData()
        }

        let workers = [
            CanonicalIDs.Workers.kevinDutan,
            CanonicalIDs.Workers.edwinLema,
            CanonicalIDs.Workers.mercedesInamagua
        ]

        for wid in workers {
            let weekly = try await op.getWorkerWeeklySchedule(for: wid)
            XCTAssertGreaterThan(weekly.count, 0, "Expected weekly schedule for worker id \(wid)")
        }
    }
}
