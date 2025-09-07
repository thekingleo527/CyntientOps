//
//  OperationalCalendar.swift
//  CyntientOps
//
//  Comprehensive operational calendar system for Franco Management
//  Handles weekly, monthly, and project-based scheduling patterns
//

import Foundation

// MARK: - Operational Calendar System

/// Manages complex scheduling patterns across multiple workers and timeframes
public struct OperationalCalendar {
    
    // MARK: - Schedule Patterns
    
    /// Represents different recurring patterns for operations
    public enum RecurrencePattern: Codable {
        case daily
        case weekdays           // M-F
        case mondayWednesdayFriday  // M W F
        case tuesdayThursdayFriday  // T Th F
        case weekly(dayOfWeek: Int) // Specific weekday
        case biWeekly(dayOfWeek: Int, weekOffset: Int) // Every other week
        case monthly(week: Int, dayOfWeek: Int) // e.g., 2nd Tuesday of month
        case monthlyDate(day: Int) // e.g., 15th of every month
        case seasonal(months: [Int]) // Specific months only
        case weatherTriggered(condition: WeatherTrigger)
        case projectBased(startDate: Date, endDate: Date)
        
        public var description: String {
            switch self {
            case .daily: return "Daily"
            case .weekdays: return "Weekdays (M-F)"
            case .mondayWednesdayFriday: return "Monday, Wednesday, Friday"
            case .tuesdayThursdayFriday: return "Tuesday, Thursday, Friday"
            case .weekly(let day): return "Weekly on \(dayName(day))"
            case .biWeekly(let day, _): return "Bi-weekly on \(dayName(day))"
            case .monthly(let week, let day): return "\(ordinal(week)) \(dayName(day)) of month"
            case .monthlyDate(let day): return "\(day)th of every month"
            case .seasonal(let months): return "Seasonal: \(months.map { monthName($0) }.joined(separator: ", "))"
            case .weatherTriggered(let condition): return "Weather triggered: \(condition)"
            case .projectBased(let start, let end): return "Project: \(start.formatted(date: .abbreviated, time: .omitted)) - \(end.formatted(date: .abbreviated, time: .omitted))"
            }
        }
        
        private func dayName(_ day: Int) -> String {
            let names = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            return names[safe: day] ?? "Unknown"
        }
        
        private func monthName(_ month: Int) -> String {
            let names = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            return names[safe: month] ?? "Unknown"
        }
        
        private func ordinal(_ number: Int) -> String {
            switch number {
            case 1: return "1st"
            case 2: return "2nd"  
            case 3: return "3rd"
            case 4: return "4th"
            default: return "\(number)th"
            }
        }
    }
    
    public enum WeatherTrigger: String, Codable, CaseIterable {
        case beforeRain = "Before Rain"
        case afterRain = "After Rain"
        case heavyWindWarning = "Heavy Wind Warning"
        case freezeWarning = "Freeze Warning"
        case heatWave = "Heat Wave"
        
        public var description: String { rawValue }
    }
    
    // MARK: - Operational Task Template
    
    /// Template for recurring operational tasks
    public struct OperationalTaskTemplate: Codable, Identifiable {
        public let id: String
        public let name: String
        public let category: OperationTask.TaskCategory
        public let location: OperationTask.TaskLocation
        public let estimatedDuration: TimeInterval
        public let skillLevel: OperationTask.SkillLevel
        public let isWeatherSensitive: Bool
        public let requiredEquipment: [String]
        public let instructions: String?
        public let requiresPhoto: Bool
        
        // Scheduling
        public let recurrence: RecurrencePattern
        public let preferredTimeSlot: PreferredTimeSlot
        public let buildingIds: [String] // Buildings this applies to
        public let assignedWorkerId: String
        
        // Constraints
        public let cannotCoexistWith: [String] // Task IDs that cannot happen same day
        public let mustFollowAfter: [String] // Task IDs that must precede this
        public let seasonalConstraints: [SeasonalConstraint]
        
        public enum PreferredTimeSlot: String, Codable, CaseIterable {
            case earlyMorning = "Early Morning" // 6-9 AM
            case midMorning = "Mid Morning" // 9-12 PM  
            case afterLunch = "After Lunch" // 12-3 PM
            case lateAfternoon = "Late Afternoon" // 3-6 PM
            case evening = "Evening" // 6-9 PM
            case flexible = "Flexible"
            
            public var timeRange: (start: Int, end: Int) {
                switch self {
                case .earlyMorning: return (6, 9)
                case .midMorning: return (9, 12)
                case .afterLunch: return (12, 15)
                case .lateAfternoon: return (15, 18)
                case .evening: return (18, 21)
                case .flexible: return (6, 18)
                }
            }
        }
        
        public struct SeasonalConstraint: Codable {
            public let months: [Int]
            public let reason: String
            
            public init(months: [Int], reason: String) {
                self.months = months
                self.reason = reason
            }
        }
        
