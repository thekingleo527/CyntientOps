//
//  AngelGuiracochaRoutes.swift
//  CyntientOps
//
//  Angel Guiracocha — evening DSNY setout and bin management at 12 W 18th
//

import Foundation

public struct AngelGuiracochaRoutes {
    public static func getWeeklyRoutes() -> [WorkerRoute] {
        [mon(), tue(), wed(), thu(), fri()]
    }

    private static func mon() -> WorkerRoute { daily("angel_mon", name: "Angel Monday", day: 2) }
    private static func tue() -> WorkerRoute { daily("angel_tue", name: "Angel Tuesday", day: 3) }
    private static func wed() -> WorkerRoute { daily("angel_wed", name: "Angel Wednesday", day: 4) }
    private static func thu() -> WorkerRoute { daily("angel_thu", name: "Angel Thursday", day: 5) }
    private static func fri() -> WorkerRoute { daily("angel_fri", name: "Angel Friday", day: 6) }

    private static func daily(_ id: String, name: String, day: Int) -> WorkerRoute {
        let startTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()

        let setout = sequence(
            seqId: "angel_setout_\(day)",
            buildingId: CanonicalIDs.Buildings.westEighteenth12,
            buildingName: "12 West 18th Street",
            hour: 18, minute: 0,
            ops: [
                OperationTask(id: "w18_stage_bins", name: "Stage Bins for Collection", category: .dsnySetout, location: .curbside, estimatedDuration: 45*60, isWeatherSensitive: true, skillLevel: .basic, instructions: "Follow DSNY schedule for the day"),
                OperationTask(id: "w18_cardboard", name: "Cardboard Break-down", category: .trashCollection, location: .trashArea, estimatedDuration: 20*60, isWeatherSensitive: true, skillLevel: .basic)
            ]
        )

        let sweep = sequence(
            seqId: "angel_sweep_\(day)",
            buildingId: CanonicalIDs.Buildings.westEighteenth12,
            buildingName: "12 West 18th Street",
            hour: 19, minute: 15,
            ops: [
                OperationTask(id: "w18_sidewalk_sweep", name: "Sidewalk Sweep", category: .sweeping, location: .sidewalk, estimatedDuration: 30*60, isWeatherSensitive: true, skillLevel: .basic)
            ],
            dependencies: [setout.id]
        )

        let wrap = sequence(
            seqId: "angel_wrap_\(day)",
            buildingId: CanonicalIDs.Buildings.westEighteenth12,
            buildingName: "12 West 18th Street",
            hour: 21, minute: 0,
            ops: [
                OperationTask(id: "w18_checklist", name: "End-of-Shift Checklist", category: .maintenance, location: .hallway, estimatedDuration: 30*60, isWeatherSensitive: false, skillLevel: .basic)
            ]
        )

        return WorkerRoute(
            id: id,
            workerId: CanonicalIDs.Workers.angelGuirachocha,
            routeName: name,
            dayOfWeek: day,
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [setout, sweep, wrap],
            routeType: .eveningOperations
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
            sequenceType: .sanitation,
            isFlexible: true,
            dependencies: dependencies
        )
    }
}
