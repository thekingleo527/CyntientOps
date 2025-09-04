import Foundation

/// Engine to generate weather-based actionable suggestions for a worker at a building
struct WeatherSuggestionEngine {
    static func suggestions(
        forWorker workerId: String?,
        at building: WorkerDashboardViewModel.BuildingSummary,
        forecast: WeatherSnapshot,
        today: Date = Date()
    ) -> [WeatherSuggestion] {
        var out: [WeatherSuggestion] = []

        let buildingId = building.id
        let policies = BuildingOperationsCatalog.map[buildingId]

        // A. Precipitation (next 6 hours)
        let next6 = Array(forecast.hourly.prefix(6))
        if let maxPrecip = next6.map({ $0.precipProb }).max(), maxPrecip >= 0.5 {
            if let start = next6.first(where: { $0.precipProb >= 0.5 })?.date,
               let end = next6.last(where: { $0.precipProb >= 0.5 })?.date {
                let window = timeWindowString(start: start, end: end)

                if let seasonal = policies?.seasonal {
                    // Clear curbs before rain (if leaf blower policy exists)
                    out.append(
                        WeatherSuggestion(
                            id: "curb-pre-rain-\(buildingId)-\(Int(start.timeIntervalSince1970))",
                            kind: .rain,
                            title: "Rain expected \(window)",
                            subtitle: "Blow leaves & clear \(seasonal.curbClearInches)″ curbs at \(shortName(building.name)) before rain",
                            taskTemplateId: "curbClearPreRain",
                            dueBy: Calendar.current.date(byAdding: .minute, value: -30, to: start),
                            buildingId: buildingId
                        )
                    )
                }

                if policies?.roofDrains?.checkBeforeRain == true {
                    out.append(
                        WeatherSuggestion(
                            id: "roof-drain-pre-rain-\(buildingId)-\(Int(start.timeIntervalSince1970))",
                            kind: .rain,
                            title: "Check roof drains before rain",
                            subtitle: "Walk-through & remove debris at \(shortName(building.name))",
                            taskTemplateId: "roofDrainCheck",
                            dueBy: Calendar.current.date(byAdding: .minute, value: -60, to: start),
                            buildingId: buildingId
                        )
                    )
                }
            }
        }

        // B. Temperature (hot day)
        let maxTempNext12 = forecast.hourly.prefix(12).map({ $0.tempF }).max() ?? forecast.current.tempF
        if maxTempNext12 >= 85 {
            out.append(
                WeatherSuggestion(
                    id: "hot-day-\(buildingId)-\(Int(maxTempNext12))",
                    kind: .heat,
                    title: "Hot today (\(Int(maxTempNext12))°)",
                    subtitle: "Hose & squeegee sidewalks at \(shortName(building.name))",
                    taskTemplateId: "hoseSidewalks",
                    dueBy: nil,
                    buildingId: buildingId
                )
            )
        }

        // C. DSNY set-out (day-of)
        let weekday = Calendar.current.component(.weekday, from: today)
        let todayDay = CollectionDay.from(weekday: weekday)
        let setOuts = DSNYCollectionSchedule.getBinSetOutReminders(for: todayDay)
        if let reminder = setOuts.first(where: { $0.buildingId == buildingId }) {
            let timeString = reminder.scheduledTime.timeString
            out.append(
                WeatherSuggestion(
                    id: "dsny-setout-\(buildingId)-\(todayDay.rawValue)",
                    kind: .dsny,
                    title: "DSNY set-out tonight",
                    subtitle: "Set out bins at \(timeString) @ \(shortName(building.name))",
                    taskTemplateId: "dsnySetout",
                    dueBy: dateFromDSNYTime(reminder.scheduledTime, offsetMinutes: -10, on: today),
                    buildingId: buildingId
                )
            )
        }

        // D. Snow (winter policy proxy)
        let snowLikelyNext24 = forecast.hourly.prefix(12).contains { hb in
            hb.precipProb >= 0.5 && forecast.current.condition.lowercased().contains("snow")
        }
        if snowLikelyNext24 {
            out.append(
                WeatherSuggestion(
                    id: "snow-entrances-\(buildingId)",
                    kind: .snow,
                    title: "Snow expected",
                    subtitle: "Salt entrances within 4h after snow",
                    taskTemplateId: "saltEntrances",
                    dueBy: nil,
                    buildingId: buildingId
                )
            )
        }

        // Return top 3
        return Array(out.prefix(3))
    }

    // MARK: - Helpers

    private static func timeWindowString(start: Date, end: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .none
        fmt.timeStyle = .short
        return "\(fmt.string(from: start))–\(fmt.string(from: end))"
    }

    private static func dateFromDSNYTime(_ time: DSNYTime, offsetMinutes: Int, on date: Date) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = time.hour
        components.minute = time.minute
        let base = Calendar.current.date(from: components)
        return Calendar.current.date(byAdding: .minute, value: offsetMinutes, to: base ?? date)
    }

    private static func shortName(_ name: String) -> String {
        // Use a compact short name (e.g., last 2 words of address)
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return parts.suffix(2).joined(separator: " ")
        }
        return name
    }
}
