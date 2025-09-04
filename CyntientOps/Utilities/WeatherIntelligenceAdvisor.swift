import Foundation

/// Centralized helper for building-aware, weather-guided task advice
struct WeatherIntelligenceAdvisor {
    static func getWeatherAffectedTaskItems(
        tasks: [WorkerDashboardViewModel.TaskItem],
        weather: WeatherSnapshot,
        currentBuildingId: String?
    ) -> [WeatherTaskItem]? {
        let sensitive = tasks.filter { task in
            isWeatherSensitiveTask(task, buildingId: task.buildingId ?? currentBuildingId)
        }

        if sensitive.isEmpty {
            return generateWeatherBasedRecommendations(for: currentBuildingId, weather: weather)
        }

        return sensitive.prefix(3).map { task in
            let impact = determineIntelligentWeatherImpact(for: task, weather: weather, buildingId: task.buildingId ?? currentBuildingId)
            return WeatherTaskItem(id: task.id, title: task.title, affectedBy: impact.condition, recommendation: impact.recommendation)
        }
    }

    // MARK: - Private helpers (mirrors WorkerDashboardView logic)

    private static func isWeatherSensitiveTask(_ task: WorkerDashboardViewModel.TaskItem, buildingId: String?) -> Bool {
        let category = task.category.lowercased()
        let title = task.title.lowercased()

        if category.contains("maintenance") || category.contains("exterior") || category.contains("roof") || category.contains("drain") {
            return true
        }
        if title.contains("roof") || title.contains("drain") || title.contains("exterior") || title.contains("gutter") || title.contains("window") || title.contains("hvac") {
            return true
        }

        guard let buildingId = buildingId else { return false }
        switch buildingId {
        case "6": // 68 Perry - roof gutter + drain on 2nd floor
            return title.contains("gutter") || title.contains("drain") || title.contains("roof")
        case "1": // 12 W 18th - deliveries/freight considerations
            return title.contains("delivery") || title.contains("freight") || category.contains("logistics")
        case "14": // Rubin Museum - 5-story walk-up
            return title.contains("stair") || title.contains("walk") || category.contains("vertical")
        case "16": // Stuyvesant Cove Park - all outdoor
            return true
        case "19": // 115 7th Avenue - exterior only
            return true
        default:
            return false
        }
    }

