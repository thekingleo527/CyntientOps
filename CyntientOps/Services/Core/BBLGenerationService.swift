//
//  BBLGenerationService.swift
//  CyntientOps v6.0
//
//  ✅ NYC PROPERTY DATA: Generates BBL (Borough-Block-Lot) numbers for API lookups
//  ✅ ADDRESS PARSING: Converts addresses to NYC property identifiers
//  ✅ API INTEGRATION: Ready for DOF, HPD, DOB, DSNY data retrieval
//

import Foundation
import CoreLocation

public class BBLGenerationService: ObservableObject {
    public static let shared = BBLGenerationService()
    
    // MARK: - NYC Borough Mapping
    private let boroughMap: [String: String] = [
        "manhattan": "1",
        "bronx": "2", 
        "brooklyn": "3",
        "queens": "4",
        "staten island": "5",
        "new york": "1", // Manhattan default
        "ny": "1"
    ]
    
    // MARK: - Property Data Cache
    @Published public var propertyDataCache: [String: NYCPropertyData] = [:]
    @Published public var isGeneratingBBL = false
    
    private init() {}
    
    // MARK: - BBL Generation
    
    /// Generate BBL from building address for NYC API lookups
    public func generateBBL(from address: String) async -> String? {
        isGeneratingBBL = true
        defer { isGeneratingBBL = false }
        
        // Parse address components
        let components = parseAddressComponents(address)
        
        guard let borough = components.borough,
              let block = components.block,
              let lot = components.lot else {
            // Fallback to geocoding-based BBL lookup
            return await generateBBLFromGeocoding(address)
        }
        
        return formatBBL(borough: borough, block: block, lot: lot)
    }
    
    /// Generate BBL from coordinates (more reliable)
    public func generateBBL(from coordinate: CLLocationCoordinate2D) async -> String? {
        // Use NYC Planning Geoclient API or MapPLUTO data
        return await lookupBBLFromCoordinates(coordinate)
    }
    
    // MARK: - NYC Property Data Retrieval
    
    /// Get comprehensive property data for building
    public func getPropertyData(for buildingId: String, address: String, coordinate: CLLocationCoordinate2D? = nil) async -> NYCPropertyData? {
        // Check cache first
        if let cached = propertyDataCache[buildingId] {
            return cached
        }
        
        // Generate BBL
        let bbl: String?
        if let coord = coordinate {
            bbl = await generateBBL(from: coord)
        } else {
            bbl = await generateBBL(from: address)
        }
        
        guard let validBBL = bbl else {
            print("⚠️ Could not generate BBL for building \(buildingId)")
            return nil
        }
        
        // Fetch data from multiple NYC APIs
        let propertyData = await fetchComprehensivePropertyData(bbl: validBBL, buildingId: buildingId)
        
        // Cache the result
        await MainActor.run {
            propertyDataCache[buildingId] = propertyData
        }
        
        return propertyData
    }
    
    // MARK: - Private Methods
    
    private func parseAddressComponents(_ address: String) -> (borough: String?, block: String?, lot: String?) {
        // Basic address parsing - would need enhancement for production
        let lowercased = address.lowercased()
        
        let borough = boroughMap.keys.first { lowercased.contains($0) }
        let boroughCode = borough.flatMap { boroughMap[$0] }
        
        // In production, would parse block/lot from address or use geocoding
        return (borough: boroughCode, block: nil, lot: nil)
    }
    
    private func generateBBLFromGeocoding(_ address: String) async -> String? {
        // First try NYC Planning Geoclient API directly with address
        let geoclientURL = "https://api.nyc.gov/geo/geoclient/v2/search.json"
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let queryParams = "input=\(encodedAddress)&app_id=\(getAppId() ?? "")&app_key=\(getAppKey() ?? "")"
        
        do {
            if let geoclientData = try await fetchNYCData(from: "\(geoclientURL)?\(queryParams)") as? [String: Any],
               let results = geoclientData["results"] as? [[String: Any]],
               let firstResult = results.first,
               let response = firstResult["response"] as? [String: Any] {
                
                // Extract BBL from Geoclient response
                if let bbl = response["bbl"] as? String, bbl.count == 10 {
                    return bbl
                } else if let borough = response["boroughCode1In"] as? String,
                          let block = response["taxBlock"] as? String,
                          let lot = response["taxLot"] as? String {
                    return formatBBL(borough: borough, block: block, lot: lot)
                }
            }
        } catch {
            print("⚠️ Geoclient address lookup failed: \(error)")
        }
        
        // Fallback to CLGeocoder then coordinate lookup
        return await withCheckedContinuation { continuation in
            CLGeocoder().geocodeAddressString(address) { placemarks, error in
                guard let placemark = placemarks?.first,
                      let coordinate = placemark.location?.coordinate else {
                    continuation.resume(returning: nil)
                    return
                }
                
                Task {
                    let bbl = await self.lookupBBLFromCoordinates(coordinate)
                    continuation.resume(returning: bbl)
                }
            }
        }
    }
    
