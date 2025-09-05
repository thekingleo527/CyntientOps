//
//  NYCVerificationService.swift
//  CyntientOps
//
//  Prints one public detail from each NYC API for each building (where BIN/BBL mapping is known),
//  to confirm live connectivity and data shape. Intended for manual run in dev/testing.
//

import Foundation

@MainActor
public final class NYCVerificationService {
    private let nycAPI = NYCAPIService.shared
    private let db: GRDBManager
    
    public init(database: GRDBManager) {
        self.db = database
    }
    
    public func runProof(limitToKnownMapped: Bool = true) async {
        print("🔎 NYC API Proof — one detail per dataset (per building)")
        do {
            let rows = try await db.query("""
                SELECT id, name, address, latitude, longitude
                FROM buildings
                ORDER BY name
            """)
            
            for row in rows {
                guard let id = row["id"] as? String,
                      let name = row["name"] as? String,
                      let address = row["address"] as? String else { continue }
                let lat = row["latitude"] as? Double ?? 0
                let lon = row["longitude"] as? Double ?? 0
                
                var (bin, bbl) = resolveBinBbl(for: id)
                if bin.isEmpty || bbl.isEmpty {
                    if limitToKnownMapped {
                        continue // skip unmapped to keep proof clean
                    }
                }
                print("\n🏢 \(name) (\(id)) — \(address)")
                if bin.isEmpty || bbl.isEmpty {
                    print("  • BIN/BBL not mapped; attempting address-only datasets…")
                }
                
                // HPD (by BIN)
                do {
                    if !bin.isEmpty {
                        let hpd = try await nycAPI.fetchHPDViolations(bin: bin)
                        let sample = hpd.first?.violationId ?? "<none>"
                        print("  • HPD violationId: \(sample)")
                    }
                } catch { print("  • HPD: <error> \(error.localizedDescription)") }
                
                // DOB (by BIN)
                do {
                    if !bin.isEmpty {
                        let dob = try await nycAPI.fetchDOBPermits(bin: bin)
                        let sample = dob.first?.jobNumber ?? "<none>"
                        print("  • DOB jobNumber: \(sample)")
                    }
                } catch { print("  • DOB: <error> \(error.localizedDescription)") }
                
                // FDNY (by BIN)
                do {
                    if !bin.isEmpty {
                        let fdny = try await nycAPI.fetchFDNYInspections(bin: bin)
                        let sample = fdny.first?.inspectionDate ?? "<none>"
                        print("  • FDNY inspectionDate: \(sample)")
                    }
                } catch { print("  • FDNY: <error> \(error.localizedDescription)") }
                
                // DSNY Violations (by BIN)
                do {
                    if !bin.isEmpty {
                        let dsnyv = try await nycAPI.fetchDSNYViolations(bin: bin)
                        let sample = dsnyv.first?.violationId ?? "<none>"
                        print("  • DSNY violationId: \(sample)")
                    }
                } catch { print("  • DSNY Violations: <error> \(error.localizedDescription)") }
                
                // LL97 (by BBL)
                do {
                    if !bbl.isEmpty {
                        let ll97 = try await nycAPI.fetchLL97Compliance(bbl: bbl)
                        let sample = ll97.first?.reportingYear ?? "<none>"
                        print("  • LL97 reportingYear: \(sample)")
                    }
                } catch { print("  • LL97: <error> \(error.localizedDescription)") }
                
                // DOF (by BBL)
                do {
                    if !bbl.isEmpty {
                        let dof = try await nycAPI.fetchDOFPropertyAssessment(bbl: bbl)
                        let sample = (dof.first?.borough ?? "") + " " + (dof.first?.bbl ?? "")
                        print("  • DOF property sample: \(sample)")
                    }
                } catch { print("  • DOF Property: <error> \(error.localizedDescription)") }
                
                do {
                    if !bbl.isEmpty {
                        let bills = try await nycAPI.fetchDOFTaxBills(bbl: bbl)
                        let sample = bills.first?.statementNumber ?? "<none>"
                        print("  • DOF tax bill statement: \(sample)")
                    }
                } catch { print("  • DOF Tax Bills: <error> \(error.localizedDescription)") }
                
                do {
                    if !bbl.isEmpty {
                        let liens = try await nycAPI.fetchDOFTaxLiens(bbl: bbl)
                        let sample = liens.first?.lienNumber ?? "<none>"
                        print("  • DOF lien number: \(sample)")
                    }
                } catch { print("  • DOF Tax Liens: <error> \(error.localizedDescription)") }
                
                // 311 (by incident_address)
                do {
                    let srs = try await nycAPI.fetch311Complaints(address: address)
                    let sample = srs.first?.uniqueKey ?? "<none>"
                    print("  • 311 unique_key: \(sample)")
                } catch { print("  • 311: <error> \(error.localizedDescription)") }
            }
            
            print("\nTip: Aggregate 1–12 months history by calling the same endpoints with date filters and persisting in nyc_compliance_cache.")
        } catch {
            print("❌ NYC verification failed: \(error)")
        }
    }
    
    private func resolveBinBbl(for id: String) -> (String, String) {
        switch id {
        case "14", "14a": return ("1034304", "1008490017")
        case "14b": return ("1034305", "1008490018")
        case "14c": return ("1034306", "1008490019")
        case "14d": return ("1034307", "1008490020")
        case "4": return ("1008765", "1006210036")
        case "8": return ("1002456", "1003900015")
        case "7": return ("1034289", "1008490015")
        case "6": return ("1034351", "1008500025")
        default: return ("", "")
        }
    }
}

