//
//  KevinDutanCompleteSchedule.swift
//  CyntientOps
//
//  Kevin Dutan's complete weekly and monthly operational schedule
//  Based on real operational patterns with stairwell rotation
//

import Foundation

// MARK: - Kevin Dutan Complete Schedule

public struct KevinDutanCompleteSchedule {
    
    // MARK: - Weekly Route Patterns
    
    /// Kevin's complete weekly schedule
    public static func getWeeklyRoutes() -> [WorkerRoute] {
        return [
            mondayRoute(),
            tuesdayRoute(), // Already defined in KevinDutanRoutes
            wednesdayRoute(),
            thursdayRoute(),
            fridayRoute()
            // Kevin is off Saturdays & Sundays
        ]
    }
    
    // MARK: - Daily Routes
    
    /// Monday Route
    public static func mondayRoute() -> WorkerRoute {
        let routeId = "kevin_monday_route"
        let startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.kevinDutan,
            routeName: "Kevin Monday Route",
            dayOfWeek: 2, // Monday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [
                perryStreet131Sequence(day: "Monday", time: 7, 0),
                perryStreet68Sequence(day: "Monday", time: 8, 30),
                seventeenthStreetMorningSequence(day: "Monday", time: 9, 0),
                // Poster removal immediately after Chelsea Circuit (11:30–12:00)
                seventhAvenueSequence(day: "Monday", time: 11, 30),
                // Monday afternoon: 123 1st Ave & 178 Spring (M W F pattern)
                firstAvenueAndSpringSequence(day: "Monday", time: 13, 0),
                // Weekly stairwell rotation (determined by week of year)
                stairwellRotationSequence(day: "Monday", time: 15, 0)
            ],
            routeType: .morningCleaning
        )
    }
    
    /// Tuesday Route (Reference from KevinDutanRoutes)
    public static func tuesdayRoute() -> WorkerRoute {
        return KevinDutanRoutes.tuesdayRoute()
    }
    
    /// Wednesday Route
    public static func wednesdayRoute() -> WorkerRoute {
        let routeId = "kevin_wednesday_route"
        let startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.kevinDutan,
            routeName: "Kevin Wednesday Route",
            dayOfWeek: 4, // Wednesday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [
                perryStreet131Sequence(day: "Wednesday", time: 7, 0),
                perryStreet68Sequence(day: "Wednesday", time: 8, 30),
                seventeenthStreetMorningSequence(day: "Wednesday", time: 9, 0),
                // Poster removal immediately after Chelsea Circuit (11:30–12:00)
                seventhAvenueSequence(day: "Wednesday", time: 11, 30),
                // Wednesday afternoon: 123 1st Ave & 178 Spring (M W F pattern) + Angel covers evening garbage
                firstAvenueAndSpringSequence(day: "Wednesday", time: 13, 0)
                // No evening garbage - Angel handles Wednesday evenings
            ],
            routeType: .morningCleaning
        )
    }
    
    /// Thursday Route
    public static func thursdayRoute() -> WorkerRoute {
        let routeId = "kevin_thursday_route"
        let startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.kevinDutan,
            routeName: "Kevin Thursday Route",
            dayOfWeek: 5, // Thursday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [
                perryStreet131Sequence(day: "Thursday", time: 7, 0),
                perryStreet68Sequence(day: "Thursday", time: 8, 30),
                seventeenthStreetMorningSequence(day: "Thursday", time: 9, 0),
                // Poster removal immediately after Chelsea Circuit (11:30–12:00)
                seventhAvenueSequence(day: "Thursday", time: 11, 30),
                // Thursday afternoon: Alternative buildings or projects
                alternativeBuildingsSequence(day: "Thursday", time: 14, 0)
            ],
            routeType: .morningCleaning
        )
    }
    
    /// Friday Route
    public static func fridayRoute() -> WorkerRoute {
        let routeId = "kevin_friday_route"
        let startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.kevinDutan,
            routeName: "Kevin Friday Route",
            dayOfWeek: 6, // Friday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [
                perryStreet131Sequence(day: "Friday", time: 7, 0),
                perryStreet68Sequence(day: "Friday", time: 8, 30),
                // Chelsea Circuit fixed to 9:00–11:30 window
                seventeenthStreetMorningSequence(day: "Friday", time: 9, 0),
                // Poster removal immediately after Chelsea Circuit (11:30–12:00)
                seventhAvenueSequence(day: "Friday", time: 11, 30),
                // Friday afternoon: 123 1st Ave & 178 Spring (M W F pattern)
                firstAvenueAndSpringSequence(day: "Friday", time: 13, 0),
                // Weekly maintenance tasks (water filters monthly, etc.)
                weeklyMaintenanceSequence(day: "Friday", time: 15, 0)
            ],
            routeType: .morningCleaning
        )
    }
    
    
    // MARK: - Sequence Builders
    
    /// Reusable Perry Street 131 sequence with day/time parameters
    private static func perryStreet131Sequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        let dayUpper = day.uppercased()
        let isMWF = dayUpper.contains("MON") || dayUpper.contains("WED") || dayUpper.contains("FRI")
        let stairsMopDay = dayUpper.contains("WED")

        return RouteSequence(
            id: "kevin_perry131_\(day.lowercased())",
            buildingId: CanonicalIDs.Buildings.perry131,
            buildingName: "131 Perry Street",
            arrivalTime: arrivalTime,
            estimatedDuration: 90 * 60,
            operations: {
                var ops: [OperationTask] = []
                ops.append(OperationTask(
                    id: "perry131_building_check_\(day.lowercased())",
                    name: "Building Check & Assessment",
                    category: .buildingInspection,
                    location: .entrance,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "\(day) building check - entrance, lobby, immediate issues"
                ))
                ops.append(OperationTask(
                    id: "perry131_entrance_cleaning_\(day.lowercased())",
                    name: "Entrance Area Cleaning",
                    category: .sweeping,
                    location: .entrance,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic
                ))
                // Daily bathroom check/restock
                ops.append(OperationTask(
                    id: "perry131_bathroom_check_\(day.lowercased())",
                    name: "Bathroom Check & Restock",
                    category: .maintenance,
                    location: .hallway,
                    estimatedDuration: 10 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                ))
                // Interior/Stairwell routine
                ops.append(OperationTask(
                    id: "perry131_interior_stairwell_\(day.lowercased())",
                    name: "Interior/Stairwell Routine",
                    category: .stairwellCleaning,
                    location: .stairwell,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "Stairwell and interior floors routine"
                ))
                // Hallway vacuum on M/W/F only
                if isMWF {
                    ops.append(OperationTask(
                        id: "perry131_hallway_vacuum_\(day.lowercased())",
                        name: "Hallway Vacuum (M/W/F)",
                        category: .vacuuming,
                        location: .hallway,
                        estimatedDuration: 20 * 60,
                        isWeatherSensitive: false,
                        skillLevel: .basic
                    ))
                }
                // Weekly stairs mop (Wednesday)
                if stairsMopDay {
                    ops.append(OperationTask(
                        id: "perry131_stairs_mop_\(day.lowercased())",
                        name: "Stairs Mop (Weekly)",
                        category: .mopping,
                        location: .stairwell,
                        estimatedDuration: 20 * 60,
                        isWeatherSensitive: false,
                        skillLevel: .basic
                    ))
                }
                return ops
            }(),
            sequenceType: .buildingCheck,
            isFlexible: true
        )
    }
    
    /// Reusable Perry Street 68 sequence
    private static func perryStreet68Sequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_perry68_\(day.lowercased())",
            buildingId: CanonicalIDs.Buildings.perry68,
            buildingName: "68 Perry Street",
            arrivalTime: arrivalTime,
            estimatedDuration: 30 * 60,
            operations: [
                OperationTask(
                    id: "perry68_maintenance_check_\(day.lowercased())",
                    name: "\(day) Perry Street Maintenance",
                    category: .maintenance,
                    location: .exterior,
                    estimatedDuration: 20 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .intermediate
                ),
                OperationTask(
                    id: "perry68_trash_area_\(day.lowercased())",
                    name: "Trash Area Maintenance",
                    category: .trashCollection,
                    location: .trashArea,
                    estimatedDuration: 10 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                )
            ],
            sequenceType: .maintenance,
            isFlexible: true,
            dependencies: ["kevin_perry131_\(day.lowercased())"]
        )
    }
    
    /// 17th Street morning sequence (consistent across weekdays)
    private static func seventeenthStreetMorningSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        let dayUpper = day.uppercased()
        let isMWF = dayUpper.contains("MON") || dayUpper.contains("WED") || dayUpper.contains("FRI")

        return RouteSequence(
            id: "kevin_17th_complex_\(day.lowercased())",
            buildingId: "17th_street_complex",
            buildingName: "Chelsea Circuit",
            arrivalTime: arrivalTime,
            estimatedDuration: 150 * 60, // 2.5 hours (9–11:30am)
            operations: {
                var ops: [OperationTask] = []
                // A) Sidewalk Hosing – All buildings (weather-dependent)
                ops.append(OperationTask(
                    id: "sidewalk_hosing_\(day.lowercased())_112_117",
                    name: "Sidewalk Hosing - 112 & 117 W 17th",
                    category: .hosing,
                    location: .sidewalk,
                    estimatedDuration: 20 * 60,
                    isWeatherSensitive: true,
                    requiredEquipment: ["Hose", "Squeegee"],
                    skillLevel: .basic,
                    instructions: "Hose sidewalks, squeegee, ensure drainage (skip heavy rain/ice; Weather card suggests deferral)."
                ))
                ops.append(OperationTask(
                    id: "sidewalk_hosing_\(day.lowercased())_135_139",
                    name: "Sidewalk Hosing - 135–139 W 17th",
                    category: .hosing,
                    location: .sidewalk,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic,
                    instructions: "Combined facade; focus around 139 side entrance."
                ))
                ops.append(OperationTask(
                    id: "sidewalk_hosing_\(day.lowercased())_136_148",
                    name: "Sidewalk Hosing - 136–148 W 17th",
                    category: .hosing,
                    location: .sidewalk,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic,
                    instructions: "Grouped entrances including 142, 144, 146, 148."
                ))

                // B) Hallway Vacuum – M/W/F only (112, 117)
                if isMWF {
                    ops.append(OperationTask(
                        id: "vacuum_hallways_\(day.lowercased())_112",
                        name: "Hallway Vacuum – 112 W 18th (Floors 2–6)",
                        category: .vacuuming,
                        location: .hallway,
                        estimatedDuration: 30 * 60,
                        isWeatherSensitive: false,
                        requiredEquipment: ["Vacuum"],
                        instructions: "Show on M/W/F only; hallways + stair landings."
                    ))
                    ops.append(OperationTask(
                        id: "vacuum_hallways_\(day.lowercased())_117",
                        name: "Hallway Vacuum – 117 W 17th (Floors 2–6)",
                        category: .vacuuming,
                        location: .hallway,
                        estimatedDuration: 30 * 60,
                        isWeatherSensitive: false,
                        requiredEquipment: ["Vacuum"],
                        instructions: "Show on M/W/F only; hallways + stair landings."
                    ))
                }

                // C) Trash Areas – All buildings
                ops.append(OperationTask(
                    id: "trash_areas_all_\(day.lowercased())",
                    name: "Trash Areas – All (112, 117, 135–139, 136–148)",
                    category: .trashCollection,
                    location: .trashArea,
                    estimatedDuration: 45 * 60,
                    isWeatherSensitive: false,
                    instructions: "Sweep, mop floors, wipe bins; clean laundry areas at 142 & 146; sanitize machine tops."
                ))

                // D) Garbage Removal – Consolidation (no curb set-out)
                ops.append(OperationTask(
                    id: "garbage_removal_circuit_\(day.lowercased())",
                    name: "Garbage Removal – Circuit Buildings",
                    category: .trashCollection,
                    location: .trashArea,
                    estimatedDuration: 20 * 60,
                    isWeatherSensitive: false,
                    instructions: "Consolidate and stage trash in building trash rooms; set-out only at DSNY times."
                ))

                return ops
            }(),
            sequenceType: .indoorCleaning,
            isFlexible: true,
            dependencies: ["kevin_perry68_\(day.lowercased())"]
        )
    }
    
    /// 7th Avenue sequence (poster removal only, after circuit)
    private static func seventhAvenueSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_7th_avenue_\(day.lowercased())",
            buildingId: CanonicalIDs.Buildings.seventhAvenue115,
            buildingName: "115 7th Avenue",
            arrivalTime: arrivalTime,
            estimatedDuration: 30 * 60, // 15–30 minutes
            operations: [
                OperationTask(
                    id: "poster_removal_7th_ave_\(day.lowercased())",
                    name: "Poster Removal - 115 7th Avenue",
                    category: .posterRemoval,
                    location: .exterior,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .intermediate,
                    instructions: "\(day): Remove illegal postings; clean adhesive residue."
                )
            ],
            sequenceType: .outdoorCleaning,
            isFlexible: false, // Weather dependent but cannot be skipped
            dependencies: ["kevin_17th_complex_\(day.lowercased())"]
        )
    }
    
    /// 123 1st Avenue & 178 Spring Street sequence (M W F pattern)
    private static func firstAvenueAndSpringSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_1st_spring_\(day.lowercased())",
            buildingId: "multi_location",
            buildingName: "123 1st Ave & 178 Spring St",
            arrivalTime: arrivalTime,
            estimatedDuration: 120 * 60, // 2 hours
            operations: [
                OperationTask(
                    id: "firstave_garbage_removal_\(day.lowercased())",
                    name: "Garbage Removal - 123 1st Avenue",
                    category: .trashCollection,
                    location: .trashArea,
                    estimatedDuration: 20 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "Consolidate and stage trash; do not curb before set-out window."
                ),
                OperationTask(
                    id: "building_maintenance_1st_ave_\(day.lowercased())",
                    name: "Building Maintenance - 123 1st Avenue",
                    category: .maintenance,
                    location: .exterior,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .intermediate,
                    instructions: "\(day): Full building exterior and common area maintenance"
                ),
                OperationTask(
                    id: "spring_garbage_removal_\(day.lowercased())",
                    name: "Garbage Removal - 178 Spring Street",
                    category: .trashCollection,
                    location: .trashArea,
                    estimatedDuration: 20 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "Consolidate and stage trash; do not curb before set-out window."
                ),
                OperationTask(
                    id: "building_cleaning_spring_\(day.lowercased())",
                    name: "Building Cleaning - 178 Spring Street",
                    category: .sweeping,
                    location: .exterior,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic,
                    instructions: "\(day): Exterior cleaning and entrance maintenance"
                )
            ],
            sequenceType: .maintenance,
            isFlexible: true,
            dependencies: ["kevin_7th_avenue_\(day.lowercased())"]
        )
    }
    
    /// Stairwell rotation sequence (weekly assignments)
    private static func stairwellRotationSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        // Determine which stairwells to clean this week (this would be calculated dynamically)
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        let assignedBuildings = getStairwellAssignmentsForWeek(currentWeek)
        
        return RouteSequence(
            id: "kevin_stairwell_rotation_\(day.lowercased())",
            buildingId: assignedBuildings.first?.buildingId ?? "unknown",
            buildingName: "Stairwell Cleaning Rotation",
            arrivalTime: arrivalTime,
            estimatedDuration: 60 * 60, // 1 hour per building
            operations: assignedBuildings.map { building in
                OperationTask(
                    id: "stairwell_cleaning_\(building.buildingId)_\(day.lowercased())",
                    name: "Stairwell Cleaning - \(building.buildingName)",
                    category: .stairwellCleaning,
                    location: .stairwell,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    requiredEquipment: ["Vacuum", "Mop", "Cleaning supplies"],
                    skillLevel: .basic,
                    instructions: "Clean stairwell floors \(building.floors.map { String($0) }.joined(separator: ", "))"
                )
            },
            sequenceType: .indoorCleaning,
            isFlexible: true
        )
    }
    
    /// Alternative buildings sequence for days without 123 1st/178 Spring
    private static func alternativeBuildingsSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_alternative_buildings_\(day.lowercased())",
            buildingId: "various",
            buildingName: "Alternative Building Maintenance",
            arrivalTime: arrivalTime,
            estimatedDuration: 90 * 60,
            operations: [
                OperationTask(
                    id: "alternative_maintenance_\(day.lowercased())",
                    name: "Alternative Building Tasks",
                    category: .maintenance,
                    location: .exterior,
                    estimatedDuration: 90 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .intermediate,
                    instructions: "\(day): Focus on buildings not covered in regular rotation"
                )
            ],
            sequenceType: .maintenance,
            isFlexible: true
        )
    }
    
    /// Weekly maintenance tasks (water filters, etc.)
    private static func weeklyMaintenanceSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_weekly_maintenance_\(day.lowercased())",
            buildingId: "various",
            buildingName: "Weekly Maintenance Tasks",
            arrivalTime: arrivalTime,
            estimatedDuration: 60 * 60,
            operations: [
                OperationTask(
                    id: "water_filters_monthly_\(day.lowercased())",
                    name: "Water Filter Check/Change - 112 & 117",
                    category: .maintenance,
                    location: .basement,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .intermediate,
                    instructions: "Monthly water filter maintenance for buildings 112 and 117"
                ),
                OperationTask(
                    id: "general_weekly_maintenance_\(day.lowercased())",
                    name: "General Weekly Maintenance",
                    category: .maintenance,
                    location: .exterior,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic,
                    instructions: "General building maintenance tasks"
                )
            ],
            sequenceType: .maintenance,
            isFlexible: true
        )
    }
    
    
    /// Project work sequence (capital improvements)
    private static func projectWorkSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_project_work_\(day.lowercased())",
            buildingId: CanonicalIDs.Buildings.chambers148,
            buildingName: "Capital Improvement Projects",
            arrivalTime: arrivalTime,
            estimatedDuration: 120 * 60,
            operations: [
                OperationTask(
                    id: "capital_improvement_work_\(day.lowercased())",
                    name: "Capital Improvement Support Work",
                    category: .maintenance,
                    location: .basement,
                    estimatedDuration: 120 * 60,
                    isWeatherSensitive: false,
                    requiredEquipment: ["Hand tools", "Cleaning supplies"],
                    skillLevel: .intermediate,
                    instructions: "Support capital improvement projects - no painting (done by Shawn, Edwin, or contractors)"
                )
            ],
            sequenceType: .maintenance,
            isFlexible: false // Projects have deadlines
        )
    }
    
    // MARK: - Stairwell Assignment Logic
    
    /// Get stairwell assignments for a specific week (this would be more sophisticated in practice)
    private static func getStairwellAssignmentsForWeek(_ week: Int) -> [StairwellInfo] {
        let allBuildings = [
            StairwellInfo(buildingId: CanonicalIDs.Buildings.westEighteenth112, buildingName: "112 West 18th Street", floors: [2, 3, 4, 5, 6]),
            StairwellInfo(buildingId: CanonicalIDs.Buildings.westSeventeenth117, buildingName: "117 West 17th Street", floors: [2, 3, 4, 5, 6]),
            StairwellInfo(buildingId: CanonicalIDs.Buildings.rubinMuseum, buildingName: "Rubin Museum Complex", floors: [1, 2, 3, 4, 5, 6])
        ]
        
        // Simple rotation - in practice this would be more sophisticated
        let assignedIndex = week % allBuildings.count
        return [allBuildings[assignedIndex]]
    }
    
    private struct StairwellInfo {
        let buildingId: String
        let buildingName: String
        let floors: [Int]
    }
}
