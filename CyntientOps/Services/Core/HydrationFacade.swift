//
//  HydrationFacade.swift
//  CyntientOps
//
//  Unifies hydration of worker and building views from route + legacy sources
//  Also injects accurate DSNY Chelsea Circuit evening set-out timing (staggered).
//

import Foundation

@MainActor
public struct HydrationFacade {
    let container: ServiceContainer

    public init(container: ServiceContainer) {
        self.container = container
    }

    // MARK: - Client Portfolio (Route-derived)
    /// Returns route-derived contextual tasks and scheduled workers for a client's portfolio for today
    public func getClientPortfolioToday(clientId: String) async throws -> (tasks: [CoreTypes.ContextualTask], workerIds: [String]) {
        let buildings = try await container.client.getBuildingsForClient(clientId)
        let buildingIds = Set(buildings.map { $0.id })
        let routes = container.routes
        let allRoutes = routes.routes
        let todayWeekday = Calendar.current.component(.weekday, from: Date())

        var tasks: [CoreTypes.ContextualTask] = []
        var workerIds: Set<String> = []

        // For each worker route today, convert to contextual tasks and filter by client's buildings
        let workersToday = Set(allRoutes.filter { $0.dayOfWeek == todayWeekday }.map { $0.workerId })
        for wid in workersToday {
            let contextual = container.routeBridge.convertSequencesToContextualTasks(for: wid)
            let filtered = contextual.filter { task in
                guard let bid = task.buildingId else { return false }
                return buildingIds.contains(bid)
            }
            if !filtered.isEmpty { workerIds.insert(wid) }
            tasks.append(contentsOf: filtered)
        }

        // Also include DSNY set-out contextual tasks for those buildings (tonight) when scheduled
        for bid in buildingIds {
            let dsny = getDSNYSetOutContextualTasksForBuilding(buildingId: bid, date: Date())
            tasks.append(contentsOf: dsny)
        }

        // Deduplicate by (id) and sort by dueDate
        var seen = Set<String>()
        let unique = tasks.filter { t in
            if seen.contains(t.id) { return false }
            seen.insert(t.id); return true
        }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }

