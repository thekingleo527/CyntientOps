//
//  KevinDutanRoutes.swift
//  CyntientOps
//
//  Kevin Dutan's precise operational routes and sequences
//  Based on real-world operational patterns and building requirements
//

import Foundation

// MARK: - Kevin Dutan Route Definitions

public struct KevinDutanRoutes {
    
    // MARK: - Tuesday Route (Example Day)
    
    /// Kevin's complete Tuesday route with precise timing and sequences
    public static func tuesdayRoute() -> WorkerRoute {
        let routeId = "kevin_tuesday_route"
        let startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.kevinDutan,
            routeName: "Kevin Tuesday Full Route",
            dayOfWeek: 3, // Tuesday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [
                perryStreet131Sequence(),
                perryStreet68Sequence(), 
                seventeenthStreetComplexSequence(),
                seventhAvenueSequence(),
                firstAvenueAndSpringSequence()
            ],
            routeType: .morningCleaning
        )
    }
    
    // MARK: - Route Sequences
    
    /// 7:00 AM - 131 Perry Street building check
    private static func perryStreet131Sequence() -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_perry131",
            buildingId: CanonicalIDs.Buildings.perry131,
            buildingName: "131 Perry Street",
            arrivalTime: arrivalTime,
            estimatedDuration: 30 * 60, // 30 minutes
            operations: [
                OperationTask(
                    id: "perry131_building_check",
                    name: "Building Check & Assessment",
                    category: .buildingInspection,
                    location: .entrance,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "Check entrance, lobby, immediate issues"
                ),
                OperationTask(
                    id: "perry131_entrance_cleaning",
                    name: "Entrance Area Cleaning",
                    category: .sweeping,
                    location: .entrance,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic
                )
            ],
            sequenceType: .buildingCheck,
            isFlexible: true
        )
    }
    
    /// 8:00 AM - 68 Perry Street operations
    private static func perryStreet68Sequence() -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_perry68",
            buildingId: CanonicalIDs.Buildings.perry68,
            buildingName: "68 Perry Street",
            arrivalTime: arrivalTime,
            estimatedDuration: 45 * 60, // 45 minutes
            operations: [
                OperationTask(
                    id: "perry68_maintenance_check",
                    name: "Perry Street Maintenance",
                    category: .maintenance,
                    location: .exterior,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .intermediate
                ),
                OperationTask(
                    id: "perry68_trash_area",
                    name: "Trash Area Maintenance",
                    category: .trashCollection,
                    location: .trashArea,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                )
            ],
            sequenceType: .maintenance,
            isFlexible: true,
            dependencies: ["kevin_perry131"]
        )
    }
    
    /// 9:15 AM - 12:00 PM - 17th Street Complex (Most Complex Sequence)
    private static func seventeenthStreetComplexSequence() -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: 9, minute: 15, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_17th_complex",
            buildingId: "17th_street_complex", // Multi-building sequence
            buildingName: "17th Street Building Complex",
            arrivalTime: arrivalTime,
            estimatedDuration: 165 * 60, // 2 hours 45 minutes
            operations: [
                // Phase 1: Outdoor Operations (Weather-Sensitive)
                OperationTask(
                    id: "sidewalk_hosing_112_117",
                    name: "Sidewalk Hosing - 112 & 117 W 17th",
                    category: .hosing,
                    location: .sidewalk,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: true,
                    requiredEquipment: ["Hose", "Squeegee"],
                    skillLevel: .basic,
                    instructions: "Hose sidewalks, squeegee clean, ensure proper drainage"
                ),
                OperationTask(
                    id: "sidewalk_hosing_135_139",
                    name: "Sidewalk Hosing - 135-139 W 17th",
                    category: .hosing,
                    location: .sidewalk,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: true,
                    instructions: "Focus on 139 side entrance area"
                ),
                OperationTask(
                    id: "sidewalk_hosing_136_148",
                    name: "Sidewalk Hosing - 136-148 W 17th (Rubin Complex)",
                    category: .hosing,
                    location: .sidewalk,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: true,
                    instructions: "Shared sidewalk for museum complex buildings"
                ),
                OperationTask(
                    id: "bins_retrieval_multiple",
                    name: "Trash Bins Retrieval - Multiple Buildings",
                    category: .binManagement,
                    location: .curbside,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: true,
                    instructions: "Return bins to designated indoor areas after collection"
                ),
                
                // Phase 2: Indoor Operations (Weather-Protected)
                OperationTask(
                    id: "vacuum_hallways_112",
                    name: "Vacuum Hallways Floors 2-6 - 112 W 17th",
                    category: .vacuuming,
                    location: .hallway,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: false,
                    requiredEquipment: ["Vacuum"],
                    instructions: "Floors 2, 3, 4, 5, 6 hallways and stairwell landings"
                ),
                OperationTask(
                    id: "vacuum_hallways_117",
                    name: "Vacuum Hallways Floors 2-6 - 117 W 17th",
                    category: .vacuuming,
                    location: .hallway,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: false,
                    requiredEquipment: ["Vacuum"],
                    instructions: "Floors 2, 3, 4, 5, 6 hallways and stairwell landings"
                ),
                
                // Phase 3: Sanitation Operations
                OperationTask(
                    id: "trash_areas_multiple",
                    name: "Trash Area Cleaning - All 17th St Buildings",
                    category: .trashCollection,
                    location: .trashArea,
                    estimatedDuration: 45 * 60,
                    isWeatherSensitive: false,
                    instructions: "Clean trash areas for 112, 117, 136, 138, 142-148"
                ),
                OperationTask(
                    id: "basement_cleaning_135",
                    name: "Basement Cleaning - 135 Side",
                    category: .mopping,
                    location: .basement,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: false,
                    instructions: "135 side basement area cleaning"
                ),
                OperationTask(
                    id: "mop_trash_areas_rubin",
                    name: "Mop Trash Areas - Rubin Museum Complex",
                    category: .mopping,
                    location: .trashArea,
                    estimatedDuration: 20 * 60,
                    isWeatherSensitive: false,
                    instructions: "Mop trash areas in 136, 138, 142-148"
                ),
                OperationTask(
                    id: "mop_second_floors_rubin",
                    name: "Mop 2nd Floors - Rubin Museum Buildings",
                    category: .mopping,
                    location: .hallway,
                    estimatedDuration: 25 * 60,
                    isWeatherSensitive: false,
                    instructions: "2nd floor mopping in 142-144 and 146-148"
                ),
                OperationTask(
                    id: "laundry_rooms_rubin",
                    name: "Laundry Room Cleaning - 142 & 146",
                    category: .laundryRoom,
                    location: .laundryRoom,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: false,
                    instructions: "Clean laundry rooms in buildings 142 and 146"
                )
            ],
            sequenceType: .indoorCleaning,
            isFlexible: true, // Can reorder indoor vs outdoor based on weather
            dependencies: ["kevin_perry68"]
        )
    }
    
    /// 12:00 PM - 115 7th Avenue (Weather-Sensitive Detail Work)
    private static func seventhAvenueSequence() -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_7th_avenue",
            buildingId: CanonicalIDs.Buildings.seventhAvenue115,
            buildingName: "115 7th Avenue",
            arrivalTime: arrivalTime,
            estimatedDuration: 90 * 60, // 1.5 hours
            operations: [
                OperationTask(
                    id: "poster_removal_7th_ave",
                    name: "Poster Removal - 115 7th Avenue",
                    category: .posterRemoval,
                    location: .exterior,
                    estimatedDuration: 45 * 60,
                    isWeatherSensitive: true, // Cannot do in rain
                    skillLevel: .intermediate,
                    instructions: "Remove illegal postings, clean adhesive residue"
                ),
                OperationTask(
                    id: "treepit_cleaning_7th_ave",
                    name: "Treepit Cleaning - 115 7th Avenue Area",
                    category: .treepitCleaning,
                    location: .treepit,
                    estimatedDuration: 45 * 60,
                    isWeatherSensitive: true, // Difficult in wet conditions
                    requiredEquipment: ["Hand tools", "Trash bags"],
                    instructions: "Clean tree pits, remove debris, maintain landscaping"
                )
            ],
            sequenceType: .outdoorCleaning,
            isFlexible: false, // Must be done in good weather
            dependencies: ["kevin_17th_complex"]
        )
    }
    
    /// 1:30 PM - 123 1st Avenue & 178 Spring Street
    private static func firstAvenueAndSpringSequence() -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: 13, minute: 30, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_1st_spring",
            buildingId: "multi_location", // Multi-building
            buildingName: "123 1st Ave & 178 Spring St",
            arrivalTime: arrivalTime,
            estimatedDuration: 90 * 60, // 1.5 hours
            operations: [
                OperationTask(
                    id: "building_maintenance_1st_ave",
                    name: "Building Maintenance - 123 1st Avenue",
                    category: .maintenance,
                    location: .exterior,
                    estimatedDuration: 45 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .intermediate
                ),
                OperationTask(
                    id: "building_cleaning_spring",
                    name: "Building Cleaning - 178 Spring Street",
                    category: .sweeping,
                    location: .exterior,
                    estimatedDuration: 45 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic
                )
            ],
            sequenceType: .maintenance,
            isFlexible: true,
            dependencies: ["kevin_7th_avenue"]
        )
    }
}

