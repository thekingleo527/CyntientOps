import XCTest
@testable import CyntientOps

final class WeatherSuggestionLinkageTests: XCTestCase {
    func testRainSuggestsIndoorForOutdoorTasks() {
        // Create a contextual sanitation task due in ~1 hour (outdoor-sensitive)
        let due = Date().addingTimeInterval(3600)
        let task = CoreTypes.ContextualTask(
            id: "t1",
            title: "DSNY Set-out",
            description: "Set out bins",
            status: .pending,
            completedAt: nil,
            scheduledDate: nil,
            dueDate: due,
            category: .sanitation,
            urgency: .normal,
            building: nil,
            worker: nil,
            buildingId: CanonicalIDs.Buildings.perry131,
            buildingName: CanonicalIDs.Buildings.getName(for: CanonicalIDs.Buildings.perry131),
            assignedWorkerId: CanonicalIDs.Workers.kevinDutan,
            priority: .normal,
            frequency: nil,
            requiresPhoto: true,
            estimatedDuration: 45
        )

        // Construct a snapshot with high precip near task time
        let current = WeatherSnapshot.Current(tempF: 60, condition: "Rain", windMph: 10)
        let blocks: [WeatherSnapshot.HourBlock] = (0..<12).map { i in
            let date = Date().addingTimeInterval(TimeInterval(i) * 3600)
            let precip: Double = i == 1 ? 0.8 : 0.1
            return WeatherSnapshot.HourBlock(date: date, precipProb: precip, windMph: 12, tempF: 60)
        }
        let snap = WeatherSnapshot(current: current, hourly: blocks)

        let scored = WeatherScoreBuilder.score(task: task, weather: snap)
        XCTAssertNotNil(scored.advice, "Expected weather advice for rainy conditions")
        XCTAssertTrue(scored.chip == .heavyRain || scored.chip == .wet, "Expected rainy chip for outdoor task")

        let row = TaskRowVM(scored: scored)
        XCTAssertNotNil(row.advice)
    }
}

