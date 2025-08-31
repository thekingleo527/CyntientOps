//
//  LuisLopezRoutes.swift
//  CyntientOps
//
//  Luis Lopez — 41 Elizabeth, 104 Franklin, 36 Walker (only)
//

import Foundation

public struct LuisLopezRoutes {
    public static func getWeeklyRoutes() -> [WorkerRoute] {
        [monday(), tuesday(), wednesday(), thursday(), friday()]
    }

    private static func monday() -> WorkerRoute { daily("luis_mon", name: "Luis Monday", day: 2) }
    private static func tuesday() -> WorkerRoute { daily("luis_tue", name: "Luis Tuesday", day: 3) }
    private static func wednesday() -> WorkerRoute { daily("luis_wed", name: "Luis Wednesday", day: 4) }
    private static func thursday() -> WorkerRoute { daily("luis_thu", name: "Luis Thursday", day: 5) }
    private static func friday() -> WorkerRoute { daily("luis_fri", name: "Luis Friday", day: 6) }

    private static func daily(_ id: String, name: String, day: Int) -> WorkerRoute {
        let startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()

        let franklinAM = sequence(
            seqId: "luis_franklin_am_\(day)",
            buildingId: CanonicalIDs.Buildings.franklin104,
            buildingName: "104 Franklin Street",
            hour: 7, minute: 0,
            ops: [
                OperationTask(id: "frk_sidewalk", name: "Sidewalk Sweep/Hose", category: .hosing, location: .sidewalk, estimatedDuration: 45*60, isWeatherSensitive: true, skillLevel: .basic),
                OperationTask(id: "frk_bins", name: "Bins Check & Tidy", category: .binManagement, location: .trashArea, estimatedDuration: 15*60, isWeatherSensitive: true, skillLevel: .basic)
            ]
        )

        let elizabethAM = sequence(
            seqId: "luis_41elizabeth_am_\(day)",
            buildingId: CanonicalIDs.Buildings.elizabeth41,
            buildingName: "41 Elizabeth Street",
            hour: 9, minute: 30,
            ops: [
                OperationTask(id: "elizabeth_lobby", name: "Lobby/Entrance", category: .sweeping, location: .lobby, estimatedDuration: 30*60, isWeatherSensitive: false, skillLevel: .basic),
                OperationTask(id: "elizabeth_hall", name: "Hallway Vacuum", category: .vacuuming, location: .hallway, estimatedDuration: 45*60, isWeatherSensitive: false, skillLevel: .basic)
            ],
            dependencies: [franklinAM.id]
        )

        let afternoon = sequence(
            seqId: "luis_pm_\(day)",
            buildingId: CanonicalIDs.Buildings.walker36,
            buildingName: "36 Walker Street",
            hour: 13, minute: 0,
            ops: [
                OperationTask(id: "walker_repairs", name: "Minor Repairs & Touch-ups", category: .maintenance, location: .interior, estimatedDuration: 90*60, isWeatherSensitive: false, skillLevel: .intermediate)
            ]
        )

        return WorkerRoute(
            id: id,
            workerId: CanonicalIDs.Workers.luisLopez,
            routeName: name,
            dayOfWeek: day,
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [franklinAM, elizabethAM, afternoon],
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
            sequenceType: .maintenance,
            isFlexible: true,
            dependencies: dependencies
        )
    }
}
