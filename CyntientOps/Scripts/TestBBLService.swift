//
//  TestBBLService.swift
//  CyntientOps
//
//  Test script for BBLGenerationService functionality
//  🧪 TESTING: BBL generation, NYC API integration, property data retrieval
//

import Foundation
import CoreLocation

@MainActor
class BBLServiceTester {
    
    /// Test BBL generation and property data retrieval
    public func runBBLTest() async {
        print("🧪 STARTING BBL SERVICE TEST")
        print("=" + String(repeating: "=", count: 50))
        
        // Test known NYC addresses
        let testAddresses = [
            ("Rubin Museum", "142-148 West 17th Street, New York, NY", 40.7390, -73.9992),
            ("123 1st Avenue", "123 1st Avenue, New York, NY", 40.7282, -73.9863),
            ("68 Perry Street", "68 Perry Street, New York, NY", 40.7348, -74.0061)
        ]
        
        let bblService = BBLGenerationService.shared
        
        for (name, address, lat, lng) in testAddresses {
            print("\n🏢 Testing: \(name)")
            print("📍 Address: \(address)")
            
            // Test BBL generation
            let bbl = await bblService.generateBBL(from: address)
            if let bbl = bbl {
                print("✅ BBL Generated: \(bbl)")
                
                // Test property data retrieval
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                let property = await bblService.getPropertyData(
                    for: "test_\(name.replacingOccurrences(of: " ", with: "_"))",
                    address: address,
                    coordinate: coordinate
                )
                
                if let property = property {
                    print("✅ Property Data Retrieved:")
                    print("   Market Value: $\(Int(property.financialData.marketValue).formatted(.number))")
                    print("   Assessed Value: $\(Int(property.financialData.assessedValue).formatted(.number))")
                    print("   Violations: \(property.violations.count)")
                    print("   LL97 Status: \(property.complianceData.ll97Status)")
                    print("   LL11 Status: \(property.complianceData.ll11Status)")
                    print("   Active Liens: \(property.financialData.activeLiens.count)")
                } else {
                    print("❌ Failed to retrieve property data")
                }
            } else {
                print("❌ Failed to generate BBL")
            }
            
            print("-" + String(repeating: "-", count: 40))
        }
        
        print("\n✅ BBL SERVICE TEST COMPLETE")
        print("📊 Cache Status: \(bblService.propertyDataCache.count) properties cached")
        print("=" + String(repeating: "=", count: 50))
    }
}

// Test runner function that can be called from other parts of the app
@MainActor
public func testBBLServiceDirectly() async {
    let tester = BBLServiceTester()
    await tester.runBBLTest()
}

#if DEBUG
// Main execution for direct script running (development only)
@main
struct BBLTestRunner {
    static func main() async {
        await testBBLServiceDirectly()
    }
}
#endif