        return (unique, Array(workerIds))
    }

    // MARK: - DSNY Chelsea Circuit Set-Out (Worker)
    /// Generates staggered evening DSNY set-out tasks for the Chelsea Corridor, filtered by scheduled buildings.
    public func getDSNYSetOutTasksForWorker(workerId: String, date: Date = Date()) -> [WorkerDashboardViewModel.TaskItem] {
        // Determine which worker is assigned to set-out for this corridor on this date
        let assigned = chelseaSetOutAssignedWorker(for: date)
        guard workerId == assigned else { return [] }

        let day = CollectionDay.from(weekday: Calendar.current.component(.weekday, from: date))
        let todays = DSNYScheduleProvider.shared.getBuildingsForSetOutAll(on: day).map { $0.buildingId }
        let corridorIds: Set<String> = [
            CanonicalIDs.Buildings.westSeventeenth117,
            CanonicalIDs.Buildings.westSeventeenth135_139,
            CanonicalIDs.Buildings.westSeventeenth136,
            CanonicalIDs.Buildings.westSeventeenth138,
            CanonicalIDs.Buildings.rubinMuseum,
            CanonicalIDs.Buildings.westEighteenth112
        ]
        let eligible = chelseaStaggeredSetOutPlan(on: date).filter { todays.contains($0.buildingId) && corridorIds.contains($0.buildingId) }

        return eligible.map { p in
            WorkerDashboardViewModel.TaskItem(
                id: "dsny_setout_\(p.buildingId)_\(Int(p.time.timeIntervalSince1970))",
                title: "DSNY Set Out — \(CanonicalIDs.Buildings.getName(for: p.buildingId) ?? p.buildingName)",
                description: {
                    let streams = DSNYScheduleProvider.shared.getWasteStreams(for: p.buildingId, on: day)
                    let text = streams.isEmpty ? "Trash" : streams.map { $0.rawValue }.joined(separator: ", ")
                    return "Set out: \(text) (\(Int(p.duration/60)) min)"
                }(),
                buildingId: p.buildingId,
                dueDate: p.time,
                urgency: .urgent,
                isCompleted: false,
                category: "Sanitation",
                requiresPhoto: false
            )
        }
    }

    // NOTE: Additional per-building DSNY scheduling should come from DSNYCollectionSchedule.

    // MARK: - DSNY Chelsea Circuit Set-Out (Building)
    /// Generates DSNY set-out contextual tasks for a specific building on Chelsea Circuit.
    public func getDSNYSetOutContextualTasksForBuilding(buildingId: String, date: Date = Date()) -> [CoreTypes.ContextualTask] {
        // Only generate tasks when the building is scheduled for set-out per DSNYCollectionSchedule
        let today = CollectionDay.from(weekday: Calendar.current.component(.weekday, from: date))
        let scheduled = DSNYScheduleProvider.shared.getBuildingsForSetOutAll(on: today).map { $0.buildingId }
        guard scheduled.contains(buildingId) else { return [] }

        // If part of the Chelsea corridor, align with the staggered plan
        let plan = chelseaStaggeredSetOutPlan(on: date).filter { $0.buildingId == buildingId }
        return plan.map { p in
            CoreTypes.ContextualTask(
                id: "dsny_setout_ctx_\(p.buildingId)_\(Int(p.time.timeIntervalSince1970))",
                title: "DSNY Set Out — \(p.buildingName)",
                description: {
                    let streams = DSNYScheduleProvider.shared.getWasteStreams(for: p.buildingId, on: today)
                    let text = streams.isEmpty ? "Trash" : streams.map { $0.rawValue }.joined(separator: ", ")
                    return "Set out: \(text) (\(Int(p.duration/60)) min)"
                }(),
                status: .pending,
                dueDate: p.time,
                category: .sanitation,
                urgency: .urgent,
                building: nil,
                worker: nil,
                buildingId: p.buildingId,
                buildingName: p.buildingName,
                assignedWorkerId: chelseaSetOutAssignedWorker(for: date),
                requiresPhoto: false,
                estimatedDuration: p.duration
            )
        }
    }

    // MARK: - Internal Staggered Plan
    /// Returns a realistic staggered plan for Chelsea Circuit set-out:
    /// - Staging begins ~19:30
    /// - Set-out begins ~19:50–20:00
    /// - 15–20 minutes per building
    /// - Finished by ~22:00
    private func chelseaStaggeredSetOutPlan(on date: Date) -> [(buildingId: String, buildingName: String, time: Date, duration: TimeInterval)] {
        let cal = Calendar.current
        // Base times
        let setOutStart = cal.date(bySettingHour: 19, minute: 50, second: 0, of: date) ?? date

        // Target buildings and order (West 17th corridor + 112 W 18th)
        let ordered: [(id: String, name: String)] = [
            (CanonicalIDs.Buildings.westSeventeenth117, CanonicalIDs.Buildings.getName(for: CanonicalIDs.Buildings.westSeventeenth117) ?? "117 W 17th"),
            (CanonicalIDs.Buildings.westSeventeenth135_139, CanonicalIDs.Buildings.getName(for: CanonicalIDs.Buildings.westSeventeenth135_139) ?? "135–139 W 17th"),
            (CanonicalIDs.Buildings.westSeventeenth136, CanonicalIDs.Buildings.getName(for: CanonicalIDs.Buildings.westSeventeenth136) ?? "136 W 17th"),
            (CanonicalIDs.Buildings.westSeventeenth138, CanonicalIDs.Buildings.getName(for: CanonicalIDs.Buildings.westSeventeenth138) ?? "138 W 17th"),
            // Rubin museum complex represents 142–148 walkups
            (CanonicalIDs.Buildings.rubinMuseum, CanonicalIDs.Buildings.getName(for: CanonicalIDs.Buildings.rubinMuseum) ?? "142–148 W 17th"),
            (CanonicalIDs.Buildings.westEighteenth112, CanonicalIDs.Buildings.getName(for: CanonicalIDs.Buildings.westEighteenth112) ?? "112 W 18th")
        ]

        var current = setOutStart
        var plan: [(String, String, Date, TimeInterval)] = []
        // Alternate 15 and 20 minutes to reflect variability
        let durations: [TimeInterval] = [15 * 60, 20 * 60]
        var i = 0
        for entry in ordered {
            let dur = durations[i % durations.count]
            plan.append((entry.id, entry.name, current, dur))
            current = current.addingTimeInterval(dur)
            i += 1
        }

        // Clamp any overflow past 22:00 by compressing last slot into 22:00 if necessary
        let cutoff = cal.date(bySettingHour: 22, minute: 0, second: 0, of: date) ?? date
        if let last = plan.last, last.2 > cutoff {
            plan[plan.count - 1] = (last.0, last.1, cutoff, last.3)
        }
        return plan
    }

    /// Decide who performs Chelsea corridor evening set-out on a given date.
    /// Defaults:
    /// - Sunday, Tuesday, Thursday → Kevin (per known corridor pattern)
    /// - Wednesday → Angel (covers evening garbage per ops note)
    /// - Other days → no assignment (return empty string)
    private func chelseaSetOutAssignedWorker(for date: Date) -> String {
        let day = CollectionDay.from(weekday: Calendar.current.component(.weekday, from: date))
        switch day {
        case .sunday, .tuesday, .thursday:
            return CanonicalIDs.Workers.kevinDutan
        case .wednesday:
            return CanonicalIDs.Workers.angelGuirachocha
        default:
            return ""
        }
    }

    // MARK: - Morning Retrieval (Worker)
    /// Generate morning retrieval tasks for a worker based on provider schedule and assignment rules
    public func getMorningRetrievalTasksForWorker(workerId: String, date: Date = Date()) -> [WorkerDashboardViewModel.TaskItem] {
        let cal = Calendar.current
        let today = CollectionDay.from(weekday: cal.component(.weekday, from: date))
        let yesterday = today.previousDay()

        // Buildings that set out yesterday are collected today
        let setOutYesterday = DSNYScheduleProvider.shared.getBuildingsForSetOutAll(on: yesterday)

        var items: [WorkerDashboardViewModel.TaskItem] = []
        for sched in setOutYesterday {
            let bid = sched.buildingId
            guard retrievalAssignedWorker(for: bid, on: today) == workerId else { continue }

            let due = sched.retrievalTime.map { t in
                cal.date(bySettingHour: t.hour, minute: t.minute, second: 0, of: date) ?? date
            } ?? cal.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date

            let title = "DSNY Bring In — \(sched.buildingName)"
            let id = "dsny_retrieval_\(bid)_\(Int(due.timeIntervalSince1970))"
            items.append(WorkerDashboardViewModel.TaskItem(
                id: id,
                title: title,
                description: "Bring bins/bags inside after collection",
                buildingId: bid,
                dueDate: due,
                urgency: .high,
                isCompleted: false,
                category: "Sanitation",
                requiresPhoto: false
            ))
        }

        return items.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private func retrievalAssignedWorker(for buildingId: String, on day: CollectionDay) -> String {
        // Retrieval is the morning after set-out.
        switch buildingId {
        case CanonicalIDs.Buildings.perry68:
            // Saturday retrieval at 68 Perry handled by Shawn; other retrievals by Kevin
            return day == .saturday ? CanonicalIDs.Workers.shawnMagloire : CanonicalIDs.Workers.kevinDutan
        case CanonicalIDs.Buildings.firstAvenue123,
             CanonicalIDs.Buildings.springStreet178,
             CanonicalIDs.Buildings.chambers148:
            return CanonicalIDs.Workers.edwinLema
        default:
            return ""
        }
    }
}