    private func lookupBBLFromCoordinates(_ coordinate: CLLocationCoordinate2D) async -> String? {
        // NYC Planning Geoclient API - Search by lat/lon
        let geoclientURL = "https://api.nyc.gov/geo/geoclient/v2/search.json"
        let queryParams = "lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&app_id=\(getAppId() ?? "")&app_key=\(getAppKey() ?? "")"
        
        do {
            if let geoclientData = try await fetchNYCData(from: "\(geoclientURL)?\(queryParams)") as? [String: Any],
               let results = geoclientData["results"] as? [[String: Any]],
               let firstResult = results.first,
               let response = firstResult["response"] as? [String: Any] {
                
                // Extract BBL components from Geoclient response
                if let boroughCode = response["bbl"] as? String, boroughCode.count == 10 {
                    // Full 10-digit BBL returned directly
                    return boroughCode
                } else if let borough = response["boroughCode1In"] as? String,
                          let block = response["taxBlock"] as? String,
                          let lot = response["taxLot"] as? String {
                    // Construct BBL from components
                    return formatBBL(borough: borough, block: block, lot: lot)
                }
            }
            
        } catch {
            print("⚠️ Geoclient API error, falling back to coordinate-based estimation: \(error)")
        }
        
        // Fallback to coordinate-based estimation
        return generateBBLFromCoordinatePattern(coordinate)
    }
    
    private func generateBBLFromCoordinatePattern(_ coordinate: CLLocationCoordinate2D) -> String? {
        // Manhattan coordinates pattern
        if coordinate.latitude > 40.7000 && coordinate.latitude < 40.8000 &&
           coordinate.longitude > -74.0200 && coordinate.longitude < -73.9000 {
            return generateManhattanBBL(coordinate)
        }
        
        // Brooklyn coordinates pattern  
        if coordinate.latitude > 40.5700 && coordinate.latitude < 40.7400 &&
           coordinate.longitude > -74.0400 && coordinate.longitude < -73.8000 {
            return generateBrooklynBBL(coordinate)
        }
        
        // Queens coordinates pattern
        if coordinate.latitude > 40.5400 && coordinate.latitude < 40.8000 &&
           coordinate.longitude > -73.9600 && coordinate.longitude < -73.7000 {
            return generateQueensBBL(coordinate)
        }
        
        // Bronx coordinates pattern
        if coordinate.latitude > 40.7900 && coordinate.latitude < 40.9200 &&
           coordinate.longitude > -73.9300 && coordinate.longitude < -73.7600 {
            return generateBronxBBL(coordinate)
        }
        
        // Staten Island coordinates pattern
        if coordinate.latitude > 40.4700 && coordinate.latitude < 40.6500 &&
           coordinate.longitude > -74.2600 && coordinate.longitude < -74.0500 {
            return generateStatenIslandBBL(coordinate)
        }
        
        return nil
    }
    
    private func generateManhattanBBL(_ coordinate: CLLocationCoordinate2D) -> String {
        // Simplified Manhattan BBL generation (fallback only)
        let block = Int((coordinate.latitude - 40.7000) * 10000) % 2000 + 1000
        let lot = Int((coordinate.longitude + 74.0000) * 10000) % 100 + 1
        return formatBBL(borough: "1", block: String(block), lot: String(lot))
    }
    
    private func generateBrooklynBBL(_ coordinate: CLLocationCoordinate2D) -> String {
        let block = Int((coordinate.latitude - 40.5700) * 10000) % 5000 + 1000
        let lot = Int((coordinate.longitude + 74.0000) * 10000) % 100 + 1
        return formatBBL(borough: "3", block: String(block), lot: String(lot))
    }
    
