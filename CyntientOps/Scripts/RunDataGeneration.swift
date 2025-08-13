//
//  RunDataGeneration.swift  
//  CyntientOps
//
//  Simple script to trigger comprehensive data generation
//  🚀 EXECUTION: Run this to populate all building data from NYC APIs
//

import Foundation

/// Simple test to verify BBL generation works
func testBBLGeneration() async {
    print("🔢 Testing BBL Generation Service...")
    
    let service = BBLGenerationService.shared
    
    // Test known Manhattan address
    let testAddress = "142-148 West 17th Street, New York, NY"
    print("📍 Testing address: \(testAddress)")
    
    let bbl = await service.generateBBL(from: testAddress)
    
    if let bbl = bbl {
        print("✅ Successfully generated BBL: \(bbl)")
        
        // Test property data retrieval
        print("📊 Testing property data retrieval...")
        let propertyData = await service.getPropertyData(for: "test-building", address: testAddress)
        
        if let property = propertyData {
            print("✅ Property data retrieved:")
            print("   BBL: \(property.bbl)")
            print("   Market Value: $\(Int(property.financialData.marketValue))")
            print("   Violations: \(property.violations.count)")
            print("   LL97 Status: \(property.complianceData.ll97Status)")
        } else {
            print("⚠️ No property data found")
        }
    } else {
        print("❌ Failed to generate BBL")
    }
}

/// Test worker building assignments
func testWorkerAssignments() {
    print("\n👷 Testing Worker Building Assignments...")
    
    let testBuildingIds = ["14", "16", "5", "6", "7"]
    
    for buildingId in testBuildingIds {
        if let worker = WorkerBuildingAssignments.getPrimaryWorker(for: buildingId) {
            print("✅ Building \(buildingId): \(worker)")
            
            if let client = WorkerBuildingAssignments.getClient(for: buildingId) {
                print("   Client: \(client)")
            }
            
            if let buildingName = WorkerBuildingAssignments.getBuildingName(for: buildingId) {
                print("   Name: \(buildingName)")
            }
        } else {
            print("⚠️ No worker assigned to building \(buildingId)")
        }
    }
    
    // Test validation
    print("\n🔍 Running assignment validation...")
    let errors = WorkerBuildingAssignments.validateAssignments()
    if errors.isEmpty {
        print("✅ All assignments valid")
    } else {
        print("❌ Assignment errors found:")
        for error in errors {
            print("   • \(error)")
        }
    }
}

/// Main execution
@main
struct RunDataGeneration {
    static func main() async {
        print("🚀 STARTING DATA GENERATION TEST")
        print("=" + String(repeating: "=", count: 40))
        
        await testBBLGeneration()
        testWorkerAssignments()
        
        print("\n✅ DATA GENERATION TEST COMPLETE")
        print("=" + String(repeating: "=", count: 40))
    }
}