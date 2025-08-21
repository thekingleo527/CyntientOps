//
//  DemoRealAPIData.swift
//  CyntientOps
//
//  Demonstration script showing real NYC API data integration
//  🎯 DEMO: Real building data with BBL generation and NYC APIs
//

import Foundation
import CoreLocation

@MainActor
class APIDataDemo {
    
    /// Demonstrate real NYC API data for multiple buildings
    public func demonstrateRealAPIData() async {
        print("🎯 NYC API REAL DATA DEMONSTRATION")
        print("=" + String(repeating: "=", count: 50))
        
        // Sample NYC buildings with real data
        let testBuildings = [
            (
                name: "One World Trade Center",
                address: "285 Fulton Street, New York, NY 10007",
                lat: 40.713003,
                lng: -74.013169,
                bin: "1001026"
            ),
            (
                name: "Chrysler Building", 
                address: "405 Lexington Avenue, New York, NY 10174",
                lat: 40.751621,
                lng: -73.975309,
                bin: "1015073"
            ),
            (
                name: "Brooklyn Bridge",
                address: "Brooklyn Bridge, New York, NY 11201",
                lat: 40.706086,
                lng: -73.996864,
                bin: "3000001"
            )
        ]
        
        let bblService = BBLGenerationService.shared
        let nycAPI = NYCAPIService.shared
        
        for (index, building) in testBuildings.enumerated() {
            print("\n\(index + 1)️⃣ BUILDING: \(building.name)")
            print("   📍 Address: \(building.address)")
            print("   🔢 BIN: \(building.bin)")
            
            do {
                // Generate BBL and get property data
                let coordinate = CLLocationCoordinate2D(latitude: building.lat, longitude: building.lng)
                
                if let propertyData = await bblService.getPropertyData(
                    for: "demo_\(index)",
                    address: building.address,
                    coordinate: coordinate
                ) {
                    print("   ✅ BBL Generated: \(propertyData.bbl)")
                    print("   💰 Market Value: $\(formatCurrency(propertyData.financialData.marketValue))")
                    print("   🏛️ Assessed Value: $\(formatCurrency(propertyData.financialData.assessedValue))")
                    print("   ⚖️ Total Violations: \(propertyData.violations.count)")
                    
                    if propertyData.violations.count > 0 {
                        let activeViolations = propertyData.violations.filter { 
                            $0.status != .resolved && $0.status != .dismissed 
                        }
                        print("   🚨 Active Violations: \(activeViolations.count)")
                        
                        if let sampleViolation = activeViolations.first {
                            let shortDesc = String(sampleViolation.description.prefix(50))
                            print("   📋 Sample: \(shortDesc)...")
                        }
                    }
                    
                    print("   🌱 LL97 Status: \(propertyData.complianceData.ll97Status)")
                    print("   🏗️ LL11 Status: \(propertyData.complianceData.ll11Status)")
                    
                    // Show recent tax payments if available
                    if !propertyData.financialData.recentTaxPayments.isEmpty {
                        let recentPayment = propertyData.financialData.recentTaxPayments.first!
                        print("   💳 Recent Tax Payment: $\(formatCurrency(recentPayment.amount)) (\(recentPayment.taxYear))")
                    }
                    
                } else {
                    print("   ❌ Failed to generate property data")
                }
                
                // Test individual API calls
                print("   📊 API Data Summary:")
                
                // HPD Violations
                do {
                    let hpdViolations = try await nycAPI.fetchHPDViolations(bin: building.bin)
                    let activeHPD = hpdViolations.filter { $0.isActive }
                    print("     • HPD Violations: \(hpdViolations.count) total, \(activeHPD.count) active")
                } catch {
                    print("     • HPD Violations: API unavailable")
                }
                
                // DOB Permits
                do {
                    let dobPermits = try await nycAPI.fetchDOBPermits(bin: building.bin)
                    let activeDOB = dobPermits.filter { !$0.isExpired }
                    print("     • DOB Permits: \(dobPermits.count) total, \(activeDOB.count) active")
                } catch {
                    print("     • DOB Permits: API unavailable")
                }
                
                print("   " + String(repeating: "-", count: 40))
                
                // Rate limiting between buildings
                if index < testBuildings.count - 1 {
                    try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                }
                
            } catch {
                print("   ❌ Error: \(error)")
            }
        }
        
        print("\n🎯 DEMONSTRATION COMPLETE")
        print("📈 This shows real NYC property data being fetched and processed")
        print("🔑 Using authenticated APIs: HPD, DOB, LL97, DSNY + BBL Generation")
        print("=" + String(repeating: "=", count: 50))
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// Demo runner function
@MainActor  
public func runRealAPIDataDemo() async {
    let demo = APIDataDemo()
    await demo.demonstrateRealAPIData()
}

#if DEBUG
// Main execution for direct script running (development only)
@main
struct APIDataDemoRunner {
    static func main() async {
        await runRealAPIDataDemo()
    }
}
#endif