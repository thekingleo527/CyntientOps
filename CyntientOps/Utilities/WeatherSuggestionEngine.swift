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

        // A. Precipitation (next 24 hours - lowered threshold and extended window)
        let next24 = Array(forecast.hourly.prefix(24))
        let maxPrecip = next24.map({ $0.precipProb }).max() ?? 0
        let totalRainInches = next24.reduce(into: 0.0) { result, hour in
            result += (hour.precipIntensity ?? 0)
        }
        
        // Rain/precipitation suggestions with lower thresholds
        if maxPrecip >= 0.25 || totalRainInches >= 0.1 {
            // Skip hosing if rain is likely
            out.append(
                WeatherSuggestion(
                    id: "skip-hosing-\(buildingId)-\(Int(today.timeIntervalSince1970))",
                    kind: .rain,
                    title: "Skip sidewalk hosing",
                    subtitle: "Rain expected — use spot clean; prevent pooling & slippery walkways",
                    taskTemplateId: "skipHosing",
                    dueBy: nil,
                    buildingId: buildingId
                )
            )
        }
        
        if maxPrecip >= 0.4 || totalRainInches >= 0.25 {
            // Clear roof and yard drains
            out.append(
                WeatherSuggestion(
                    id: "clear-drains-\(buildingId)-\(Int(today.timeIntervalSince1970))",
                    kind: .rain,
                    title: "Clear roof & curb drains",
                    subtitle: "Check scuppers & drains before precipitation at \(shortName(building.name))",
                    taskTemplateId: "roofDrainCheck",
                    dueBy: nil,
                    buildingId: buildingId
                )
            )
        }
        
        // Rain mats for buildings with entrances
        if maxPrecip >= 0.3 {
            out.append(
                WeatherSuggestion(
                    id: "rain-mats-\(buildingId)-\(Int(today.timeIntervalSince1970))",
                    kind: .rain,
                    title: "Deploy / clean rain mats",
                    subtitle: "Reduce slip risk at lobby entrance",
                    taskTemplateId: "rainMats",
                    dueBy: nil,
                    buildingId: buildingId
                )
            )
        }

        // B. Temperature (hot day) - lowered threshold
        let maxTempNext12 = forecast.hourly.prefix(12).map({ $0.tempF }).max() ?? forecast.current.tempF
        if maxTempNext12 >= 78 && maxPrecip < 0.3 { // Only if not raining
            out.append(
                WeatherSuggestion(
                    id: "hot-day-\(buildingId)-\(Int(maxTempNext12))",
                    kind: .heat,
                    title: "Warm today (\(Int(maxTempNext12))°)",
                    subtitle: "Hose & squeegee sidewalks at \(shortName(building.name))",
                    taskTemplateId: "hoseSidewalks",
                    dueBy: nil,
                    buildingId: buildingId
                )
            )
        }
        
        // C. Wind conditions
        let maxWindNext12 = forecast.hourly.prefix(12).map({ $0.windMph }).max() ?? 0
        if maxWindNext12 >= 15 {
            out.append(
                WeatherSuggestion(
                    id: "wind-secure-\(buildingId)-\(Int(maxWindNext12))",
                    kind: .wind,
                    title: "Windy conditions (\(Int(maxWindNext12)) mph)",
                    subtitle: "Secure trash lids & tie bags to prevent litter",
                    taskTemplateId: "secureTrash",
                    dueBy: nil,
                    buildingId: buildingId
                )
            )
        }

        // D. DSNY set-out (only show on actual collection days)
        let weekday = Calendar.current.component(.weekday, from: today)
        let todayDay = CollectionDay.from(weekday: weekday)
        
        // Check if today is actually a collection day for this building
        // Sunday = 1, Monday = 2, Tuesday = 3, Wednesday = 4, Thursday = 5, Friday = 6, Saturday = 7
        let isDSNYDay = (weekday == 1 || weekday == 3 || weekday == 5) // Sunday, Tuesday, Thursday
        
        if isDSNYDay {
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
        }

        // E. Snow (winter policy proxy)
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
        
        // F. General maintenance suggestions if no weather conditions
        if out.isEmpty {
            // Add a general suggestion to ensure there's always something
            out.append(
                WeatherSuggestion(
                    id: "general-maintenance-\(buildingId)",
                    kind: .generic,
                    title: "Perfect weather for outdoor tasks",
                    subtitle: "Complete exterior maintenance at \(shortName(building.name))",
                    taskTemplateId: "exteriorMaintenance",
                    dueBy: nil,
                    buildingId: buildingId
                )
            )
        }

        // Priority sorting: DSNY (highest), rain/wind (urgent weather), temperature (routine)
        let prioritySorted = out.sorted { first, second in
            switch (first.kind, second.kind) {
            case (.dsny, _): return true
            case (_, .dsny): return false
            case (.rain, .heat), (.rain, .generic), (.wind, .heat), (.wind, .generic): return true
            case (.heat, .rain), (.generic, .rain), (.heat, .wind), (.generic, .wind): return false
            default: return first.title < second.title
            }
        }
        
        // Return top 3
        return Array(prioritySorted.prefix(3))
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
