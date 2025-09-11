//
//  DSNYScheduleProvider.swift
//  CyntientOps
//
//  Bridges DSNY API live schedules with local fallbacks.
//  Provides unified queries for set-out schedules used by hydration.
//

import Foundation

@MainActor
public final class DSNYScheduleProvider: ObservableObject {
    public static let shared = DSNYScheduleProvider()

    @Published private var overrides: [String: GeneralSetOutSchedule] = [:] // buildingId -> schedule

    private init() {}

    // MARK: - Public Queries

    public func getBuildingsForSetOutAll(on day: CollectionDay) -> [GeneralSetOutSchedule] {
        // Merge live overrides with static defaults; live overrides take precedence
        let base = DSNYCollectionSchedule.allSetOutSchedules
        var merged: [String: GeneralSetOutSchedule] = base
        for (bid, sched) in overrides { merged[bid] = sched }
        return merged.values.filter { $0.setOutByDay.keys.contains(day) }
            .sorted { $0.buildingName < $1.buildingName }
    }

    public func getWasteStreams(for buildingId: String, on day: CollectionDay) -> [WasteType] {
        if let s = overrides[buildingId]?.setOutByDay[day] { return s }
        return DSNYCollectionSchedule.allSetOutSchedules[buildingId]?.setOutByDay[day] ?? []
    }

    public func hasOverride(for buildingId: String) -> Bool {
        return overrides[buildingId] != nil
    }

    // MARK: - Live Refresh (best-effort)

    /// Refresh schedules for the given buildings using DSNY API.
    /// If DSNY API is unavailable or returns no data, keeps existing schedules.
    public func refresh(for buildings: [CoreTypes.NamedCoordinate]) async {
        do {
            // Use existing DSNYAPIService to batch fetch schedules
            let service = DSNYAPIService.shared
            let schedules = try await service.getSchedules(for: buildings)
            var newOverrides: [String: GeneralSetOutSchedule] = [:]

            for (buildingId, dsny) in schedules {
                // Map DSNY schedule into GeneralSetOutSchedule
                var map: [CollectionDay: [WasteType]] = [:]
                for day in [CollectionDay.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday] {
                    var streams: [WasteType] = []
                    // Map DSNY.CollectionType to WasteType
                    for ct in DSNY.CollectionType.allCases {
                        if dsny.isCollectionDay(for: ct, on: day) {
                            switch ct {
                            case .trash: streams.append(.trash)
                            case .recycling: streams.append(.recycling)
                            case .compost: streams.append(.compost)
                            default: break
                            }
                        }
                    }
                    if !streams.isEmpty { map[day] = streams }
                }

                // Choose set-out and retrieval default times; DSNY has compliance windows but we use 8 PM by default here
                let sched = GeneralSetOutSchedule(
                    buildingId: buildingId,
                    buildingName: CanonicalIDs.Buildings.getName(for: buildingId) ?? buildingId,
                    setOutByDay: map,
                    setOutTime: DSNYTime(hour: 20, minute: 0),
                    retrievalTime: DSNYTime(hour: 9, minute: 0),
                    containerType: inferContainerType(for: buildingId),
                    unitCount: BuildingInfrastructureCatalog.unitCount(for: buildingId) ?? 0
                )
                newOverrides[buildingId] = sched
            }

            self.overrides.merge(newOverrides) { _, new in new }
        } catch {
            // Best-effort: keep existing schedules; log once
            print("⚠️ DSNYScheduleProvider: Live refresh failed: \(error)")
        }
    }

    // MARK: - Helpers

    private func inferContainerType(for buildingId: String) -> ContainerType {
        let units = BuildingInfrastructureCatalog.unitCount(for: buildingId) ?? 0
        return units <= DSNYCollectionSchedule.individualBinMaxUnits ? .blackBin : .blackBags
    }
}
