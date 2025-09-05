//
//  NovaGroundingService.swift
//  CyntientOps
//
//  Ground Nova Q&A in app data (routes, routines, DSNY, infra).
//

import Foundation
import CoreLocation

@MainActor
final class NovaGroundingService {
    static let shared = NovaGroundingService()

    private init() {}

    struct GroundingContext {
        let workerId: String
        let now: Date
        let assignedBuildings: [(id: String, name: String)]
    }

    enum Intent {
        case routineForBuilding(String)
        case scheduleForBuilding(String)
        case nextAction
        case dsnyForBuilding(String)
        case binsModeForBuilding(String)
        case buildingInfo(String)
        case unknown
    }

    func ground(query: String, container: ServiceContainer, assignedBuildings: [CoreTypes.NamedCoordinate], defaultWorkerId: String) async -> NovaResponse? {
        let ctx = GroundingContext(
            workerId: defaultWorkerId,
            now: Date(),
            assignedBuildings: assignedBuildings.map { ($0.id, $0.name) }
        )
        let normalized = normalize(query)
        let intent = inferIntent(from: normalized, ctx: ctx)

        switch intent {
        case .routineForBuilding(let bid):
            return await answerRoutines(for: bid, ctx: ctx, container: container)
        case .scheduleForBuilding(let bid):
            return await answerRoutines(for: bid, ctx: ctx, container: container)
        case .nextAction:
            return await answerNextAction(ctx: ctx, container: container)
        case .dsnyForBuilding(let bid):
            return answerDSNY(for: bid)
        case .binsModeForBuilding(let bid):
            return answerBinsMode(for: bid)
        case .buildingInfo(let bid):
            return answerBuildingInfo(for: bid)
        case .unknown:
            // Provide a deterministic generic summary for the worker
            return await answerGenericSummary(ctx: ctx, container: container)
        }
    }

    // MARK: - Intent + Entity Resolution

    private func normalize(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "street", with: "st")
            .replacingOccurrences(of: "west ", with: "w ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func inferIntent(from q: String, ctx: GroundingContext) -> Intent {
        // Resolve building
        if let b = resolveBuildingId(in: q, ctx: ctx) {
            if q.contains("routine") || q.contains("routines") || q.contains("schedule") || q.contains("what do i do") {
                return .routineForBuilding(b)
            }
            if q.contains("dsny") || q.contains("set out") || q.contains("bins") || q.contains("collection") {
                if q.contains("bin") || q.contains("bag") {
                    return .binsModeForBuilding(b)
                }
                return .dsnyForBuilding(b)
            }
            if q.contains("info") || q.contains("address") || q.contains("elevator") || q.contains("notes") {
                return .buildingInfo(b)
            }
            return .scheduleForBuilding(b)
        }
        if q.contains("what's next") || q.contains("whats next") || q.contains("next up") || q.contains("what do i have") || q.contains("my schedule") {
            return .nextAction
        }
        return .unknown
    }

    private func resolveBuildingId(in q: String, ctx: GroundingContext) -> String? {
        // Check assigned buildings first
        for (id, name) in ctx.assignedBuildings {
            let n = normalize(name)
            if q.contains(n) { return id }
        }
        // Common aliases by address fragments
        if q.contains("68 perry") { return CanonicalIDs.Buildings.perry68 }
        if q.contains("131 perry") { return CanonicalIDs.Buildings.perry131 }
        if q.contains("112 w 18") || q.contains("112 west 18") { return CanonicalIDs.Buildings.westEighteenth112 }
        if q.contains("117 w 17") || q.contains("117 west 17") { return CanonicalIDs.Buildings.westSeventeenth117 }
        if q.contains("135") && q.contains("139") && q.contains("17") { return CanonicalIDs.Buildings.westSeventeenth135_139 }
        if q.contains("136") && q.contains("148") && q.contains("17") { return CanonicalIDs.Buildings.rubinMuseum }
        if q.contains("chelsea circuit") || q.contains("17th st complex") || q.contains("17th street complex") { return "17th_street_complex" }
        if q.contains("104 franklin") { return CanonicalIDs.Buildings.franklin104 }
        if q.contains("123 1st") || q.contains("1st ave") { return CanonicalIDs.Buildings.firstAvenue123 }
        if q.contains("178 spring") { return CanonicalIDs.Buildings.springStreet178 }
        return nil
    }

    // MARK: - Answers

    private func answerRoutines(for buildingId: String, ctx: GroundingContext, container: ServiceContainer) async -> NovaResponse? {
        do {
            let instances = try await container.operationalData.getWorkerWeeklySchedule(for: ctx.workerId)
            let df = DateFormatter(); df.dateFormat = "E h:mm a"; df.locale = Locale(identifier: "en_US_POSIX")
            let filtered = instances
                .filter { $0.buildingId == buildingId }
                .sorted { $0.startTime < $1.startTime }
                .prefix(8)
            guard !filtered.isEmpty else {
                let msg = "No upcoming routine instances for this building in the next 7 days."
                return NovaResponse(success: true, message: msg, metadata: ["buildingId": buildingId])
            }
            let lines = filtered.map { inst in
                "• \(df.string(from: inst.startTime)) — \(inst.title)"
            }
            let name = CanonicalIDs.Buildings.getName(for: buildingId) ?? "Building"
            let msg = "Routines for \(name):\n" + lines.joined(separator: "\n")
            return NovaResponse(success: true, message: msg, metadata: ["buildingId": buildingId])
        } catch {
            return NovaResponse(success: false, message: "Couldn’t load routines right now.", metadata: ["error": error.localizedDescription])
        }
    }

