import XCTest
@testable import CyntientOps

@MainActor
final class ClockStateTransitionsTests: XCTestCase {
    func testClockInOutTransitionsPersist() async throws {
        let container = ServiceContainer(
            database: GRDBManager.shared,
            operationalData: OperationalDataManager(database: GRDBManager.shared)
        )
        let clock = container.clockIn

        // Worker 4 (Kevin) at building 10 (131 Perry Street)
        let workerId = "4"
        let building = NamedCoordinate(id: "10", name: "131 Perry Street", address: "131 Perry St", latitude: 40.7357, longitude: -74.0060)

        // Make sure we end any previous session to avoid state leakage
        if clock.isWorkerClockedIn(workerId) {
            try? await clock.clockOut(workerId: workerId)
        }

        // Clock in
        try await ClockInManager.shared.clockIn(workerId: workerId, building: building)
        XCTAssertTrue(clock.isWorkerClockedIn(workerId), "Worker should be clocked in after clockIn call")

        // Clock out
        try await clock.clockOut(workerId: workerId)
        XCTAssertFalse(clock.isWorkerClockedIn(workerId), "Worker should be clocked out after clockOut call")
    }
}

