//
//  RoutesUpserter.swift
//  CyntientOps
//
//  Idempotent upsert helpers for routine schedules using stable IDs

import Foundation

public enum RoutesUpserter {
    /// Upsert a routine schedule row with a stable ID (routine_<buildingId>_<workerId>_<hash>)
    public static func upsertRoutine(workerId: String, buildingId: String, rrule: String, title: String, startHour: Int, durationMinutes: Int) async {
        let stable = stableId(workerId: workerId, buildingId: buildingId, rrule: rrule)
        let sql = """
            INSERT INTO routine_schedules
            (id, worker_id, building_id, title, rrule, start_hour, duration_minutes, is_active)
            VALUES (?, ?, ?, ?, ?, ?, ?, 1)
            ON CONFLICT(id) DO UPDATE SET
                title = excluded.title,
                rrule = excluded.rrule,
                start_hour = excluded.start_hour,
                duration_minutes = excluded.duration_minutes,
                is_active = 1
        """
        do {
            try await GRDBManager.shared.execute(sql, [stable, workerId, buildingId, title, rrule, startHour, durationMinutes])
        } catch {
            print("⚠️ RoutesUpserter.upsertRoutine failed: \(error)")
        }
    }

    /// Seed a minimal core schedule set idempotently (Kevin Chelsea AM block etc.)
    public static func ensureCoreSchedules() async {
        // Kevin (4): Chelsea Circuit 9:00-11:30, Tue/Thu/Sat
        let kevin = "4"
        let chelseaIds = [
            CanonicalIDs.Buildings.westSeventeenth117,
            CanonicalIDs.Buildings.westSeventeenth135_139,
            CanonicalIDs.Buildings.westSeventeenth136,
            CanonicalIDs.Buildings.westSeventeenth138,
            CanonicalIDs.Buildings.westEighteenth112,
            CanonicalIDs.Buildings.rubinMuseum
        ]
        let rrule = "FREQ=WEEKLY;BYDAY=TU,TH,SA;BYHOUR=9"
        for bid in chelseaIds {
            await upsertRoutine(workerId: kevin, buildingId: bid, rrule: rrule, title: "Chelsea Circuit", startHour: 9, durationMinutes: 150)
        }
    }

    private static func stableId(workerId: String, buildingId: String, rrule: String) -> String {
        let base = "routine_\(buildingId)_\(workerId)_\(rrule)"
        let hash = String(base.hashValue)
        return "routine_\(buildingId)_\(workerId)_\(hash)"
    }
}