    private func answerNextAction(ctx: GroundingContext, container: ServiceContainer) async -> NovaResponse? {
        // Prefer active route sequence, then next upcoming
        if let active = container.routes.getActiveSequences(for: ctx.workerId).first {
            let time = CoreTypes.DateUtils.timeFormatter.string(from: active.arrivalTime)
            let msg = "Now: \(active.buildingName) — \(active.operations.first?.name ?? active.sequenceType.rawValue) at \(time)"
            return NovaResponse(success: true, message: msg, metadata: ["buildingId": active.buildingId])
        }
        if let next = container.routes.getUpcomingSequences(for: ctx.workerId, limit: 1).first {
            let time = CoreTypes.DateUtils.timeFormatter.string(from: next.arrivalTime)
            let msg = "Next: \(next.buildingName) — \(next.operations.first?.name ?? next.sequenceType.rawValue) at \(time)"
            return NovaResponse(success: true, message: msg, metadata: ["buildingId": next.buildingId])
        }
        // Fallback to earliest task from OperationalDataManager
        do {
            let today = try await container.operationalData.getWorkerScheduleForDate(workerId: ctx.workerId, date: ctx.now)
            if let first = today.sorted(by: { $0.startTime < $1.startTime }).first {
                let time = CoreTypes.DateUtils.timeFormatter.string(from: first.startTime)
                let msg = "Next: \(first.buildingName) — \(first.title) at \(time)"
                return NovaResponse(success: true, message: msg, metadata: ["buildingId": first.buildingId])
            }
        } catch { }
        return NovaResponse(success: true, message: "All clear — no pending items.", metadata: [:])
    }

    private func answerDSNY(for buildingId: String) -> NovaResponse? {
        if let sched = DSNYCollectionSchedule.buildingCollectionSchedules[buildingId] {
            let days = sched.collectionDays.map { $0.rawValue }.joined(separator: ", ")
            let setOut = String(format: "%02d:%02d", sched.binSetOutTime.hour, sched.binSetOutTime.minute)
            let pickup = String(format: "%02d:%02d", sched.binRetrievalTime.hour, sched.binRetrievalTime.minute)
            let msg = "DSNY for \(sched.buildingName): \n• Collection Days: \(days)\n• Set-Out: \(setOut)\n• Bring-In: \(pickup)\n• Notes: \(sched.specialInstructions)"
            return NovaResponse(success: true, message: msg, metadata: ["buildingId": buildingId])
        }
        return NovaResponse(success: true, message: "No DSNY schedule on record for this location.", metadata: ["buildingId": buildingId])
    }

    private func answerBinsMode(for buildingId: String) -> NovaResponse? {
        let name = CanonicalIDs.Buildings.getName(for: buildingId) ?? "Building"
        let mode: String
        if BuildingUnitValidator.requiresEmpireContainers(buildingId: buildingId) { mode = "Empire Containers (31+ units)" }
        else if BuildingUnitValidator.canChooseContainerType(buildingId: buildingId) { mode = "Choice: Bins or Empire (10–30 units)" }
        else if BuildingUnitValidator.requiresIndividualBins(buildingId: buildingId) { mode = "Individual Bins (≤9 units)" }
        else { mode = "Black Bags" }
        let msg = "\(name): \(mode)"
        return NovaResponse(success: true, message: msg, metadata: ["buildingId": buildingId])
    }

    private func answerBuildingInfo(for buildingId: String) -> NovaResponse? {
        let name = CanonicalIDs.Buildings.getName(for: buildingId) ?? "Building"
        var lines: [String] = ["Building: \(name)"]
        if let floors = BuildingInfrastructureCatalog.floorCount(for: buildingId) { lines.append("Floors: \(floors)") }
        if let elevators = BuildingInfrastructureCatalog.elevatorCount(for: buildingId) { lines.append("Elevators: \(elevators)") }
        if let notes = BuildingInfrastructureCatalog.notes(for: buildingId) { lines.append("Notes: \(notes)") }
        return NovaResponse(success: true, message: lines.joined(separator: "\n"), metadata: ["buildingId": buildingId])
    }

    private func answerGenericSummary(ctx: GroundingContext, container: ServiceContainer) async -> NovaResponse? {
        // Provide a helpful overview: next action + today’s top 3
        if let next = await answerNextAction(ctx: ctx, container: container) {
            return next
        }
        // If absolutely nothing, summarize assigned buildings
        let buildings = ctx.assignedBuildings.map { "• \($0.1)" }.joined(separator: "\n")
        return NovaResponse(success: true, message: "Assigned Buildings:\n\(buildings)", metadata: [:])
    }
}