    private static func generateWeatherBasedRecommendations(for buildingId: String?, weather: WeatherSnapshot) -> [WeatherTaskItem]? {
        guard let buildingId = buildingId else { return nil }

        var recs: [WeatherTaskItem] = []
        let condition = weather.current.condition.lowercased()
        let temp = weather.current.tempF
        let maxWind = weather.hourly.prefix(6).map(\.windMph).max() ?? 0

        switch buildingId {
        case "1": // 12 W 18th
            if condition.contains("rain") {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-rain-\(buildingId)",
                    title: NSLocalizedString("building.1.check_mats_title", comment: "Check lobby mats and drainage"),
                    affectedBy: "Rain",
                    recommendation: NSLocalizedString("building.1.check_mats_reco", comment: "Ensure entrance mats are secure and lobby drainage is clear")
                ))
            }
            if temp <= 32 {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-cold-\(buildingId)",
                    title: NSLocalizedString("building.1.verify_elevator_heat_title", comment: "Verify elevator heating systems"),
                    affectedBy: "Cold",
                    recommendation: NSLocalizedString("building.1.verify_elevator_heat_reco", comment: "Check both passenger and freight elevator heating")
                ))
            }
        case "3": // 135–139 W 17th — backyard drain
            if condition.contains("rain") {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-backyard-drain-\(buildingId)",
                    title: NSLocalizedString("building.3.check_backyard_drain_title", comment: "Check backyard drain before rain"),
                    affectedBy: "Rain",
                    recommendation: NSLocalizedString("building.3.check_backyard_drain_reco", comment: "Inspect and clear backyard drain prior to rainfall")
                ))
            }
        case "5": // 138 W 17th — mixed-use
            if condition.contains("rain") {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-museum-lobby-\(buildingId)",
                    title: NSLocalizedString("building.5.lobby_flow_title", comment: "Manage lobby flow during rain"),
                    affectedBy: "Rain",
                    recommendation: NSLocalizedString("building.5.lobby_flow_reco", comment: "Place mats and cones; expect higher traffic from museum/offices")
                ))
            }
        case "6": // 68 Perry
            if condition.contains("rain") {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-drain-\(buildingId)",
                    title: NSLocalizedString("building.6.inspect_roof_drain_title", comment: "Inspect 2nd floor roof drain"),
                    affectedBy: "Rain",
                    recommendation: NSLocalizedString("building.6.inspect_roof_drain_reco", comment: "Check drain via Apt 2R access during rain")
                ))
            }
        case "7": // 112 W 18th — mats
            if condition.contains("rain") {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-mats-\(buildingId)",
                    title: NSLocalizedString("building.7.check_mats_title", comment: "Check rain mats at entrance"),
                    affectedBy: "Rain",
                    recommendation: NSLocalizedString("building.7.check_mats_reco", comment: "Place mats and monitor water tracking in lobby")
                ))
            }
        case "8": // 41 Elizabeth — commercial floors
            if condition.contains("rain") {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-elizabeth-logistics-\(buildingId)",
                    title: NSLocalizedString("building.8.commercial_logistics_title", comment: "Coordinate commercial logistics in rain"),
                    affectedBy: "Rain",
                    recommendation: NSLocalizedString("building.8.commercial_logistics_reco", comment: "Use freight elevator for deliveries; add lobby mats")
                ))
            }
        case "9": // 117 W 17th — mats
            if condition.contains("rain") {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-117-mats-\(buildingId)",
                    title: NSLocalizedString("building.9.check_mats_title", comment: "Check rain mats at entrance"),
                    affectedBy: "Rain",
                    recommendation: NSLocalizedString("building.9.check_mats_reco", comment: "Place mats; expect increased water tracking")
                ))
            }
        case "10": // 131 Perry — 1 elevator
            if temp <= 32 {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-perry-elevator-cold-\(buildingId)",
                    title: NSLocalizedString("building.10.elevator_cold_title", comment: "Cold check: elevator rooms"),
                    affectedBy: "Cold",
                    recommendation: NSLocalizedString("building.10.elevator_cold_reco", comment: "Verify machine room temps and door seals")
                ))
            }
        case "11":
            break // no awning at 123; no special rain handling beyond general mats if added later
        case "13": // 136 W 17th — ground commercial
            if condition.contains("rain") {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-136-mats-\(buildingId)",
                    title: NSLocalizedString("building.13.commercial_mats_title", comment: "Ground-floor commercial mats"),
                    affectedBy: "Rain",
                    recommendation: NSLocalizedString("building.13.commercial_mats_reco", comment: "Place mats and cones at entrance during rain")
                ))
            }
        case "14": // Rubin Museum walk-ups
            break // no wind-specific actions needed
        case "16": // Stuyvesant Cove Park
            if temp >= 85 {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-heat-\(buildingId)",
                    title: NSLocalizedString("building.16.early_maintenance_title", comment: "Early morning park maintenance"),
                    affectedBy: "Heat",
                    recommendation: NSLocalizedString("building.16.early_maintenance_reco", comment: "Complete outdoor work before 10 AM to avoid heat")
                ))
            }
            let hour = Calendar.current.component(.hour, from: Date())
            let nearRain = condition.contains("rain") || weather.hourly.prefix(3).contains { $0.precipProb >= 0.3 }
            if hour < 10 && nearRain {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-park-reschedule-\(buildingId)",
                    title: NSLocalizedString("building.16.rain_reschedule_title", comment: "Reschedule park maintenance"),
                    affectedBy: "Rain",
                    recommendation: NSLocalizedString("building.16.rain_reschedule_reco", comment: "Rain in early morning—reschedule park tasks to later when clear")
                ))
            }
        case "17": // 178 Spring — no elevator
            if temp >= 85 {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-spring-heat-\(buildingId)",
                    title: NSLocalizedString("building.17.walkup_heat_title", comment: "Walk-up: plan heat breaks"),
                    affectedBy: "Heat",
                    recommendation: NSLocalizedString("building.17.walkup_heat_reco", comment: "Schedule stairwork earlier; take frequent breaks")
                ))
            }
        case "19": // 115 7th Avenue
            if condition.contains("rain") {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-exterior-\(buildingId)",
                    title: NSLocalizedString("building.19.postpone_exterior_title", comment: "Postpone exterior cleaning"),
                    affectedBy: "Rain",
                    recommendation: NSLocalizedString("building.19.postpone_exterior_reco", comment: "Wait for clear weather for sidewalk work")
                ))
            }
        case "20":
            break // no outdoor equipment to secure
        case "4": // 104 Franklin — 1 commercial
            if condition.contains("rain") {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-franklin-mats-\(buildingId)",
                    title: NSLocalizedString("building.4.commercial_threshold_mats_title", comment: "Commercial threshold mats"),
                    affectedBy: "Rain",
                    recommendation: NSLocalizedString("building.4.commercial_threshold_mats_reco", comment: "Place mats at commercial entrance; monitor slip risk")
                ))
            }
        case "21": // 148 Chambers — private elevator
            if temp <= 32 {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-chambers-elevator-cold-\(buildingId)",
                    title: NSLocalizedString("building.21.private_elevator_cold_title", comment: "Private elevator cold check"),
                    affectedBy: "Cold",
                    recommendation: NSLocalizedString("building.21.private_elevator_cold_reco", comment: "Check temperature/comfort where elevator opens into unit")
                ))
            }
        case "15": // 133 East 15th — lobby ground
            if condition.contains("rain") {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-east15-mats-\(buildingId)",
                    title: NSLocalizedString("building.15.lobby_mats_title", comment: "Lobby rain mats"),
                    affectedBy: "Rain",
                    recommendation: NSLocalizedString("building.15.lobby_mats_reco", comment: "Place mats at lobby; 4 units per floor")
                ))
            }
        default:
            if condition.contains("rain") && BuildingInfrastructureCatalog.elevatorCount(for: buildingId) == nil {
                recs.append(WeatherTaskItem(
                    id: "weather-rec-general-\(buildingId)",
                    title: NSLocalizedString("building.general.water_entry_title", comment: "Check building water entry points"),
                    affectedBy: "Rain",
                    recommendation: NSLocalizedString("building.general.water_entry_reco", comment: "Inspect doors and windows for water intrusion")
                ))
            }
        }

        // Global freezing guidance: turn off outdoor water connections
        if temp <= 32 {
            recs.append(WeatherTaskItem(
                id: "weather-rec-freeze-wateroff-\(buildingId)",
                title: NSLocalizedString("building.generic.freeze_wateroff_title", comment: "Turn off outdoor water connections"),
                affectedBy: "Cold",
                recommendation: NSLocalizedString("building.generic.freeze_wateroff_reco", comment: "Shut off and drain exterior hoses/spigots to prevent freezing")
            ))
        }
        return recs.isEmpty ? nil : Array(recs.prefix(2))
    }

    private static func determineIntelligentWeatherImpact(
        for task: WorkerDashboardViewModel.TaskItem,
        weather: WeatherSnapshot,
        buildingId: String?
    ) -> (condition: String, recommendation: String) {
        let currentTemp = weather.current.tempF
        let condition = weather.current.condition.lowercased()
        let taskTitle = task.title.lowercased()
        let maxWind = weather.hourly.prefix(6).map(\.windMph).max() ?? 0

        if let buildingId = buildingId {
            let hasElevator = (BuildingInfrastructureCatalog.elevatorCount(for: buildingId) ?? 0) > 0
            let floors = BuildingInfrastructureCatalog.floorCount(for: buildingId)
            let commercialUnits = BuildingInfrastructureCatalog.commercialUnits(for: buildingId) ?? 0

            switch buildingId {
            case "1":
                if condition.contains("rain") && taskTitle.contains("delivery") { return ("Rain", NSLocalizedString("building.1.freight_in_rain", comment: "Use freight elevator to minimize lobby water tracking")) }
                if condition.contains("rain") && taskTitle.contains("lobby") { return ("Rain", NSLocalizedString("building.1.mats_foot_traffic", comment: "Extra attention to mats - 9 floors of foot traffic")) }
            case "6":
                if condition.contains("rain") && (taskTitle.contains("roof") || taskTitle.contains("drain")) { return ("Rain", NSLocalizedString("building.6.inspect_drain_now", comment: "Perfect time to inspect drain function via Apt 2R")) }
                if condition.contains("rain") && taskTitle.contains("gutter") { return ("Rain", NSLocalizedString("building.6.observe_gutter", comment: "Observe gutter performance during active rainfall")) }
            case "14":
                if currentTemp >= 90 && taskTitle.contains("stair") { return ("Heat", NSLocalizedString("building.14.start_early_heat", comment: "Start early - 5-story walk-up will be exhausting in heat")) }
            case "16":
                if condition.contains("rain") { return ("Rain", NSLocalizedString("building.16.suspend_outdoor_rain", comment: "Suspend all outdoor park maintenance until clear")) }
                if currentTemp >= 85 { return ("Heat", NSLocalizedString("building.16.complete_before_9", comment: "Complete before 9 AM - no indoor shelter available")) }
            case "19":
                if condition.contains("rain") { return ("Rain", NSLocalizedString("building.19.exterior_wait_clear", comment: "All work exterior - wait for clear conditions")) }
                if currentTemp <= 32 && taskTitle.contains("hose") { return ("Cold", NSLocalizedString("building.19.hose_freeze_risk", comment: "Risk of freezing - use warm water for sidewalk hosing")) }
            case "21":
                if taskTitle.contains("elevator") && currentTemp <= 32 { return ("Cold", NSLocalizedString("building.21.private_elevator_cold_detail", comment: "Check elevator that opens into unit - resident comfort critical")) }
            default:
                break
            }

            if !hasElevator, let floors = floors, floors > 3, currentTemp >= 85 {
                return ("Heat", NSLocalizedString("building.generic.walkup_heat_breaks", comment: "Multi-story walk-up - plan frequent breaks"))
            }
            if commercialUnits > 0 && condition.contains("rain") {
                return ("Rain", NSLocalizedString("building.generic.commercial_rain_attention", comment: "Extra attention to commercial entrances - higher foot traffic"))
            }
        }

        if condition.contains("rain") || condition.contains("storm") {
            if taskTitle.contains("roof") || taskTitle.contains("drain") { return ("Rain", NSLocalizedString("weather.advice.optimal_drain_inspection", comment: "Optimal time for drain inspection")) }
            if taskTitle.contains("exterior") { return ("Rain", NSLocalizedString("weather.advice.postpone_exterior", comment: "Postpone until weather clears")) }
            return ("Rain", NSLocalizedString("weather.advice.move_indoors", comment: "Move indoors if possible"))
        }

        if currentTemp >= 90 { return ("Heat", NSLocalizedString("weather.advice.heat_complete_early", comment: "Complete early morning to avoid heat")) }
        if currentTemp <= 32 { return ("Cold", NSLocalizedString("weather.advice.cold_dress_warm", comment: "Dress warmly and take frequent breaks")) }

        // No wind-specific actions required

        return ("Weather", NSLocalizedString("weather.advice.monitor", comment: "Monitor conditions throughout task"))
    }
}