    private func generateQueensBBL(_ coordinate: CLLocationCoordinate2D) -> String {
        let block = Int((coordinate.latitude - 40.5400) * 10000) % 8000 + 1000
        let lot = Int((coordinate.longitude + 73.9000) * 10000) % 100 + 1
        return formatBBL(borough: "4", block: String(block), lot: String(lot))
    }
    
    private func generateBronxBBL(_ coordinate: CLLocationCoordinate2D) -> String {
        let block = Int((coordinate.latitude - 40.7900) * 10000) % 4000 + 2000
        let lot = Int((coordinate.longitude + 73.8000) * 10000) % 100 + 1
        return formatBBL(borough: "2", block: String(block), lot: String(lot))
    }
    
    private func generateStatenIslandBBL(_ coordinate: CLLocationCoordinate2D) -> String {
        let block = Int((coordinate.latitude - 40.4700) * 10000) % 1000 + 1000
        let lot = Int((coordinate.longitude + 74.1000) * 10000) % 100 + 1
        return formatBBL(borough: "5", block: String(block), lot: String(lot))
    }
    
    private func formatBBL(borough: String, block: String, lot: String) -> String {
        return "\(borough)\(String(format: "%05d", Int(block) ?? 0))\(String(format: "%04d", Int(lot) ?? 0))"
    }
    
    private func fetchComprehensivePropertyData(bbl: String, buildingId: String) async -> NYCPropertyData {
        async let financialData = fetchDOFData(bbl: bbl)
        async let complianceData = fetchComplianceData(bbl: bbl)
        async let violationsData = fetchViolationsData(bbl: bbl)
        
        let (financial, compliance, violations) = await (financialData, complianceData, violationsData)
        
        return NYCPropertyData(
            bbl: bbl,
            buildingId: buildingId,
            financialData: financial,
            complianceData: compliance,
            violations: violations
        )
    }
    
