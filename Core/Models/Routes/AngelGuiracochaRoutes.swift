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
        let collectionDay = CollectionDay.from(weekday: day)

        // Align DSNY set-out with 8:00 PM rule (not before 8:00 PM)
        let setout = sequence(
            seqId: "angel_setout_\(day)",
            buildingId: CanonicalIDs.Buildings.westEighteenth12,
            buildingName: "12 West 18th Street",
            hour: 20, minute: 0,
            ops: [
                OperationTask(id: "w18_stage_bins", name: "Stage Bins for Collection", category: .dsnySetout, location: .curbside, estimatedDuration: 45*60, isWeatherSensitive: true, skillLevel: .basic, instructions: "Follow DSNY schedule for the day"),
                OperationTask(id: "w18_cardboard", name: "Cardboard Break-down", category: .trashCollection, location: .trashArea, estimatedDuration: 20*60, isWeatherSensitive: true, skillLevel: .basic)
            ]
        )

        // Offsite garbage removal (not left curbside) for Perry corridor
        let perry68Offsite = sequence(
            seqId: "angel_perry68_offsite_\(day)",
            buildingId: CanonicalIDs.Buildings.perry68,
            buildingName: "68 Perry Street",
            hour: 21, minute: 0,
            ops: [
                OperationTask(
                    id: "perry68_garbage_offsite_\(day)",
                    name: "Offsite Garbage Removal - 68 Perry",
                    category: .trashCollection,
                    location: .hallway,
                    estimatedDuration: 15*60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "Collect and remove garbage for offsite disposal. Do not leave outside."
                )
            ]
        )
        let perry131Offsite = sequence(
            seqId: "angel_perry131_offsite_\(day)",
            buildingId: CanonicalIDs.Buildings.perry131,
            buildingName: "131 Perry Street",
            hour: 21, minute: 20,
            ops: [
                OperationTask(
                    id: "perry131_garbage_offsite_\(day)",
                    name: "Offsite Garbage Removal - 131 Perry",
                    category: .trashCollection,
                    location: .hallway,
                    estimatedDuration: 15*60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "Collect and remove garbage for offsite disposal. Do not leave outside."
                )
            ]
        )

        // Franklin 104 offsite garbage removal (Floors 2 & 4)
        var franklinRemoval: RouteSequence? = nil
        if [2,4,6].contains(day) { // Mon, Wed, Fri
            franklinRemoval = sequence(
                seqId: "angel_franklin104_garbage_\(day)",
                buildingId: CanonicalIDs.Buildings.franklin104,
                buildingName: "104 Franklin Street",
                hour: 20, minute: 35,
                ops: [
                    OperationTask(
                        id: "frk104_garbage_offsite_\(day)",
                        name: "Offsite Garbage Removal - 104 Franklin (Floors 2 & 4)",
                        category: .trashCollection,
                        location: .hallway,
                        estimatedDuration: 25*60,
                        isWeatherSensitive: false,
                        skillLevel: .basic,
                        instructions: "Collect from floors 2 and 4, transport for offsite disposal. Do not leave outside."
                    )
                ]
            )
        }

        let sweep = sequence(
            seqId: "angel_sweep_\(day)",
            buildingId: CanonicalIDs.Buildings.westEighteenth12,
            buildingName: "12 West 18th Street",
            hour: 21, minute: 40,
            ops: [
                OperationTask(id: "w18_sidewalk_sweep", name: "Sidewalk Sweep", category: .sweeping, location: .sidewalk, estimatedDuration: 30*60, isWeatherSensitive: true, skillLevel: .basic)
            ],
            dependencies: [setout.id]
        )

        let wrap = sequence(
            seqId: "angel_wrap_\(day)",
            buildingId: CanonicalIDs.Buildings.westEighteenth12,
            buildingName: "12 West 18th Street",
            hour: 22, minute: 10,
            ops: [
                OperationTask(id: "w18_checklist", name: "End-of-Shift Checklist", category: .maintenance, location: .hallway, estimatedDuration: 30*60, isWeatherSensitive: false, skillLevel: .basic)
            ]
        )

        var seqs: [RouteSequence] = [setout]
        if let f = franklinRemoval { seqs.append(f) }
        seqs.append(perry68Offsite)
        seqs.append(perry131Offsite)
        seqs.append(sweep)
        seqs.append(wrap)

        return WorkerRoute(
            id: id,
            workerId: CanonicalIDs.Workers.angelGuirachocha,
            routeName: name,
            dayOfWeek: day,
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: seqs,
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