// MARK: - Building Profiles for Kevin's Route

public struct KevinBuildingProfiles {
    
    /// Building operational profiles for Kevin's assigned buildings
    public static func getAllProfiles() -> [BuildingOperationalProfile] {
        return [
            rubinMuseumComplexProfile(),
            westSeventeenth112Profile(),
            westSeventeenth117Profile(),
            westSeventeenth135_139Profile()
        ]
    }
    
    /// Rubin Museum Complex (142-148 W 17th) - Most Complex
    private static func rubinMuseumComplexProfile() -> BuildingOperationalProfile {
        return BuildingOperationalProfile(
            id: "rubin_museum_complex",
            buildingId: CanonicalIDs.Buildings.rubinMuseum,
            buildingName: "Rubin Museum Complex (142-148 W 17th)",
            operationalComplexity: .institutional,
            floorConfiguration: BuildingOperationalProfile.FloorConfiguration(
                totalFloors: 6,
                basementLevels: 1,
                hallwayFloors: [2],
                stairwellFloors: [1, 2, 3, 4, 5, 6],
                specialFloors: [1: "Museum Entrance", 2: "Gallery Floors"]
            ),
            specialRequirements: [
                .laundryRoom,
                .multipleTrashAreas,
                .sharedSidewalk,
                .museumProtocols
            ],
            accessConstraints: [
                .timeRestricted,
                .securityProtocol,
                .noiseRestriction
            ],
            weatherSensitiveAreas: [
                .sidewalk,
                .entrance,
                .curbside
            ]
        )
    }
    
