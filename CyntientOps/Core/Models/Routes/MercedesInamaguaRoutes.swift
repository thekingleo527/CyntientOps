//
//  MercedesInamaguaRoutes.swift
//  CyntientOps
//
//  Mercedes Inamagua — split-shift routines across 117 W 17th and 135–139 W 17th
//

import Foundation

public struct MercedesInamaguaRoutes {
    public static func getWeeklyRoutes() -> [WorkerRoute] {
        [monday(), tuesday(), wednesday(), thursday(), friday()]
    }

    private static func monday() -> WorkerRoute { dailyRoute(id: "mercedes_mon", name: "Mercedes Monday", day: 2) }
    private static func tuesday() -> WorkerRoute { dailyRoute(id: "mercedes_tue", name: "Mercedes Tuesday", day: 3) }
    private static func wednesday() -> WorkerRoute { dailyRoute(id: "mercedes_wed", name: "Mercedes Wednesday", day: 4) }
    private static func thursday() -> WorkerRoute { dailyRoute(id: "mercedes_thu", name: "Mercedes Thursday", day: 5) }
    private static func friday() -> WorkerRoute { dailyRoute(id: "mercedes_fri", name: "Mercedes Friday", day: 6) }

    private static func dailyRoute(id: String, name: String, day: Int) -> WorkerRoute {
        let startTime = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()

        // Morning block — 117 W 17th
        let seqMorning117 = sequence(
            seqId: "mer_117_am_\(day)",
            buildingId: CanonicalIDs.Buildings.westSeventeenth117,
            buildingName: "117 West 17th Street",
            hour: 6, minute: 30,
            ops: [
                OperationTask(
                    id: "117_hall_clean",
                    name: "Hallway Vacuum & Dust",
                    category: .vacuuming,
                    location: .hallway,
                    estimatedDuration: 75 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                ),
                OperationTask(
                    id: "117_trash",
                    name: "Trash Area Tidy",
                    category: .trashCollection,
                    location: .trashArea,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                )
            ]
        )

        // Mid-morning — 135–139 W 17th complex
        let seqMorning135 = sequence(
            seqId: "mer_135_am_\(day)",
            buildingId: CanonicalIDs.Buildings.westSeventeenth135_139,
            buildingName: "135–139 West 17th Street",
            hour: 9, minute: 0,
            ops: [
                OperationTask(
                    id: "135_stair_mop",
                    name: "Stairwell Mopping",
                    category: .mopping,
                    location: .stairwell,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                ),
                OperationTask(
                    id: "135_lobby",
                    name: "Lobby Wipe-down",
                    category: .sweeping,
                    location: .lobby,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                )
            ],
            dependencies: [seqMorning117.id]
        )

        // Afternoon split shift — rotations
        let seqAfternoon = sequence(
            seqId: "mer_pm_\(day)",
            buildingId: CanonicalIDs.Buildings.westSeventeenth117,
            buildingName: "117 West 17th Street",
            hour: 13, minute: 0,
            ops: [
                OperationTask(
                    id: "117_touchups",
                    name: "Afternoon Touch-ups",
                    category: .maintenance,
                    location: .interior,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                )
            ]
        )

        return WorkerRoute(
            id: id,
            workerId: CanonicalIDs.Workers.mercedesInamagua,
            routeName: name,
            dayOfWeek: day,
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [seqMorning117, seqMorning135, seqAfternoon],
            routeType: .morningCleaning
        )
    }

    private static func sequence(seqId: String, buildingId: String, buildingName: String, hour: Int, minute: Int, ops: [OperationTask], dependencies: [String] = []) -> RouteSequence {
        let at = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        let total = ops.reduce(0.0) { $0 + $1.estimatedDuration }
        return RouteSequence(
            id: seqId,
            buildingId: buildingId,
            buildingName: buildingName,
            arrivalTime: at,
            estimatedDuration: total,
            operations: ops,
            sequenceType: .indoorCleaning,
            isFlexible: true,
            dependencies: dependencies
        )
    }
}

