//
//  TestMigrationFlow.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 7/30/25.
//


//
//  TestMigrationFlow.swift
//  CyntientOps v6.0
//
//  ✅ TESTING: Helper to test migration flow
//

import SwiftUI

struct TestMigrationFlow: View {
    @StateObject private var dailyOps = DailyOpsReset.shared
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Migration Status") {
                    HStack {
                        Text("Needs Migration")
                        Spacer()
                        Text(dailyOps.needsMigration() ? "Yes" : "No")
                            .foregroundColor(dailyOps.needsMigration() ? .red : .green)
                            .fontWeight(.semibold)
                    }
                    
                    if dailyOps.isMigrating {
                        HStack {
                            Text("Progress")
                            Spacer()
                            Text("\(Int(dailyOps.migrationProgress * 100))%")
                        }
                        
                        HStack {
                            Text("Current Step")
                            Spacer()
                            Text("\(dailyOps.currentStep) of \(dailyOps.totalSteps)")
                        }
                        
                        HStack {
                            Text("Status")
                            Spacer()
                            Text(dailyOps.migrationStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Migration Controls") {
                    Button(action: {
                        Task {
                            try await dailyOps.performOneTimeMigration()
                        }
                    }) {
                        Label("Start Migration", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(dailyOps.isMigrating || !dailyOps.needsMigration())
                    
                    Button(action: {
                        showingResetConfirmation = true
                    }) {
                        Label("Reset Migration Status", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .disabled(dailyOps.isMigrating)
                }
                
                Section("Quick Tests") {
                    Button("Test Migration View") {
                        openMigrationView()
                    }
                    
                    Button("Simulate Migration Error") {
                        simulateError()
                    }
                    
                    Button("Check Database Tables") {
                        checkDatabaseTables()
                    }
                }
                
                Section("Migration Keys") {
                    ForEach(migrationKeys, id: \.key) { item in
                        HStack {
                            Text(item.key)
                                .font(.caption)
                            Spacer()
                            Image(systemName: item.value ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(item.value ? .green : .gray)
                        }
                    }
                }
            }
            .navigationTitle("Migration Testing")
            .alert("Reset Migration?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetMigrationStatus()
                }
            } message: {
                Text("This will clear all migration flags and allow you to run the migration again. Use only for testing.")
            }
        }
    }
    
    private var migrationKeys: [(key: String, value: Bool)] {
        [
            ("Workers Imported", UserDefaults.standard.bool(forKey: "hasImportedWorkers_v1")),
            ("Buildings Imported", UserDefaults.standard.bool(forKey: "hasImportedBuildings_v1")),
            ("Templates Created", UserDefaults.standard.bool(forKey: "hasImportedTemplates_v1")),
            ("Assignments Created", UserDefaults.standard.bool(forKey: "hasCreatedAssignments_v1")),
            ("Capabilities Setup", UserDefaults.standard.bool(forKey: "hasSetupCapabilities_v1"))
        ]
    }
    
    private func openMigrationView() {
        let migrationView = MigrationView()
        let hostingController = UIHostingController(rootView: migrationView)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(hostingController, animated: true)
        }
    }
    
    private func simulateError() {
        // This would normally be internal to DailyOpsReset
        // For testing, you might need to add a test method to DailyOpsReset
        print("⚠️ Error simulation not implemented - add test method to DailyOpsReset if needed")
    }
    
    private func checkDatabaseTables() {
        Task {
            do {
                let tables = [
                    "routine_templates",
                    "photo_evidence",
                    "worker_capabilities",
                    "migration_history"
                ]
                
                for table in tables {
                    let count = try await GRDBManager.shared.query(
                        "SELECT COUNT(*) as count FROM \(table)"
                    )
                    let recordCount = count.first?["count"] as? Int64 ?? 0
                    print("✅ Table '\(table)': \(recordCount) records")
                }
            } catch {
                print("❌ Error checking tables: \(error)")
            }
        }
    }
    
    private func resetMigrationStatus() {
        // Clear all migration flags
        UserDefaults.standard.removeObject(forKey: "hasImportedWorkers_v1")
        UserDefaults.standard.removeObject(forKey: "hasImportedBuildings_v1")
        UserDefaults.standard.removeObject(forKey: "hasImportedTemplates_v1")
        UserDefaults.standard.removeObject(forKey: "hasCreatedAssignments_v1")
        UserDefaults.standard.removeObject(forKey: "hasSetupCapabilities_v1")
        UserDefaults.standard.removeObject(forKey: "dailyOpsMigrationVersion")
        UserDefaults.standard.removeObject(forKey: "lastDailyOperationDate")
        
        print("✅ Migration status reset - app will show migration on next launch")
    }
}

// MARK: - Testing Instructions

/*
 HOW TO TEST THE MIGRATION:
 
 1. Add this view to your ContentView for easy access:
    ```
    .sheet(isPresented: $showingMigrationTest) {
        TestMigrationFlow()
    }
    ```
 
 2. First Run (Fresh Install):
    - Launch app → Should show MigrationView automatically
    - Watch progress through all 7 steps
    - Verify completion and transition to main app
 
 3. Subsequent Runs:
    - Migration should NOT show
    - Daily operations should run silently
 
 4. Testing Reset:
    - Use "Reset Migration Status" to test again
    - Force quit and relaunch app
 
 5. Error Testing:
    - Disconnect network during migration
    - Kill app during migration
    - Test retry functionality
 
 6. Verify Data:
    - Check "Migration Keys" section
    - Use "Check Database Tables" to verify data
    - Look for Kevin's Rubin Museum assignments
 
 EXPECTED RESULTS:
 - Workers: 7 records
 - Buildings: 17+ records
 - Templates: 88 records (from OperationalDataManager)
 - Assignments: Multiple per worker
 - Capabilities: 7 records (one per worker)
 */