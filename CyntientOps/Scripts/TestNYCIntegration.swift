//
//  TestNYCIntegration.swift
//  CyntientOps
//
//  Test script to verify complete NYC API integration
//  Tests BIN/BBL mapping, API calls, and DSNY data flow
//

import Foundation
import CoreLocation

@MainActor
class NYCIntegrationTester {
    
    /// Test the complete NYC API integration
    public func runIntegrationTest() async {
        print("🧪 NYC API INTEGRATION TEST")
        print("=" + String(repeating: "=", count: 50))
        print("🔑 Using NYC API Token: dbO8NmN2pMcmSQO7w56rTaFax")
        print("🏢 Testing portfolio buildings with real BIN/BBL mapping")
        
        let nycCompliance = NYCComplianceService(database: GRDBManager.shared)
        
        // Test building - Rubin Museum
        let testBuilding = CoreTypes.NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            coordinate: CLLocationCoordinate2D(latitude: 40.7388, longitude: -73.9970)
        )
        
        print("\n🏢 Testing: \(testBuilding.name)")
        print("📍 Coordinates: \(testBuilding.coordinate.latitude), \(testBuilding.coordinate.longitude)")
        
        // Test compliance data sync
        await nycCompliance.syncBuildingCompliance(building: testBuilding)
        
        // Check if data was retrieved
        let complianceData = nycCompliance.complianceData[testBuilding.id]
        
        if let data = complianceData {
            print("✅ Compliance data retrieved successfully:")
            print("   BIN: \(data.bin)")
            print("   BBL: \(data.bbl)")
            print("   HPD Violations: \(data.hpdViolations.count)")
            print("   DOB Permits: \(data.dobPermits.count)")
            print("   FDNY Inspections: \(data.fdnyInspections.count)")
            print("   311 Complaints: \(data.complaints311.count)")
            print("   DSNY Routes: \(data.dsnySchedule.count)")
            print("   DSNY Violations: \(data.dsnyViolations.count)")
            print("   LL97 Data: \(data.ll97Data.count)")
            
            // Test individual API endpoints
            await testIndividualEndpoints(bin: data.bin, bbl: data.bbl)
            
        } else {
            print("❌ No compliance data retrieved")
        }
        
        print("\n✅ NYC API Integration test completed")
    }
    
    private func testIndividualEndpoints(bin: String, bbl: String) async {
        print("\n🔗 Testing individual API endpoints:")
        
        let nycAPI = NYCAPIService.shared
        
        do {
            // Test HPD Violations
            let hpdViolations = try await nycAPI.fetchHPDViolations(bin: bin)
            print("   HPD Violations: \(hpdViolations.count) records")
            
            // Test DOB Permits
            let dobPermits = try await nycAPI.fetchDOBPermits(bin: bin)
            print("   DOB Permits: \(dobPermits.count) records")
            
            // Test DSNY Schedule
            let dsnyRoutes = try await nycAPI.fetchDSNYSchedule(district: "MN05")
            print("   DSNY Routes: \(dsnyRoutes.count) records")
            
            // Test DSNY Violations
            let dsnyViolations = try await nycAPI.fetchDSNYViolations(bin: bin)
            print("   DSNY Violations: \(dsnyViolations.count) records")
            
            // Test LL97 Compliance
            let ll97Data = try await nycAPI.fetchLL97Compliance(bbl: bbl)
            print("   LL97 Emissions: \(ll97Data.count) records")
            
            // Test 311 Complaints
            let complaints = try await nycAPI.fetch311Complaints(bin: bin)
            print("   311 Complaints: \(complaints.count) records")
            
        } catch {
            print("   ❌ API Error: \(error.localizedDescription)")
        }
    }
}

// Usage example:
// let tester = NYCIntegrationTester()
// await tester.runIntegrationTest()