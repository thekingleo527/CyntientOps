//
//  ImportHelper.swift
//  CyntientOps v6.0
//
//  🔧 COMPILATION FIX: Comprehensive import helper
//  ✅ Ensures all components can find each other
//

import Foundation
import SwiftUI
import Combine

// MARK: - Core Framework Imports
@_exported import Foundation
@_exported import SwiftUI
@_exported import Combine

// MARK: - Type Availability Check
public enum CyntientOpsTypes {
    public static func validateImports() -> Bool {
        // Validate that all core types are available
        let _ = WorkerContextEngineAdapter.self
        let _ = ContextualTask.self
        let _ = MaintenanceTask.self
        let _ = CoreTypes.WorkerProfile.self
        let _ = TaskUrgency.self
        let _ = TaskCategory.self
        return true
    }
}
