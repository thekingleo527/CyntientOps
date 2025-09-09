import Foundation
import SwiftUI
import Combine

@MainActor
public final class PortfolioScheduleViewModel: ObservableObject {

    // MARK: - Types
    public struct ScheduleItem: Identifiable, Hashable {
        public let id: String
        public let day: Int // 1...7 weekday
        public let startTime: Date
        public let endTime: Date
        public let buildingId: String
        public let buildingName: String
        public let workerId: String
        public let workerName: String
        public let title: String
        public let taskCount: Int
    }

    public struct DaySection: Identifiable {
        public let id: Int // weekday
        public let date: Date
        public let items: [ScheduleItem]
    }

    // MARK: - Published
    @Published public private(set) var weekSections: [DaySection] = []
    @Published public private(set) var monthMap: [Int: [ScheduleItem]] = [:]
    @Published public private(set) var monthRefDate: Date?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var lastUpdated: Date?
    @Published public var filterWorkerId: String? = nil
    @Published public var filterBuildingId: String? = nil
    @Published public var useWeatherOptimized: Bool = false

    // MARK: - Deps
    private let container: ServiceContainer
    private let calendar = Calendar.current

    public init(container: ServiceContainer) {
        self.container = container
    }

    // MARK: - Week
    public func loadWeek(starting reference: Date = Date()) async {
        isLoading = true
        defer { isLoading = false }

        // Use Range<Int> to avoid mixing Range and ClosedRange
        let weekRange: Range<Int> = calendar.range(of: .weekday, in: .weekOfYear, for: reference) ?? (1..<8)
        let weekdayRef = calendar.component(.weekday, from: reference)
        let startOfDay = calendar.startOfDay(for: reference)
        let baseDate = startOfDay.addingTimeInterval(TimeInterval(-86400 * (weekdayRef - weekRange.lowerBound)))
        let todayWeekday = calendar.component(.weekday, from: Date())
        let snapshot = currentWeatherSnapshot()

        var sections: [DaySection] = []
        for offset in weekRange {
            guard let date = calendar.date(byAdding: .day, value: offset - weekRange.lowerBound, to: baseDate) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            let items = await buildItemsForDay(weekday: weekday, optimizeForWeather: useWeatherOptimized && weekday == todayWeekday, weather: snapshot)
            let filtered = items.filter { item in
                (filterWorkerId == nil || item.workerId == filterWorkerId) &&
                (filterBuildingId == nil || item.buildingId == filterBuildingId)
            }
            sections.append(DaySection(id: weekday, date: date, items: filtered.sorted { $0.startTime < $1.startTime }))
        }
        weekSections = sections
        lastUpdated = Date()
    }

    // MARK: - Month
    public func loadMonth(reference: Date = Date()) async {
        isLoading = true
        defer { isLoading = false }
        monthRefDate = reference
        // Ensure consistent Range<Int> type for coalescing
        let range: Range<Int> = calendar.range(of: .day, in: .month, for: reference) ?? (1..<29)
        let snapshot = currentWeatherSnapshot()
        var map: [Int: [ScheduleItem]] = [:]
        for day in range {
            guard let date = calendar.date(bySetting: .day, value: day, of: reference) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            let todayWeekday = calendar.component(.weekday, from: Date())
            let items = await buildItemsForDay(weekday: weekday, optimizeForWeather: useWeatherOptimized && weekday == todayWeekday, weather: snapshot)
            let filtered = items.filter { item in
                (filterWorkerId == nil || item.workerId == filterWorkerId) &&
                (filterBuildingId == nil || item.buildingId == filterBuildingId)
            }
            map[day] = filtered.sorted { $0.startTime < $1.startTime }
        }
        monthMap = map
        lastUpdated = Date()
    }

    // MARK: - Builders
    private func buildItemsForDay(weekday: Int, optimizeForWeather: Bool, weather: WeatherSnapshot?) async -> [ScheduleItem] {
        var items: [ScheduleItem] = []
        let routesToday = container.routes.routes.filter { $0.dayOfWeek == weekday }
        if !routesToday.isEmpty {
            for route in routesToday {
                let workerId = route.workerId
                let workerName = CanonicalIDs.Workers.getName(for: workerId) ?? workerId
                let sequences: [RouteSequence]
                if optimizeForWeather, let w = weather, let optimized = container.routes.optimizeRoute(for: workerId, weather: w) {
                    sequences = optimized.sequences
                } else {
                    sequences = route.sequences
                }
                for seq in sequences {
                    items.append(ScheduleItem(
                        id: seq.id,
                        day: weekday,
                        startTime: seq.arrivalTime,
                        endTime: seq.arrivalTime.addingTimeInterval(seq.estimatedDuration),
                        buildingId: seq.buildingId,
                        buildingName: seq.buildingName,
                        workerId: workerId,
                        workerName: workerName,
                        title: seq.buildingName,
                        taskCount: max(1, seq.operations.count)
                    ))
                }
            }
            return items
        }

        // Fallback to operational weekly schedule
        let workers = (try? await container.operationalData.fetchAllWorkers()) ?? []
        for w in workers {
            if let weekly = try? await container.operationalData.getWorkerWeeklySchedule(for: w.id) {
                let entries = weekly.filter { calendar.component(.weekday, from: $0.startTime) == weekday }
                for entry in entries {
                    items.append(ScheduleItem(
                        id: UUID().uuidString,
                        day: weekday,
                        startTime: entry.startTime,
                        endTime: entry.endTime,
                        buildingId: entry.buildingId,
                        buildingName: entry.buildingName,
                        workerId: w.id,
                        workerName: w.name,
                        title: entry.title,
                        taskCount: 1
                    ))
                }
            }
        }
        return items
    }

    private func currentWeatherSnapshot() -> WeatherSnapshot? {
        WeatherSnapshot.from(current: container.weather.currentWeather, hourly: container.weather.forecast)
    }
}