    /// 112 W 17th Street Profile
    private static func westSeventeenth112Profile() -> BuildingOperationalProfile {
        return BuildingOperationalProfile(
            id: "west_17th_112",
            buildingId: CanonicalIDs.Buildings.westEighteenth112,
            buildingName: "112 West 17th Street",
            operationalComplexity: .moderate,
            floorConfiguration: BuildingOperationalProfile.FloorConfiguration(
                totalFloors: 6,
                basementLevels: 0,
                hallwayFloors: [2, 3, 4, 5, 6],
                stairwellFloors: [2, 3, 4, 5, 6]
            ),
            specialRequirements: [],
            accessConstraints: [.keyRequired],
            weatherSensitiveAreas: [.sidewalk, .entrance]
        )
    }
    
    /// 117 W 17th Street Profile  
    private static func westSeventeenth117Profile() -> BuildingOperationalProfile {
        return BuildingOperationalProfile(
            id: "west_17th_117",
            buildingId: CanonicalIDs.Buildings.westSeventeenth117,
            buildingName: "117 West 17th Street",
            operationalComplexity: .moderate,
            floorConfiguration: BuildingOperationalProfile.FloorConfiguration(
                totalFloors: 6,
                basementLevels: 0,
                hallwayFloors: [2, 3, 4, 5, 6],
                stairwellFloors: [2, 3, 4, 5, 6]
            ),
            specialRequirements: [],
            accessConstraints: [.keyRequired],
            weatherSensitiveAreas: [.sidewalk, .entrance]
        )
    }
    
    /// 135-139 W 17th Street Profile (Two-Sided Building)
    private static func westSeventeenth135_139Profile() -> BuildingOperationalProfile {
        return BuildingOperationalProfile(
            id: "west_17th_135_139",
            buildingId: CanonicalIDs.Buildings.westSeventeenth135_139,
            buildingName: "135-139 West 17th Street",
            operationalComplexity: .complex,
            floorConfiguration: BuildingOperationalProfile.FloorConfiguration(
                totalFloors: 6,
                basementLevels: 1,
                hallwayFloors: [2, 3, 4, 5, 6],
                stairwellFloors: [2, 3, 4, 5, 6],
                specialFloors: [0: "135 Side Basement"]
            ),
            specialRequirements: [
                .separateBuildingSides,
                .multipleTrashAreas
            ],
            accessConstraints: [.keyRequired],
            weatherSensitiveAreas: [.sidewalk, .entrance, .curbside]
        )
    }
}