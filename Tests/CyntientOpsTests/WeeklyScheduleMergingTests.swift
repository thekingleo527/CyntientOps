import XCTest
@testable import CyntientOps

@MainActor
final class WeeklyScheduleMergingTests: XCTestCase {
    func testWeeklyScheduleLoadsFromOperationalData() async throws {
        let service = ServiceContainer(
            database: GRDBManager.shared,
            operationalData: OperationalDataManager(database: GRDBManager.shared)
        )

        // Ensure seeds
        let status = await service.operationalData.getInitializationStatus()
        if !status.routinesSeeded {
            try await service.operationalData.initializeOperationalData()
        }

        // Kevin is worker id "4" in canonical ids
        let items = try await service.operationalData.getWorkerWeeklySchedule(for: "4")
        XCTAssertGreaterThan(items.count, 0, "Weekly schedule should not be empty for worker 4")
    }
}

