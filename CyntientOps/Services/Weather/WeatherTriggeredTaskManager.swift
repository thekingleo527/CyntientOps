//
//  WeatherTriggeredTaskManager.swift
//  CyntientOps
//
//  Manages weather-triggered operational tasks like roof drain checks
//  Monitors weather conditions and automatically schedules urgent tasks
//

import Foundation
import Combine

// MARK: - Weather-Triggered Task Management

@MainActor
public final class WeatherTriggeredTaskManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var activeTriggers: [WeatherTrigger] = []
    @Published public private(set) var pendingTasks: [TriggeredTask] = []
    @Published public private(set) var completedTasks: [TriggeredTask] = []
    
    // MARK: - Dependencies
    
    private let weatherAdapter: WeatherDataAdapter
    private let routeManager: RouteManager
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var weatherMonitoringTimer: Timer?
    private var wasSnowingRecently: Bool = false
    private var lastLeafTasksDate: Date? = nil
    
    // MARK: - Weather Trigger Definitions
    
    public struct WeatherTrigger: Identifiable, Codable {
        public let id: UUID
        public let condition: WeatherCondition
        public let threshold: Double
        public let timeFrame: TimeFrame
        public let priority: Priority
        public let triggeredTasks: [TaskTemplate]
        
        public enum WeatherCondition: String, Codable, CaseIterable {
            case rainExpected = "Rain Expected"
            case rainEnded = "Rain Ended"
            case heavyWindWarning = "Heavy Wind Warning"
            case windEnded = "Wind Ended"
            case freezeWarning = "Freeze Warning"
            case heatWave = "Heat Wave"
            case stormWarning = "Storm Warning"
            case immediate = "Immediate" // Non-weather seasonal/manual trigger
        }
        
        public enum TimeFrame: String, Codable, CaseIterable {
            case next6Hours = "Next 6 Hours"
            case next12Hours = "Next 12 Hours"
            case next24Hours = "Next 24 Hours"
            case immediate = "Immediate"
            case afterCondition = "After Condition Ends"
        }
        
        public enum Priority: String, Codable, CaseIterable {
            case critical = "Critical"
            case high = "High"
            case medium = "Medium"
            case low = "Low"
        }
        
        public init(id: UUID = UUID(), condition: WeatherCondition, threshold: Double, timeFrame: TimeFrame, 
                    priority: Priority, triggeredTasks: [TaskTemplate]) {
            self.id = id
            self.condition = condition
            self.threshold = threshold
            self.timeFrame = timeFrame
            self.priority = priority
            self.triggeredTasks = triggeredTasks
        }
    }
    
    public struct TaskTemplate: Identifiable, Codable {
        public let id: UUID
        public let name: String
        public let assignedWorkerId: String
        public let buildingIds: [String]
        public let category: OperationTask.TaskCategory
        public let location: OperationTask.TaskLocation
        public let estimatedDuration: TimeInterval
        public let instructions: String
        public let requiredEquipment: [String]
        public let mustCompleteWithin: TimeInterval // seconds from trigger
        
        public init(id: UUID = UUID(), name: String, assignedWorkerId: String, buildingIds: [String],
                    category: OperationTask.TaskCategory, location: OperationTask.TaskLocation,
                    estimatedDuration: TimeInterval, instructions: String, 
                    requiredEquipment: [String] = [], mustCompleteWithin: TimeInterval) {
            self.id = id
            self.name = name
            self.assignedWorkerId = assignedWorkerId
            self.buildingIds = buildingIds
            self.category = category
            self.location = location
            self.estimatedDuration = estimatedDuration
            self.instructions = instructions
            self.requiredEquipment = requiredEquipment
            self.mustCompleteWithin = mustCompleteWithin
        }
    }
    
    public struct TriggeredTask: Identifiable, Codable {
        public let id: UUID
        public let template: TaskTemplate
        public let triggeredBy: WeatherTrigger.WeatherCondition
        public let triggeredAt: Date
        public let mustCompleteBy: Date
        public let status: TaskStatus
        public let completedAt: Date?
        public let notes: String?
        
        public enum TaskStatus: String, Codable, CaseIterable {
            case pending = "Pending"
            case assigned = "Assigned"
            case inProgress = "In Progress"
            case completed = "Completed"
            case overdue = "Overdue"
            case cancelled = "Cancelled"
        }
        
        public init(id: UUID = UUID(), template: TaskTemplate, triggeredBy: WeatherTrigger.WeatherCondition,
                    triggeredAt: Date, status: TaskStatus = .pending, 
                    completedAt: Date? = nil, notes: String? = nil) {
            self.id = id
            self.template = template
            self.triggeredBy = triggeredBy
            self.triggeredAt = triggeredAt
            self.mustCompleteBy = triggeredAt.addingTimeInterval(template.mustCompleteWithin)
            self.status = status
            self.completedAt = completedAt
            self.notes = notes
        }
        
        public var isOverdue: Bool {
            status != .completed && Date() > mustCompleteBy
        }
        
        public var urgencyLevel: String {
            let timeRemaining = mustCompleteBy.timeIntervalSinceNow
            if timeRemaining <= 0 { return "OVERDUE" }
            if timeRemaining <= 3600 { return "URGENT" } // 1 hour
            if timeRemaining <= 7200 { return "HIGH" } // 2 hours
            return "NORMAL"
        }
    }
    
    // MARK: - Initialization
    
    public init(weatherAdapter: WeatherDataAdapter, routeManager: RouteManager) {
        self.weatherAdapter = weatherAdapter
        self.routeManager = routeManager
        setupWeatherMonitoring()
        setupTriggerDefinitions()
    }
    
    // MARK: - Weather Monitoring Setup
    
    private func setupWeatherMonitoring() {
        // Monitor current weather and forecast for trigger conditions
        Publishers.CombineLatest(
            weatherAdapter.$currentWeather,
            weatherAdapter.$forecast
        )
        .compactMap { current, forecast -> (CoreTypes.WeatherData, [CoreTypes.WeatherData])? in
            guard let current = current else { return nil }
            return (current, forecast)
        }
        .sink { [weak self] value in
            let (current, forecast) = value
            self?.evaluateWeatherTriggers(current: current, forecast: forecast)
            self?.createSeasonalLeafTasksIfNeeded(at: Date())
        }
        .store(in: &cancellables)
        
        // Set up periodic monitoring timer
        weatherMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            // Check every 10 minutes
            Task { [weak self] in
                await self?.evaluateActiveTriggers()
            }
        }
        
        print("✅ WeatherTriggeredTaskManager: Weather monitoring active")
    }
    
    // MARK: - Trigger Definitions
    
    private func setupTriggerDefinitions() {
        // Build triggers asynchronously to avoid async-in-sync closure issues
        Task { [weak self] in
            guard let self else { return }
            
            // Filter roof-drain buildings per worker by feature config (pilot/production only)
            let roofDrainByWorkerRaw = self.roofDrainBuildingsPerWorker()
            var roofDrainByWorkerFiltered: [String: [String]] = [:]
            for (workerId, ids) in roofDrainByWorkerRaw {
                var kept: [String] = []
                for id in ids {
                    let conf = await BuildingConfigurationManager.shared.getConfiguration(for: id)
                    if conf != .standard {
                        kept.append(id)
                    }
                }
                roofDrainByWorkerFiltered[workerId] = kept
            }
            
            // Filter rain-mat buildings by feature config (pilot/production only)
            let rainMatRaw = self.rainMatBuildingIds()
            var rainMatBuildingsFiltered: [String] = []
            for id in rainMatRaw {
                let conf = await BuildingConfigurationManager.shared.getConfiguration(for: id)
                if conf != .standard {
                    rainMatBuildingsFiltered.append(id)
                }
            }
            
            // Build templates synchronously from filtered sets
            let roofDrainBeforeRain: [TaskTemplate] = roofDrainByWorkerFiltered.flatMap { (workerId, buildingIds) in
                buildingIds.map { bid in
                    TaskTemplate(
                        name: "Emergency Roof Drain Inspection - Before Rain",
                        assignedWorkerId: workerId,
                        buildingIds: [bid],
                        category: .maintenance,
                        location: .exterior,
                        estimatedDuration: 60 * 60,
                        instructions: "URGENT: Inspect and clear roof drains before expected heavy rain.",
                        requiredEquipment: ["Ladder", "Safety equipment", "Drain snake", "Flashlight"],
                        mustCompleteWithin: 4 * 3600
                    )
                }
            }

            let roofDrainAfterRain: [TaskTemplate] = roofDrainByWorkerFiltered.flatMap { (workerId, buildingIds) in
                buildingIds.map { bid in
                    TaskTemplate(
                        name: "Post-Rain Roof Drain Assessment",
                        assignedWorkerId: workerId,
                        buildingIds: [bid],
                        category: .buildingInspection,
                        location: .exterior,
                        estimatedDuration: 45 * 60,
                        instructions: "Inspect roof drains for proper drainage and any backup issues.",
                        requiredEquipment: ["Ladder", "Camera", "Safety equipment"],
                        mustCompleteWithin: 6 * 3600
                    )
                }
            }

            let rainMatPutOut: [TaskTemplate] = rainMatBuildingsFiltered.map { bid in
                TaskTemplate(
                    name: "Put Out Rain Mats (Pre-Rain)",
                    assignedWorkerId: assignMatWorker(for: bid),
                    buildingIds: [bid],
                    category: .maintenance,
                    location: .entrance,
                    estimatedDuration: 20 * 60,
                    instructions: "Place rain mats at entrances prior to rain.",
                    requiredEquipment: ["Rain mats"],
                    mustCompleteWithin: 6 * 3600
                )
            }

            let rainMatRemove: [TaskTemplate] = rainMatBuildingsFiltered.map { bid in
                TaskTemplate(
                    name: "Remove Rain Mats (Post-Rain)",
                    assignedWorkerId: assignMatWorker(for: bid),
                    buildingIds: [bid],
                    category: .maintenance,
                    location: .entrance,
                    estimatedDuration: 20 * 60,
                    instructions: "Remove and store rain mats once surfaces are dry.",
                    requiredEquipment: ["Rain mats"],
                    mustCompleteWithin: 6 * 3600
                )
            }

            // Salt sidewalks pre-snow (approximate: freeze warning is our proxy)
            let saltSidewalks = TaskTemplate(
                name: "Pre-Salt Sidewalks",
                assignedWorkerId: CanonicalIDs.Workers.kevinDutan,
                buildingIds: getAllBuildingIds(),
                category: .maintenance,
                location: .sidewalk,
                estimatedDuration: 45 * 60,
                instructions: "Apply salt to sidewalks prior to snowfall to prevent icing.",
                requiredEquipment: ["Salt", "Spreader"],
                mustCompleteWithin: 6 * 3600
            )
            
            // Assign active triggers on main actor
            await MainActor.run {
                self.activeTriggers = [
                    // Roof drains + rain mats before rain
                    WeatherTrigger(
                        condition: .rainExpected,
                        threshold: 0.6, // 60% chance or higher
                        timeFrame: .next12Hours,
                        priority: .high,
                        triggeredTasks: roofDrainBeforeRain + rainMatPutOut
                    ),
                    
                    // Roof drain checks + remove mats after rain
                    WeatherTrigger(
                        condition: .rainEnded,
                        threshold: 0.5, // After significant rain (>0.5 inches)
                        timeFrame: .afterCondition,
                        priority: .high,
                        triggeredTasks: roofDrainAfterRain + rainMatRemove
                    ),
                    
                    // High wind preparations
                    WeatherTrigger(
                        condition: .heavyWindWarning,
                        threshold: 35.0, // 35+ mph winds
                        timeFrame: .next6Hours,
                        priority: .critical,
                        triggeredTasks: [
                            TaskTemplate(
                                name: "High Wind Preparation - Secure Loose Items",
                                assignedWorkerId: CanonicalIDs.Workers.kevinDutan,
                                buildingIds: getAllBuildingIds(),
                                category: .maintenance,
                                location: .exterior,
                                estimatedDuration: 60 * 60, // 1 hour
                                instructions: "CRITICAL: Secure all loose items, trash bins, signage, and outdoor furniture. Check building exteriors for loose elements.",
                                requiredEquipment: ["Tie-down straps", "Storage areas access"],
                                mustCompleteWithin: 2 * 3600 // 2 hours to complete
                            )
                        ]
                    ),
                    
                    // Post-wind damage assessment
                    WeatherTrigger(
                        condition: .windEnded,
                        threshold: 30.0, // After winds above 30 mph
                        timeFrame: .afterCondition,
                        priority: .high,
                        triggeredTasks: [
                            TaskTemplate(
                                name: "Post-Wind Damage Assessment",
                                assignedWorkerId: CanonicalIDs.Workers.edwinLema,
                                buildingIds: getAllBuildingIds(),
                                category: .buildingInspection,
                                location: .exterior,
                                estimatedDuration: 120 * 60, // 2 hours
                                instructions: "Comprehensive inspection for wind damage: loose siding, damaged signage, clogged drains from debris, broken windows.",
                                requiredEquipment: ["Camera", "Ladder", "Safety equipment", "Temporary repair materials"],
                                mustCompleteWithin: 4 * 3600 // 4 hours after wind subsides
                            )
                        ]
                    ),
                    
                    // Freeze warning preparations (pre-salt sidewalks + freeze protection)
                    WeatherTrigger(
                        condition: .freezeWarning,
                        threshold: 32.0, // Below 32°F
                        timeFrame: .next12Hours,
                        priority: .high,
                        triggeredTasks: [saltSidewalks,
                            TaskTemplate(
                                name: "Freeze Protection - Pipe & System Check",
                                assignedWorkerId: CanonicalIDs.Workers.edwinLema,
                                buildingIds: getBuildingsWithExposedPlumbing(),
                                category: .maintenance,
                                location: .basement,
                                estimatedDuration: 90 * 60, // 1.5 hours
                                instructions: "Check exposed pipes, ensure heat is adequate in vulnerable areas, verify freeze protection systems are active.",
                                requiredEquipment: ["Thermometer", "Pipe insulation", "Space heaters if needed"],
                                mustCompleteWithin: 6 * 3600 // 6 hours before freeze
                            )
                        ]
                    )
                ]
                
                print("✅ WeatherTriggeredTaskManager: Loaded \(self.activeTriggers.count) weather trigger definitions")
            }
        }
    }

    // MARK: - Advisory Broadcast
    private func postAdvisory(_ title: String, body: String, buildingIds: [String]) {
        NotificationCenter.default.post(
            name: Notification.Name("WeatherAdvisory"),
            object: nil,
            userInfo: [
                "title": title,
                "body": body,
                "buildingIds": buildingIds.joined(separator: ",")
            ]
        )
    }
    
    // MARK: - Weather Evaluation
    
    private func evaluateWeatherTriggers(current: CoreTypes.WeatherData, forecast: [CoreTypes.WeatherData]) {
        let now = Date()

        // Snow-ended detection (simple state transition)
        let isSnowingNow = (current.condition == .snow || current.condition == .snowy)
        if wasSnowingRecently && !isSnowingNow {
            // Create shovel tasks per building (due within 4 hours)
            let shovel = shovelTasksPerBuilding()
            let trigger = WeatherTrigger(
                condition: .freezeWarning, // reuse type bucket
                threshold: 0.0,
                timeFrame: .afterCondition,
                priority: .high,
                triggeredTasks: shovel
            )
            createTriggeredTasks(from: trigger, at: now)
        }
        wasSnowingRecently = isSnowingNow

        for trigger in activeTriggers {
            let shouldTrigger = evaluateTriggerCondition(trigger, current: current, forecast: forecast, at: now)
            
            if shouldTrigger && !hasRecentTrigger(for: trigger.condition, within: 6 * 3600) {
                createTriggeredTasks(from: trigger, at: now)
                print("🌦️ Weather trigger activated: \(trigger.condition.rawValue)")
            }
        }
    }

    private func shovelTasksPerBuilding() -> [TaskTemplate] {
        let all = getAllBuildingIds()
        return all.map { bid in
            TaskTemplate(
                name: "Shovel Sidewalks",
                assignedWorkerId: assignSidewalkWorker(for: bid),
                buildingIds: [bid],
                category: .maintenance,
                location: .sidewalk,
                estimatedDuration: 60 * 60,
                instructions: "Shovel sidewalks and clear path; comply within 4 hours after snow.",
                requiredEquipment: ["Shovel", "Ice Melt"],
                mustCompleteWithin: 4 * 3600
            )
        }
    }

    private func assignSidewalkWorker(for buildingId: String) -> String {
        let candidates = [
            CanonicalIDs.Workers.kevinDutan,
            CanonicalIDs.Workers.edwinLema,
            CanonicalIDs.Workers.mercedesInamagua
        ]
        for wid in candidates {
            if let route = routeManager.getCurrentRoute(for: wid) {
                if route.sequences.contains(where: { $0.buildingId == buildingId }) { return wid }
            }
        }
        return CanonicalIDs.Workers.kevinDutan
    }

    private func createSeasonalLeafTasksIfNeeded(at now: Date) {
        let m = Calendar.current.component(.month, from: now)
        guard [9,10,11].contains(m) else { return }
        if let last = lastLeafTasksDate, Calendar.current.isDate(last, inSameDayAs: now) { return }

        let templates: [TaskTemplate] = getAllBuildingIds().map { bid in
            TaskTemplate(
                name: "Leaf Blow & Clear Curbs (18in)",
                assignedWorkerId: assignSidewalkWorker(for: bid),
                buildingIds: [bid],
                category: .sweeping,
                location: .curbside,
                estimatedDuration: 45 * 60,
                instructions: "Blow leaves and clear curbs up to 18 inches.",
                requiredEquipment: ["Leaf Blower", "Broom", "Bags"],
                mustCompleteWithin: 6 * 3600
            )
        }
        let trigger = WeatherTrigger(
            condition: .immediate,
            threshold: 0,
            timeFrame: .immediate,
            priority: .medium,
            triggeredTasks: templates
        )
        createTriggeredTasks(from: trigger, at: now)
        lastLeafTasksDate = now
    }
    
    private func evaluateTriggerCondition(_ trigger: WeatherTrigger, 
                                          current: CoreTypes.WeatherData, 
                                          forecast: [CoreTypes.WeatherData], 
                                          at time: Date) -> Bool {
        switch trigger.condition {
        case .immediate:
            return true
        case .rainExpected:
            // Check if significant rain is expected in the specified timeframe
            let timeWindow = getTimeWindow(for: trigger.timeFrame, from: time)
            let forecastInWindow = forecast.filter { timeWindow.contains($0.timestamp) }
            let maxRainProbability = forecastInWindow.map { precipitationProbability(for: $0.condition) }.max() ?? 0
            return maxRainProbability >= trigger.threshold
            
        case .rainEnded:
            // Check if rain just ended and was significant
            let wasRaining = precipitationProbability(for: current.condition) > 0.5
            let isNoLongerRaining = precipitationProbability(for: current.condition) < 0.2
            return wasRaining && isNoLongerRaining
            
        case .heavyWindWarning:
            // Check if high winds are expected
            return current.windSpeed >= trigger.threshold || 
                   forecast.prefix(6).contains { $0.windSpeed >= trigger.threshold }
                   
        case .windEnded:
            // Check if high winds just subsided
            let recentHighWinds = forecast.prefix(2).contains { $0.windSpeed >= trigger.threshold }
            let currentWindsLow = current.windSpeed < (trigger.threshold * 0.7)
            return recentHighWinds && currentWindsLow
            
        case .freezeWarning:
            // Check if freezing temperatures are expected
            return current.temperature <= trigger.threshold || 
                   forecast.prefix(12).contains { $0.temperature <= trigger.threshold }
                   
        case .heatWave:
            // Check for extreme heat conditions
            return current.temperature >= trigger.threshold
            
        case .stormWarning:
            // Check for storm conditions (combination of factors)
            return current.windSpeed >= 40.0 && precipitationProbability(for: current.condition) >= 0.8
        }
    }
    
    private func precipitationProbability(for condition: CoreTypes.WeatherCondition) -> Double {
        switch condition {
        case .sunny, .clear: return 0.0
        case .cloudy: return 0.1
        case .overcast: return 0.2
        case .rain: return 0.8
        case .storm: return 0.9
        case .snow, .snowy: return 0.85
        case .fog, .foggy: return 0.3
        case .windy: return 0.1
        case .hot, .cold: return 0.0
        }
    }
    
    private func getTimeWindow(for timeFrame: WeatherTrigger.TimeFrame, from start: Date) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let endTime: Date
        
        switch timeFrame {
        case .next6Hours:
            endTime = calendar.date(byAdding: .hour, value: 6, to: start)!
        case .next12Hours:
            endTime = calendar.date(byAdding: .hour, value: 12, to: start)!
        case .next24Hours:
            endTime = calendar.date(byAdding: .hour, value: 24, to: start)!
        case .immediate:
            endTime = calendar.date(byAdding: .hour, value: 1, to: start)!
        case .afterCondition:
            endTime = calendar.date(byAdding: .hour, value: 6, to: start)!
        }
        
        return start...endTime
    }
    
    private func hasRecentTrigger(for condition: WeatherTrigger.WeatherCondition, within timeInterval: TimeInterval) -> Bool {
        let cutoffTime = Date().addingTimeInterval(-timeInterval)
        return pendingTasks.contains { task in
            task.triggeredBy == condition && task.triggeredAt > cutoffTime
        } || completedTasks.contains { task in
            task.triggeredBy == condition && task.triggeredAt > cutoffTime
        }
    }
    
    // MARK: - Task Creation
    
    private func createTriggeredTasks(from trigger: WeatherTrigger, at time: Date) {
        for template in trigger.triggeredTasks {
            let triggeredTask = TriggeredTask(
                template: template,
                triggeredBy: trigger.condition,
                triggeredAt: time
            )
            
            pendingTasks.append(triggeredTask)
        }
        
        // Notify the system about new urgent tasks
        notifyUrgentTaskCreated(trigger.priority)
    }
    
    private func notifyUrgentTaskCreated(_ priority: WeatherTrigger.Priority) {
        print("🚨 Weather-triggered \(priority.rawValue) priority tasks created")
        let title = "Weather Advisory"
        let body = "New \(priority.rawValue) weather-triggered tasks created"
        let bids = pendingTasks.flatMap { $0.template.buildingIds }
        postAdvisory(title, body: body, buildingIds: bids)
    }
    
    // MARK: - Task Management
    
    public func completeTask(_ taskId: UUID, notes: String? = nil) {
        guard let index = pendingTasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        var completedTask = pendingTasks[index]
        completedTask = TriggeredTask(
            template: completedTask.template,
            triggeredBy: completedTask.triggeredBy,
            triggeredAt: completedTask.triggeredAt,
            status: .completed,
            completedAt: Date(),
            notes: notes
        )
        
        pendingTasks.remove(at: index)
        completedTasks.append(completedTask)
        
        print("✅ Weather-triggered task completed: \(completedTask.template.name)")
    }
    
    public func getOverdueTasks() -> [TriggeredTask] {
        return pendingTasks.filter { $0.isOverdue }
    }
    
    public func getUrgentTasks() -> [TriggeredTask] {
        return pendingTasks.filter { $0.urgencyLevel == "URGENT" || $0.urgencyLevel == "OVERDUE" }
    }
    
    // MARK: - Helper Methods
    
    private func getAllBuildingIds() -> [String] {
        return [
            CanonicalIDs.Buildings.westEighteenth12,
            CanonicalIDs.Buildings.westSeventeenth135_139,
            CanonicalIDs.Buildings.franklin104,
            CanonicalIDs.Buildings.westSeventeenth138,
            CanonicalIDs.Buildings.perry68,
            CanonicalIDs.Buildings.westEighteenth112,
            CanonicalIDs.Buildings.elizabeth41,
            CanonicalIDs.Buildings.westSeventeenth117,
            CanonicalIDs.Buildings.perry131,
            CanonicalIDs.Buildings.firstAvenue123,
            CanonicalIDs.Buildings.westSeventeenth136,
            CanonicalIDs.Buildings.rubinMuseum,
            CanonicalIDs.Buildings.eastFifteenth133,
            CanonicalIDs.Buildings.stuyvesantCove,
            CanonicalIDs.Buildings.springStreet178,
            CanonicalIDs.Buildings.walker36,
            CanonicalIDs.Buildings.seventhAvenue115,
            CanonicalIDs.Buildings.cyntientOpsHQ,
            CanonicalIDs.Buildings.chambers148
        ]
    }

    // MARK: - Local building policy helpers (inline to avoid external deps)

    /// Buildings that require roof drain checks, grouped by the responsible worker
    private func roofDrainBuildingsPerWorker() -> [String: [String]] {
        let edwin = CanonicalIDs.Workers.edwinLema
        let greg  = CanonicalIDs.Workers.gregHutson
        return [
            edwin: [
                CanonicalIDs.Buildings.westSeventeenth135_139,
                CanonicalIDs.Buildings.westSeventeenth138,
                CanonicalIDs.Buildings.westEighteenth112,
                CanonicalIDs.Buildings.westSeventeenth117
            ],
            greg: [
                CanonicalIDs.Buildings.westEighteenth12
            ]
        ]
    }

    /// Buildings with rain mats (12 W 18th, 112 W 18th, 117 W 17th)
    private func rainMatBuildingIds() -> [String] {
        return [
            CanonicalIDs.Buildings.westEighteenth12,
            CanonicalIDs.Buildings.westEighteenth112,
            CanonicalIDs.Buildings.westSeventeenth117
        ]
    }

    /// Intelligent assignment for rain mats on 17th St cluster: prefer Edwin; else Kevin, then Mercedes.
    /// Greg is solely responsible for 12 W 18th.
    private func assignMatWorker(for buildingId: String) -> String {
        let greg = CanonicalIDs.Workers.gregHutson
        if buildingId == CanonicalIDs.Buildings.westEighteenth12 { return greg }

        let candidates = [
            CanonicalIDs.Workers.edwinLema,
            CanonicalIDs.Workers.kevinDutan,
            CanonicalIDs.Workers.mercedesInamagua
        ]

        // Try to pick the worker who is currently routed to this building today
        for wid in candidates {
            if let route = routeManager.getCurrentRoute(for: wid) {
                if route.sequences.contains(where: { $0.buildingId == buildingId }) {
                    return wid
                }
            }
        }

        // Fallback to Edwin by default
        return CanonicalIDs.Workers.edwinLema
    }
    
    private func getBuildingsWithExposedPlumbing() -> [String] {
        // Buildings with known exposed plumbing that need freeze protection
        return [
            CanonicalIDs.Buildings.westSeventeenth117,
            CanonicalIDs.Buildings.westEighteenth112,
            CanonicalIDs.Buildings.rubinMuseum,
            CanonicalIDs.Buildings.chambers148
        ]
    }
    
    // MARK: - Periodic Evaluation
    
    private func evaluateActiveTriggers() async {
        // Check for overdue tasks and update urgency levels
        for i in 0..<pendingTasks.count {
            let task = pendingTasks[i]
            if task.isOverdue && task.status != .overdue {
                pendingTasks[i] = TriggeredTask(
                    template: task.template,
                    triggeredBy: task.triggeredBy,
                    triggeredAt: task.triggeredAt,
                    status: .overdue,
                    completedAt: task.completedAt,
                    notes: task.notes
                )
                
                print("⚠️ Weather-triggered task is now overdue: \(task.template.name)")
            }
        }
    }
    
    deinit {
        weatherMonitoringTimer?.invalidate()
    }
}
