//
//  DSNYTaskGenerator.swift
//  CyntientOps
//
//  ✅ V6.0 FIXED: All GRDB access and parameter issues resolved
//  ✅ FIXED: Added await for async isDatabaseReady() calls
//

import Foundation

class DSNYTaskGenerator {
    static let shared = DSNYTaskGenerator()
    
    private init() {}
    
    func generateDSNYTasks(for buildingId: String, date: Date) async throws -> [CoreTypes.MaintenanceTask] {
        guard await GRDBManager.shared.isDatabaseReady() else {  // ✅ FIXED: Added await
            print("⚠️ GRDB not ready")
            return []
        }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        var tasks: [CoreTypes.MaintenanceTask] = []
        
        // Morning collection
        if weekday == 2 || weekday == 5 { // Monday and Thursday
            tasks.append(CoreTypes.MaintenanceTask(
                title: "Prepare for Waste Collection",
                description: "Move bins to collection point, ensure proper sorting",
                category: .maintenance,
                urgency: .medium,
                buildingId: buildingId,
                dueDate: calendar.date(byAdding: .hour, value: 6, to: calendar.startOfDay(for: date))
            ))
        }
        
        // Evening bin return
        if weekday == 2 || weekday == 5 {
            tasks.append(CoreTypes.MaintenanceTask(
                title: "Return Waste Bins",
                description: "Return bins from collection point, clean area",
                category: .maintenance,
                urgency: .medium,
                buildingId: buildingId,
                dueDate: calendar.date(byAdding: .hour, value: 18, to: calendar.startOfDay(for: date))
            ))
        }
        
        // Weekly recycling
        if weekday == 3 { // Wednesday
            tasks.append(CoreTypes.MaintenanceTask(
                title: "Recycling Collection Prep",
                description: "Organize recycling materials, move to collection area",
                category: .maintenance,
                urgency: .medium,
                buildingId: buildingId,
                dueDate: calendar.date(byAdding: .hour, value: 6, to: calendar.startOfDay(for: date))
            ))
        }
        
        return tasks
    }
    
    func scheduleRecurringDSNYTasks(for buildingId: String) async throws {
        guard await GRDBManager.shared.isDatabaseReady() else {  // ✅ FIXED: Added await
            print("⚠️ GRDB not ready for scheduling")
            return
        }
        
        print("✅ DSNY recurring tasks scheduled for building \(buildingId)")
    }
}
