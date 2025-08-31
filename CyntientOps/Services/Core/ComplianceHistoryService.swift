//
//  ComplianceHistoryService.swift
//  CyntientOps
//
//  Definitive service for persisting and retrieving NYC compliance history
//  Aligns with GRDB schema (dsny_violations table) and existing integration caches.
//

import Foundation

public actor ComplianceHistoryService {
    private let db: GRDBManager
    
    public init(database: GRDBManager = GRDBManager.shared) {
        self.db = database
    }
    
    // MARK: - DSNY Violations
    
    public struct DSNYTicket: Sendable {
        public let id: String
        public let buildingId: String
        public let type: String
        public let issueDate: Date
        public let fineAmount: Double
        public let status: String
        public let description: String?
    }
    
    public func getDSNYViolations(for buildingId: String, limit: Int = 50) async -> [DSNYTicket] {
        do {
            let rows = try await db.query("""
                SELECT id, building_id, violation_type, issue_date, fine_amount, status, description
                FROM dsny_violations
                WHERE building_id = ?
                ORDER BY datetime(issue_date) DESC
                LIMIT ?
            """, [buildingId, limit])
            return rows.compactMap { row in
                guard let id = row["id"] as? String,
                      let bid = row["building_id"] as? String,
                      let type = row["violation_type"] as? String,
                      let issue = row["issue_date"] as? String,
                      let status = row["status"] as? String else { return nil }
                let fine = (row["fine_amount"] as? Double) ?? 0.0
                let desc = row["description"] as? String
                let date = ISO8601DateFormatter().date(from: issue) ?? Date()
                return DSNYTicket(id: id, buildingId: bid, type: type, issueDate: date, fineAmount: fine, status: status, description: desc)
            }
        } catch {
            return []
        }
    }
    
    public func persistDSNYViolations(buildingId: String, violations: [DSNYViolation]) async {
        for v in violations {
            do {
                try await db.execute("""
                    INSERT OR REPLACE INTO dsny_violations (
                        id, building_id, violation_type, issue_date, fine_amount, status, description, reported_by, created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, NULL, datetime('now'))
                """, [
                    v.id,
                    buildingId,
                    v.violationType,
                    v.issueDate ?? ISO8601DateFormatter().string(from: Date()),
                    v.fineAmount ?? 0.0,
                    v.isActive ? "active" : "resolved",
                    v.violationDetails ?? ""
                ])
            } catch {
                continue
            }
        }
    }
}

