//
//  FixtureSeeder.swift
//  CyntientOps
//
//  Deterministic seeding for local/sim runs. Use to quickly get a stable snapshot.

import Foundation
import CoreLocation

public enum FixtureSeeder {
    /// Seed a deterministic dataset and freeze time/location for reproducibility
    public static func seedAll() async {
        do {
            // Initialize DB if needed
            try await DatabaseInitializer.shared.initializeIfNeeded()

            // Freeze to a standard day/time: Thu 06:50 local
            if let frozen = Self.thursdayAt(hour: 6, minute: 50) {
                AppClock.freeze(frozen)
                print("🕒 AppClock frozen at: \(frozen)")
            }

            // Set debug location to Chelsea center
            #if DEBUG
            LocationManager.shared.setDebugLocation(latitude: 40.7450, longitude: -73.9965)
            #endif

            // Ensure core data is present (DatabaseInitializer seeds buildings, users, assignments, tasks)
            // Idempotent upserts for route schedules using stable IDs
            await RoutesUpserter.ensureCoreSchedules()

            print("✅ FixtureSeeder.seedAll completed deterministically")
        } catch {
            print("❌ FixtureSeeder.seedAll failed: \(error)")
        }
    }

    private static func thursdayAt(hour: Int, minute: Int) -> Date? {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        // Walk backward to last Thursday
        let today = Date()
        let weekday = cal.component(.weekday, from: today) // 1=Sun ... 5=Thu
        let delta = ((weekday + 7) - 5) % 7 // distance back to Thu
        if let base = cal.date(byAdding: .day, value: -delta, to: today),
           let anchor = cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) {
            comps.year = cal.component(.year, from: anchor)
            comps.month = cal.component(.month, from: anchor)
            comps.day = cal.component(.day, from: anchor)
            comps.hour = hour
            comps.minute = minute
            comps.second = 0
            return cal.date(from: comps)
        }
        return nil
    }
}

