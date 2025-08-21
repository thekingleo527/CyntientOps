//
//  TestRealAPIConnections.swift  
//  CyntientOps
//
//  Test script to verify real NYC API connections with authentication
//  🧪 TESTING: BBL generation, NYC API integration with real data
//

import Foundation
import CoreLocation

@MainActor
class RealAPITester {
    
    /// Test real NYC API connections with authentication
    public func testRealAPIConnections() async {
        print("🧪 STARTING REAL NYC API CONNECTION TEST")
        print("=" + String(repeating: "=", count: 60))
        
        // Test with a real NYC address
        let testBuilding = (
            name: "Empire State Building",
            address: "350 Fifth Avenue, New York, NY 10118",
            lat: 40.748817,
            lng: -73.985428,
            bin: "1003041", // Real BIN for Empire State Building
            bbl: "1012800011" // Real BBL for Empire State Building
        )
        
        print("\n🏢 Testing with: \(testBuilding.name)")
        print("📍 Address: \(testBuilding.address)")
        print("🔢 BIN: \(testBuilding.bin)")
        print("📊 BBL: \(testBuilding.bbl)")
        
        // Test BBL Generation Service
        print("\n1️⃣ Testing BBL Generation Service...")
        let bblService = BBLGenerationService.shared
        
        let coordinate = CLLocationCoordinate2D(latitude: testBuilding.lat, longitude: testBuilding.lng)
        let propertyData = await bblService.getPropertyData(
            for: "test_empire_state",
            address: testBuilding.address,
            coordinate: coordinate
        )
        
        if let propertyData = propertyData {
            print("✅ BBL Service Success!")
            print("   Generated BBL: \(propertyData.bbl)")
            print("   Market Value: $\(Int(propertyData.financialData.marketValue).formatted(.number))")
            print("   Assessed Value: $\(Int(propertyData.financialData.assessedValue).formatted(.number))")
            print("   Violations: \(propertyData.violations.count)")
            print("   LL97 Status: \(propertyData.complianceData.ll97Status)")
            print("   LL11 Status: \(propertyData.complianceData.ll11Status)")
            
            if propertyData.violations.count > 0 {
                print("   Sample Violations:")
                for (index, violation) in propertyData.violations.prefix(3).enumerated() {
                    print("     \(index + 1). \(violation.violationNumber): \(violation.description.prefix(80))...")
                }
            }
        } else {
            print("❌ BBL Service failed")
        }
        
        // Test individual NYC API services
        print("\n2️⃣ Testing Individual NYC APIs...")
        let nycAPI = NYCAPIService.shared
        
        // Test HPD Violations
        do {
            print("📋 Testing HPD Violations API...")
            let hpdViolations = try await nycAPI.fetchHPDViolations(bin: testBuilding.bin)
            print("✅ HPD API Success: Found \(hpdViolations.count) violations")
            
            if let firstViolation = hpdViolations.first {
                print("   Sample: \(firstViolation.novDescription.prefix(80))...")
                print("   Status: \(firstViolation.currentStatus)")
                print("   Severity: \(firstViolation.severity)")
            }
        } catch {
            print("❌ HPD API Error: \(error)")
        }
        
        // Test DOB Permits  
        do {
            print("🏗️ Testing DOB Permits API...")
            let dobPermits = try await nycAPI.fetchDOBPermits(bin: testBuilding.bin)
            print("✅ DOB API Success: Found \(dobPermits.count) permits")
            
            if let firstPermit = dobPermits.first {
                print("   Sample: \(firstPermit.jobType) - \(firstPermit.workType)")
                print("   Status: \(firstPermit.permitStatus)")
                print("   Filed: \(firstPermit.filingDate)")
            }
        } catch {
            print("❌ DOB API Error: \(error)")
        }
        
        // Test LL97 Compliance
        do {
            print("🌱 Testing LL97 Emissions API...")
            let ll97Data = try await nycAPI.fetchLL97Compliance(bbl: testBuilding.bbl)
            print("✅ LL97 API Success: Found \(ll97Data.count) emission reports")
            
            if let firstReport = ll97Data.first {
                print("   Property: \(firstReport.propertyName)")
                print("   Year: \(firstReport.reportingYear)")
                print("   Emissions: \(firstReport.totalGHGEmissions) metric tons CO2e")
                print("   Compliance: \(firstReport.complianceStatus)")
            }
        } catch {
            print("❌ LL97 API Error: \(error)")
        }
        
        // Test DSNY Schedule
        do {
            print("🚛 Testing DSNY Schedule API...")
            let dsnyRoutes = try await nycAPI.fetchDSNYSchedule(district: "Manhattan")
            print("✅ DSNY API Success: Found \(dsnyRoutes.count) collection routes")
            
            if let firstRoute = dsnyRoutes.first {
                print("   Route: \(firstRoute.route)")
                print("   Day: \(firstRoute.dayOfWeek)")
                print("   Service: \(firstRoute.serviceType)")
            }
        } catch {
            print("❌ DSNY API Error: \(error)")
        }
        
        print("\n✅ REAL NYC API CONNECTION TEST COMPLETE")
        print("📊 Cache Status: \(bblService.propertyDataCache.count) properties cached")
        print("=" + String(repeating: "=", count: 60))
    }
}

// Test runner function  
@MainActor
public func testRealNYCAPIConnections() async {
    let tester = RealAPITester()
    await tester.testRealAPIConnections()
}

#if DEBUG
// Main execution for direct script running (development only)
@main
struct RealAPITestRunner {
    static func main() async {
        await testRealNYCAPIConnections()
    }
}
#endif