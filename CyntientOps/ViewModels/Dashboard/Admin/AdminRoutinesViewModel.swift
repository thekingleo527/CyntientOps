
//
//  AdminRoutinesViewModel.swift
//  CyntientOps
//
//  Created by Gemini on 2025-09-08.
//

import Foundation
import Combine

@MainActor
final class AdminRoutinesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var routines: [WorkerRoutine] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let routeManager: RouteManager
    private let workerService: WorkerService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        routeManager: RouteManager = .shared,
        workerService: WorkerService
    ) {
        self.routeManager = routeManager
        self.workerService = workerService
    }
    
    // MARK: - Public Methods
    
    func loadRoutines() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let workers = try await workerService.getAllActiveWorkers()
            var routines: [WorkerRoutine] = []
            
            for worker in workers {
                if let route = routeManager.getCurrentRoute(for: worker.id) {
                    routines.append(WorkerRoutine(workerId: worker.id, workerName: worker.name, route: route))
                }
            }
            
            self.routines = routines
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    func computeLookahead(limit: Int = 2) async -> [RouteItem] {
        let workers: [CoreTypes.WorkerProfile]
        do {
            workers = try await workerService.getAllActiveWorkers()
        } catch {
            return []
        }

        let calendar = Calendar.current
        let now = Date()
        var items: [RouteItem] = []

        // 1) Today’s remaining items across workers
        for w in workers {
            let todays = routeManager.today(for: w.id, date: now)
            let upcoming = todays.filter { item in
                // Keep future items; RouteItem.time is "HH:mm–HH:mm"
                let startStr = item.time.split(separator: "–").first.map(String.init) ?? ""
                let df = DateFormatter(); df.dateFormat = "HH:mm"
                if let startClock = df.date(from: startStr) {
                    var comps = calendar.dateComponents([.year, .month, .day], from: now)
                    let hh = calendar.component(.hour, from: startClock)
                    let mm = calendar.component(.minute, from: startClock)
                    comps.hour = hh
                    comps.minute = mm
                    let scheduled = calendar.date(from: comps) ?? now
                    return scheduled >= now
                }
                return true
            }
            if let first = upcoming.first { items.append(first) }
        }

        // 2) DSNY set‑out look‑ahead after 7pm on set‑out days (Su/Tu/Th)
        let weekday = calendar.component(.weekday, from: now) // 1=Sun
        let hour = calendar.component(.hour, from: now)
        let todayDay = DSNYCollectionSchedule.CollectionDay.from(weekday: weekday)
        let dsnySetoutDays: Set<DSNYCollectionSchedule.CollectionDay> = [.sunday, .tuesday, .thursday]
        if hour >= 19 && dsnySetoutDays.contains(todayDay) {
            let setoutBuildings = DSNYCollectionSchedule.getBuildingsForBinSetOut(on: todayDay)
            if !setoutBuildings.isEmpty {
                // Compose a single summary item at 20:00–21:00
                if let start = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now),
                   let end = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now) {
                    let timeStr = formatTimeRange(start: start, end: end)
                    let caption: String
                    if setoutBuildings.count == 1 {
                        caption = "DSNY Set Out — \(setoutBuildings.first!.buildingName)"
                    } else {
                        caption = "DSNY Set Out — \(setoutBuildings.count) buildings"
                    }
                    items.append(RouteItem(
                        id: "dsny_setout_\(todayDay.rawValue.lowercased())_\(Int(start.timeIntervalSince1970))",
                        buildingName: caption,
                        buildingId: nil,
                        time: timeStr,
                        icon: "trash.circle",
                        isActive: false
                    ))
                }
            }
        }

        // 3) Next morning’s first routine across portfolio
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            let nextWeekday = calendar.component(.weekday, from: tomorrow)
            var earliest: (time: Date, item: RouteItem)? = nil
            for w in workers {
                if let route = routeManager.getRoute(for: w.id, dayOfWeek: nextWeekday) {
                    // Earliest sequence start
                    if let firstSeq = route.sequences.sorted(by: { $0.arrivalTime < $1.arrivalTime }).first,
                       let op = firstSeq.operations.first {
                        let item = RouteItem(
                            id: "next_day_\(route.id)_\(firstSeq.id)",
                            buildingName: op.name,
                            buildingId: firstSeq.buildingId,
                            time: formatTimeRange(start: firstSeq.arrivalTime, end: firstSeq.arrivalTime.addingTimeInterval(firstSeq.estimatedDuration)),
                            icon: "calendar",
                            isActive: false,
                            dayOfWeek: nextWeekday
                        )
                        if earliest == nil || firstSeq.arrivalTime < earliest!.time {
                            earliest = (firstSeq.arrivalTime, item)
                        }
                    }
                }
            }
            if let e = earliest { items.append(e.item) }
        }

        // Sort and limit
        return items
            .sorted { $0.time < $1.time }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Helpers
    private func formatTimeRange(start: Date, end: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "HH:mm"
        return "\(df.string(from: start))–\(df.string(from: end))"
    }
    
    // MARK: - Supporting Types
    
    struct WorkerRoutine {
        let workerId: String
        let workerName: String
        let route: WorkerRoute
    }
}
