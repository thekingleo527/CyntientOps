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
                ),
                OperationTask(
                    id: "117_lobby_glass",
                    name: "Lobby Glass & Doors",
                    category: .maintenance,
                    location: .entrance,
                    estimatedDuration: 20 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                ),
                OperationTask(
                    id: "117_elevator_cab",
                    name: "Elevator Cab Clean",
                    category: .maintenance,
                    location: .hallway,
                    estimatedDuration: 20 * 60,
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
                    location: .entrance,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                ),
                OperationTask(
                    id: "135_lobby_glass",
                    name: "Lobby Glass & Doors",
                    category: .maintenance,
                    location: .entrance,
                    estimatedDuration: 20 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                ),
                OperationTask(
                    id: "135_elevator_cab",
                    name: "Elevator Cab Clean",
                    category: .maintenance,
                    location: .hallway,
                    estimatedDuration: 20 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                )
            ],
            dependencies: [seqMorning117.id]
        )

        // Midday — 112 W 18th lobby/glass
        let seqMid112 = sequence(
            seqId: "mer_112_mid_\(day)",
            buildingId: CanonicalIDs.Buildings.westEighteenth112,
            buildingName: "112 West 18th Street",
            hour: 11, minute: 30,
            ops: [
                OperationTask(
                    id: "112_lobby_glass",
                    name: "Lobby Glass & Doors",
                    category: .maintenance,
                    location: .entrance,
                    estimatedDuration: 20 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                ),
                OperationTask(
                    id: "112_mail_area",
                    name: "Mail Area Tidy",
                    category: .maintenance,
                    location: .hallway,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                )
            ],
            dependencies: [seqMorning135.id]
        )

        // Rubin Complex (walkups) — mail areas / lobby vestibules (no elevators)
        let seqRubinMail = sequence(
            seqId: "mer_rubin_mail_\(day)",
            buildingId: CanonicalIDs.Buildings.rubinMuseum,
            buildingName: "Rubin Museum Complex (142-148 W 17th)",
            hour: 12, minute: 15,
            ops: [
                OperationTask(
                    id: "rubin_mail_lobby_walkups",
                    name: "Mail Areas & Lobby Vestibules – Rubin (Walkups)",
                    category: .maintenance,
                    location: .entrance,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "Clean mail areas and vestibules for 142, 144, 146, 148 W 17th; no elevators in these walkups."
                )
            ],
            dependencies: [seqMid112.id]
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
                    location: .hallway,
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
            sequences: [seqMorning117, seqMorning135, seqMid112, seqRubinMail, seqAfternoon],
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