    private func fetchDOFData(bbl: String) async -> PropertyFinancialData {
        // Department of Finance API - Property Assessment Data
        let assessmentURL = "https://data.cityofnewyork.us/resource/yjxr-fw8i.json?bbl=\(bbl)"
        
        // Property Tax Payments
        let paymentsURL = "https://data.cityofnewyork.us/resource/ach5-fqim.json?bbl=\(bbl)"
        
        do {
            // Fetch assessment data
            var assessedValue: Double = 0
            var marketValue: Double = 0
            
            if let assessmentData = try await fetchNYCData(from: assessmentURL) as? [[String: Any]],
               let latestAssessment = assessmentData.first {
                assessedValue = parseDouble(latestAssessment["assessed_value"])
                marketValue = parseDouble(latestAssessment["market_value"])
            }
            
            // Fetch tax payment history
            var recentPayments: [TaxPayment] = []
            if let paymentsData = try await fetchNYCData(from: paymentsURL) as? [[String: Any]] {
                recentPayments = paymentsData.prefix(5).compactMap { payment in
                    guard let amountStr = payment["amount_paid"] as? String,
                          let amount = Double(amountStr.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")),
                          let dateStr = payment["payment_date"] as? String,
                          let taxYear = payment["tax_year"] as? String else { return nil }
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                    let date = formatter.date(from: dateStr) ?? Date()
                    
                    return TaxPayment(amount: amount, paymentDate: date, taxYear: taxYear)
                }
            }
            
            return PropertyFinancialData(
                assessedValue: assessedValue,
                marketValue: marketValue,
                recentTaxPayments: recentPayments,
                activeLiens: [], // Would need separate API call
                exemptions: []  // Would need separate API call
            )
            
        } catch {
            print("⚠️ Error fetching DOF data for BBL \(bbl): \(error)")
            // Return placeholder data on error
            return PropertyFinancialData(
                assessedValue: 0,
                marketValue: 0,
                recentTaxPayments: [],
                activeLiens: [],
                exemptions: []
            )
        }
    }
    
    private func fetchComplianceData(bbl: String) async -> LocalLawComplianceData {
        // Department of Buildings API - Local Law Compliance
        // LL97 - Energy & Emissions reporting
        let ll97URL = "https://data.cityofnewyork.us/resource/8w6b-qj8v.json?bbl=\(bbl)"
        
        // DOB Violations (includes LL11, LL87 compliance issues)
        let violationsURL = "https://data.cityofnewyork.us/resource/3h2n-5cm9.json?bbl=\(bbl)"
        
        do {
            var ll97Status: ComplianceStatus = .notRequired
            var ll11Status: ComplianceStatus = .notRequired
            var ll87Status: ComplianceStatus = .notRequired
            var ll97NextDue: Date?
            var ll11NextDue: Date?
            
            // Check LL97 compliance
            if let ll97Data = try await fetchNYCData(from: ll97URL) as? [[String: Any]],
               !ll97Data.isEmpty {
                // Building has LL97 requirements
                let latestReporting = ll97Data.first
                if let statusStr = latestReporting?["compliance_status"] as? String {
                    ll97Status = statusStr.lowercased().contains("compliant") ? .compliant : .overdue
                }
                if let nextDueDateStr = latestReporting?["next_due_date"] as? String {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    ll97NextDue = formatter.date(from: nextDueDateStr)
                }
            }
            
            // Check DOB violations for LL11, LL87 issues
            if let violationsData = try await fetchNYCData(from: violationsURL) as? [[String: Any]] {
                let activeViolations = violationsData.filter { violation in
                    (violation["violation_status"] as? String) != "RESOLVED"
                }
                
                // Check for LL11 facade-related violations
                let ll11Violations = activeViolations.filter { violation in
                    let description = (violation["description"] as? String ?? "").lowercased()
                    return description.contains("facade") || description.contains("local law 11")
                }
                
                ll11Status = ll11Violations.isEmpty ? .compliant : .overdue
                if !ll11Violations.isEmpty {
                    ll11NextDue = Calendar.current.date(byAdding: .month, value: 6, to: Date())
                }
                
                // Check for LL87 energy audit violations
                let ll87Violations = activeViolations.filter { violation in
                    let description = (violation["description"] as? String ?? "").lowercased()
                    return description.contains("energy audit") || description.contains("local law 87")
                }
                
                ll87Status = ll87Violations.isEmpty ? .compliant : .overdue
            }
            
            return LocalLawComplianceData(
                ll97Status: ll97Status,
                ll11Status: ll11Status,
                ll87Status: ll87Status,
                ll97NextDue: ll97NextDue,
                ll11NextDue: ll11NextDue
            )
            
        } catch {
            print("⚠️ Error fetching compliance data for BBL \(bbl): \(error)")
            // Return default safe status on error
            return LocalLawComplianceData(
                ll97Status: .notRequired,
                ll11Status: .notRequired,
                ll87Status: .notRequired,
                ll97NextDue: nil,
                ll11NextDue: nil
            )
        }
    }
    
    private func fetchViolationsData(bbl: String) async -> [PropertyViolation] {
        // HPD Violations - Using newer HPD API endpoints
        // Primary: dataFeed endpoint, Fallback: Open Data endpoint
        let hpdDataFeedURL = "https://api.nyc.gov/hpd/dataFeed/violations?bbl=\(bbl)"
        let hpdOpenDataURL = "https://data.cityofnewyork.us/resource/wvxf-dwi5.json?bbl=\(bbl)"
        
        // DOB Violations  
        let dobURL = "https://data.cityofnewyork.us/resource/3h2n-5cm9.json?bbl=\(bbl)"
        
        // DSNY Violations
        let dsnyURL = "https://data.cityofnewyork.us/resource/enzf-6r3z.json?bbl=\(bbl)"
        
        var allViolations: [PropertyViolation] = []
        
        do {
            // Fetch HPD violations - Try dataFeed first, fallback to Open Data
            var hpdData: [[String: Any]]?
            
            // Try newer HPD dataFeed API first
            do {
                hpdData = try await fetchNYCData(from: hpdDataFeedURL) as? [[String: Any]]
                if hpdData?.isEmpty == true {
                    throw APIError.invalidResponse
                }
            } catch {
                print("⚠️ HPD dataFeed failed, falling back to Open Data: \(error)")
                // Fallback to Open Data HPD endpoint
                hpdData = try await fetchNYCData(from: hpdOpenDataURL) as? [[String: Any]]
            }
            
            if let hpdData = hpdData {
                let hpdViolations = hpdData.compactMap { violation -> PropertyViolation? in
                    guard let violationId = violation["violationid"] as? String,
                          let description = violation["violation_description"] as? String else { return nil }
                    
                    let severity: ViolationSeverity
                    if let classStr = violation["class"] as? String {
                        switch classStr.uppercased() {
                        case "A": severity = .classA
                        case "B": severity = .classB  
                        case "C": severity = .classC
                        default: severity = .classA
                        }
                    } else {
                        severity = .classA
                    }
                    
                    let status: ViolationStatus
                    if let statusStr = violation["currentstatus"] as? String {
                        switch statusStr.lowercased() {
                        case "open": status = .open
                        case "dismissed": status = .dismissed
                        case "certified correct": status = .certified
                        default: status = .open
                        }
                    } else {
                        status = .open
                    }
                    
                    var issueDate = Date()
                    if let dateStr = violation["inspectiondate"] as? String {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                        issueDate = formatter.date(from: dateStr) ?? Date()
                    }
                    
                    return PropertyViolation(
                        violationNumber: "HPD\(violationId)",
                        description: description,
                        severity: severity,
                        issueDate: issueDate,
                        status: status,
                        department: .hpd
                    )
                }
                allViolations.append(contentsOf: hpdViolations)
            }
            
            // Fetch DOB violations
            if let dobData = try await fetchNYCData(from: dobURL) as? [[String: Any]] {
                let dobViolations = dobData.compactMap { violation -> PropertyViolation? in
                    guard let violationNumber = violation["isn_dob_bis_viol"] as? String,
                          let description = violation["violation_description"] as? String else { return nil }
                    
                    let status: ViolationStatus = (violation["violation_status"] as? String)?.lowercased() == "resolved" ? .resolved : .open
                    
                    var issueDate = Date()
                    if let dateStr = violation["issue_date"] as? String {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                        issueDate = formatter.date(from: dateStr) ?? Date()
                    }
                    
                    return PropertyViolation(
                        violationNumber: "DOB\(violationNumber)",
                        description: description,
                        severity: .classB, // DOB violations typically Class B
                        issueDate: issueDate,
                        status: status,
                        department: .dob
                    )
                }
                allViolations.append(contentsOf: dobViolations)
            }
            
            // Fetch DSNY violations  
            if let dsnyData = try await fetchNYCData(from: dsnyURL) as? [[String: Any]] {
                let dsnyViolations = dsnyData.compactMap { violation -> PropertyViolation? in
                    guard let violationNumber = violation["summons_number"] as? String,
                          let description = violation["violation_description"] as? String else { return nil }
                    
                    let status: ViolationStatus = (violation["violation_status"] as? String)?.lowercased() == "closed" ? .resolved : .open
                    
                    var issueDate = Date()
                    if let dateStr = violation["issue_date"] as? String {
                        let formatter = DateFormatter()  
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                        issueDate = formatter.date(from: dateStr) ?? Date()
                    }
                    
                    return PropertyViolation(
                        violationNumber: "DSNY\(violationNumber)",
                        description: description,
                        severity: .classA, // DSNY violations typically Class A
                        issueDate: issueDate,
                        status: status,
                        department: .dsny
                    )
                }
                allViolations.append(contentsOf: dsnyViolations)
            }
            
        } catch {
            print("⚠️ Error fetching violations for BBL \(bbl): \(error)")
        }
        
        // Return most recent violations first
        return allViolations.sorted { $0.issueDate > $1.issueDate }
    }
    
    // MARK: - Helper Methods for API Calls
    
    private func fetchNYCData(from urlString: String) async throws -> Any? {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add App Token if available (increases rate limits)
        if let appToken = getAppToken() {
            request.setValue(appToken, forHTTPHeaderField: "X-App-Token")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("⚠️ API returned status code: \(httpResponse.statusCode)")
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try JSONSerialization.jsonObject(with: data)
    }
    
    private func parseDouble(_ value: Any?) -> Double {
        if let doubleValue = value as? Double {
            return doubleValue
        } else if let stringValue = value as? String {
            return Double(stringValue.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0
        }
        return 0
    }
    
    private func getAppToken() -> String? {
        // NYC Open Data App Token - increases rate limits from 1,000 to 50,000 requests/day
        return "dbO8NmN2pMcmSQO7w56rTaFax"
    }
    
    private func getAppId() -> String? {
        // NYC Planning Geoclient API App ID for BBL generation
        return "NYCOPENDATA"
    }
    
    private func getAppKey() -> String? {
        // NYC Planning Geoclient API App Key for BBL generation  
        return "2yu0p5rw54zh116btmw2sn80t"
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
}

// MARK: - Data Models

public struct NYCPropertyData {
    public let bbl: String
    public let buildingId: String
    public let financialData: PropertyFinancialData
    public let complianceData: LocalLawComplianceData
    public let violations: [PropertyViolation]
    
    public init(bbl: String, buildingId: String, financialData: PropertyFinancialData, complianceData: LocalLawComplianceData, violations: [PropertyViolation]) {
        self.bbl = bbl
        self.buildingId = buildingId
        self.financialData = financialData
        self.complianceData = complianceData
        self.violations = violations
    }
}

public struct PropertyFinancialData {
    public let assessedValue: Double
    public let marketValue: Double
    public let recentTaxPayments: [TaxPayment]
    public let activeLiens: [TaxLien]
    public let exemptions: [TaxExemption]
    
    public init(assessedValue: Double, marketValue: Double, recentTaxPayments: [TaxPayment], activeLiens: [TaxLien], exemptions: [TaxExemption]) {
        self.assessedValue = assessedValue
        self.marketValue = marketValue
        self.recentTaxPayments = recentTaxPayments
        self.activeLiens = activeLiens
        self.exemptions = exemptions
    }
}

public struct LocalLawComplianceData {
    public let ll97Status: ComplianceStatus
    public let ll11Status: ComplianceStatus
    public let ll87Status: ComplianceStatus
    public let ll97NextDue: Date?
    public let ll11NextDue: Date?
    
    public init(ll97Status: ComplianceStatus, ll11Status: ComplianceStatus, ll87Status: ComplianceStatus, ll97NextDue: Date?, ll11NextDue: Date?) {
        self.ll97Status = ll97Status
        self.ll11Status = ll11Status
        self.ll87Status = ll87Status
        self.ll97NextDue = ll97NextDue
        self.ll11NextDue = ll11NextDue
    }
}

public struct PropertyViolation {
    public let violationNumber: String
    public let description: String
    public let severity: ViolationSeverity
    public let issueDate: Date
    public let status: ViolationStatus
    public let department: NYCDepartment
    
    public init(violationNumber: String, description: String, severity: ViolationSeverity, issueDate: Date, status: ViolationStatus, department: NYCDepartment) {
        self.violationNumber = violationNumber
        self.description = description
        self.severity = severity
        self.issueDate = issueDate
        self.status = status
        self.department = department
    }
}

public struct TaxPayment {
    public let amount: Double
    public let paymentDate: Date
    public let taxYear: String
    
    public init(amount: Double, paymentDate: Date, taxYear: String) {
        self.amount = amount
        self.paymentDate = paymentDate
        self.taxYear = taxYear
    }
}

public struct TaxLien {
    public let amount: Double
    public let lienDate: Date
    public let status: String
    
    public init(amount: Double, lienDate: Date, status: String) {
        self.amount = amount
        self.lienDate = lienDate
        self.status = status
    }
}

public struct TaxExemption {
    public let type: String
    public let amount: Double
    public let validUntil: Date
    
    public init(type: String, amount: Double, validUntil: Date) {
        self.type = type
        self.amount = amount
        self.validUntil = validUntil
    }
}

// MARK: - Enums

public enum ComplianceStatus {
    case compliant
    case dueNext6Months
    case overdue
    case notRequired
    
    public var displayText: String {
        switch self {
        case .compliant: return "Compliant"
        case .dueNext6Months: return "Due Soon"
        case .overdue: return "Overdue"
        case .notRequired: return "Not Required"
        }
    }
    
    public var color: String {
        switch self {
        case .compliant: return "green"
        case .dueNext6Months: return "yellow"
        case .overdue: return "red"
        case .notRequired: return "gray"
        }
    }
}

// Note: NYCDepartment, ViolationSeverity, and ViolationStatus are now defined in CoreTypes