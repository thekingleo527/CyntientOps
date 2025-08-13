#!/usr/bin/env swift

//
//  ValidateWorkerData.swift
//  CyntientOps
//
//  Validates that each worker gets their specific building assignments and routines
//

import Foundation

// ACTUAL worker building assignments from OperationalDataManager (as of data review)
let workerExpectedBuildings: [String: [String]] = [
    "1": ["12 West 18th Street"], // Greg Hutson - ACTUAL assignments
    "2": ["Stuyvesant Cove Park", "133 East 15th Street", "CyntientOps HQ", "117 West 17th Street", "112 West 18th Street", "135-139 West 17th Street", "131 Perry Street", "138 West 17th Street"], // Edwin Lema - Maintenance worker
    "4": ["131 Perry Street", "68 Perry Street", "135-139 West 17th Street", "136 West 17th Street", "138 West 17th Street", "117 West 17th Street", "112 West 18th Street", "Rubin Museum", "123 1st Avenue", "178 Spring Street"], // Kevin Dutan - MANY assignments
    "5": ["117 West 17th Street", "112 West 18th Street", "135-139 West 17th Street", "136 West 17th Street"], // Mercedes Inamagua - Glass/Lobby cleaning
    "6": ["104 Franklin Street", "36 Walker Street"], // Luis Lopez
    "7": ["41 Elizabeth Street", "12 West 18th Street"], // Angel Guirachocha
    "8": ["CyntientOps HQ"] // Shawn Magloire
    
    // NOTE: 29-31 East 20th Street REMOVED - No longer active
]

print("🧪 Worker Data Validation")
print("========================")

print("Expected building assignments:")
for (workerId, buildings) in workerExpectedBuildings.sorted(by: { $0.key < $1.key }) {
    let workerName = getWorkerName(workerId)
    print("  \(workerName) (ID: \(workerId)): \(buildings.joined(separator: ", "))")
}

func getWorkerName(_ workerId: String) -> String {
    let workerNames = [
        "1": "Greg Hutson",
        "2": "Edwin Lema", 
        "4": "Kevin Dutan",
        "5": "Mercedes Inamagua",
        "6": "Luis Lopez",
        "7": "Angel Guirachocha",
        "8": "Shawn Magloire"
    ]
    return workerNames[workerId] ?? "Unknown Worker"
}

print("\n✅ Worker data validation script ready!")
print("💡 Use this to verify WorkerDashboardViewModel loads correct buildings per user.")
print("🗺️ Each worker should see only their assigned buildings on the map.")
print("📋 Weekly schedules should show only their specific routines.")
print("🏢 Building coordinates should render correctly on map with pins.")