        public init(id: String, name: String, category: OperationTask.TaskCategory,
                    location: OperationTask.TaskLocation, estimatedDuration: TimeInterval,
                    skillLevel: OperationTask.SkillLevel = .basic, isWeatherSensitive: Bool = false,
                    requiredEquipment: [String] = [], instructions: String? = nil,
                    requiresPhoto: Bool = false, recurrence: RecurrencePattern,
                    preferredTimeSlot: PreferredTimeSlot, buildingIds: [String],
                    assignedWorkerId: String, cannotCoexistWith: [String] = [],
                    mustFollowAfter: [String] = [], seasonalConstraints: [SeasonalConstraint] = []) {
            self.id = id
            self.name = name
            self.category = category
            self.location = location
            self.estimatedDuration = estimatedDuration
            self.skillLevel = skillLevel
            self.isWeatherSensitive = isWeatherSensitive
            self.requiredEquipment = requiredEquipment
            self.instructions = instructions
            self.requiresPhoto = requiresPhoto
            self.recurrence = recurrence
            self.preferredTimeSlot = preferredTimeSlot
            self.buildingIds = buildingIds
            self.assignedWorkerId = assignedWorkerId
            self.cannotCoexistWith = cannotCoexistWith
            self.mustFollowAfter = mustFollowAfter
            self.seasonalConstraints = seasonalConstraints
        }
    }
    
    // MARK: - Capital Improvement Projects
    
    /// Represents ongoing capital improvement projects
    public struct CapitalProject: Codable, Identifiable {
        public let id: String
        public let name: String
        public let description: String
        public let buildingId: String
        public let buildingName: String
        public let projectType: ProjectType
        public let startDate: Date
        public let estimatedEndDate: Date
        public let assignedWorkerId: String
        public let dailyHours: TimeInterval
        public let preferredTimeSlot: OperationalTaskTemplate.PreferredTimeSlot
        public let requiredEquipment: [String]
        public let safetyRequirements: [String]
        public let weatherConstraints: [String]
        public let status: ProjectStatus
        
        public enum ProjectType: String, Codable, CaseIterable {
            case painting = "Painting"
            case stairwellRenovation = "Stairwell Renovation"
            case basementWork = "Basement Work"
            case roofRepair = "Roof Repair"
            case plumbing = "Plumbing"
            case electrical = "Electrical"
            case hvac = "HVAC"
            case structural = "Structural"
            case cosmetic = "Cosmetic"
        }
        
        public enum ProjectStatus: String, Codable, CaseIterable {
            case planning = "Planning"
            case inProgress = "In Progress"
            case onHold = "On Hold"
            case completed = "Completed"
            case cancelled = "Cancelled"
        }
        
        public init(id: String, name: String, description: String, buildingId: String,
                    buildingName: String, projectType: ProjectType, startDate: Date,
                    estimatedEndDate: Date, assignedWorkerId: String, dailyHours: TimeInterval,
                    preferredTimeSlot: OperationalTaskTemplate.PreferredTimeSlot,
                    requiredEquipment: [String] = [], safetyRequirements: [String] = [],
                    weatherConstraints: [String] = [], status: ProjectStatus = .planning) {
            self.id = id
            self.name = name
            self.description = description
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.projectType = projectType
            self.startDate = startDate
            self.estimatedEndDate = estimatedEndDate
            self.assignedWorkerId = assignedWorkerId
            self.dailyHours = dailyHours
            self.preferredTimeSlot = preferredTimeSlot
            self.requiredEquipment = requiredEquipment
            self.safetyRequirements = safetyRequirements
            self.weatherConstraints = weatherConstraints
            self.status = status
        }
    }
    
    // MARK: - Stairwell Rotation System
    
    /// Manages weekly stairwell cleaning rotation across buildings
    public struct StairwellRotation {
        public let buildingStairwells: [String: StairwellInfo] // BuildingID -> Info
        public let weeklyAssignments: [Int: [String]] // Week of year -> Building IDs
        
        public struct StairwellInfo: Codable {
            public let buildingId: String
            public let buildingName: String
            public let floors: [Int]
            public let estimatedDuration: TimeInterval
            public let accessRequirements: [String]
            public let specialInstructions: String?
            
            public init(buildingId: String, buildingName: String, floors: [Int],
                        estimatedDuration: TimeInterval, accessRequirements: [String] = [],
                        specialInstructions: String? = nil) {
                self.buildingId = buildingId
                self.buildingName = buildingName
                self.floors = floors
                self.estimatedDuration = estimatedDuration
                self.accessRequirements = accessRequirements
                self.specialInstructions = specialInstructions
            }
        }
        
        public init(buildingStairwells: [String: StairwellInfo]) {
            self.buildingStairwells = buildingStairwells
            
            // Generate weekly assignments (spread buildings across weeks)
            let buildings = Array(buildingStairwells.keys)
            var assignments: [Int: [String]] = [:]
            
            for (index, buildingId) in buildings.enumerated() {
                let weekOfYear = (index % 52) + 1 // Distribute across 52 weeks
                if assignments[weekOfYear] == nil {
                    assignments[weekOfYear] = []
                }
                assignments[weekOfYear]?.append(buildingId)
            }
            
            self.weeklyAssignments = assignments
        }
        
        /// Get stairwells to clean for a specific week
        public func getStairwellsForWeek(_ week: Int) -> [StairwellInfo] {
            let buildingIds = weeklyAssignments[week] ?? []
            return buildingIds.compactMap { buildingStairwells[$0] }
        }
    }
}

// MARK: - Array Extension for Safe Access

private extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
