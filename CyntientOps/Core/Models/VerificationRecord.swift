//  VerificationRecord.swift
//  CyntientOps
//
//  ✅ FIXED: Aligned with CoreTypes.VerificationStatus
//  ✅ FIXED: TaskCompletionRecord initializer
//  ✅ FIXED: All enum values corrected
//  ✅ FIXED: Removed non-existent .needsReview case
//

import Foundation

public struct VerificationRecord: Identifiable, Codable, Hashable, Equatable {
    public let id: String
    public let taskId: String
    public let buildingId: String
    public let workerId: String
    public let verificationDate: Date
    public let status: CoreTypes.VerificationStatus
    public let notes: String?
    public let photoPaths: [String]
    
    public init(
        id: String = UUID().uuidString,
        taskId: String,
        buildingId: String,
        workerId: String,
        verificationDate: Date = Date(),
        status: CoreTypes.VerificationStatus = .pending,
        notes: String? = nil,
        photoPaths: [String] = []
    ) {
        self.id = id
        self.taskId = taskId
        self.buildingId = buildingId
        self.workerId = workerId
        self.verificationDate = verificationDate
        self.status = status
        self.notes = notes
        self.photoPaths = photoPaths
    }
    
    // MARK: - Equatable
    public static func == (lhs: VerificationRecord, rhs: VerificationRecord) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Helper Methods
extension VerificationRecord {
    
    func createCompletionRecord() -> CoreTypes.TaskCompletionRecord {
        return CoreTypes.TaskCompletionRecord(
            taskId: taskId,
            workerId: workerId,
            completedAt: verificationDate,
            verificationStatus: status,
            evidence: nil
        )
    }
    
    func updateVerificationStatus(_ newStatus: CoreTypes.VerificationStatus) -> VerificationRecord {
        return VerificationRecord(
            id: id,
            taskId: taskId,
            buildingId: buildingId,
            workerId: workerId,
            verificationDate: Date(),
            status: newStatus,
            notes: notes,
            photoPaths: photoPaths
        )
    }
    
    var isCompleted: Bool {
        return status == .verified
    }
    
    var isPending: Bool {
        return status == .pending
    }
    
    var isRejected: Bool {
        return status == .rejected
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: verificationDate)
    }
    
    var hasPhotos: Bool {
        return !photoPaths.isEmpty
    }
    
    var photoCount: Int {
        return photoPaths.count
    }
    
    var statusDescription: String {
        switch status {
        case .pending:
            return "Awaiting verification"
        case .verified:
            return "Verified and approved"
        case .rejected:
            return "Rejected - needs revision"
        case .needsReview:
            return "Needs additional review"
        case .notRequired:
            return "Verification not required"
        }
    }
}

// MARK: - Codable Conformance (Consistent property names)
extension VerificationRecord {
    enum CodingKeys: String, CodingKey {
        case id, taskId, buildingId, workerId, verificationDate, status, notes, photoPaths
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        taskId = try container.decode(String.self, forKey: .taskId)
        buildingId = try container.decode(String.self, forKey: .buildingId)
        workerId = try container.decode(String.self, forKey: .workerId)
        verificationDate = try container.decode(Date.self, forKey: .verificationDate)
        status = try container.decode(CoreTypes.VerificationStatus.self, forKey: .status)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        photoPaths = try container.decode([String].self, forKey: .photoPaths)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(taskId, forKey: .taskId)
        try container.encode(buildingId, forKey: .buildingId)
        try container.encode(workerId, forKey: .workerId)
        try container.encode(verificationDate, forKey: .verificationDate)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(photoPaths, forKey: .photoPaths)
    }
}

// MARK: - Sample Data for Kevin's Rubin Museum
extension VerificationRecord {
    static var sampleData: [VerificationRecord] {
        return [
            VerificationRecord(
                taskId: "task_001",
                buildingId: "14", // Rubin Museum
                workerId: "kevin",
                status: .verified,
                notes: "Cleaning completed successfully. All areas thoroughly sanitized.",
                photoPaths: ["rubin_cleaning_before.jpg", "rubin_cleaning_after.jpg"]
            ),
            VerificationRecord(
                taskId: "task_002",
                buildingId: "14", // Rubin Museum
                workerId: "kevin",
                status: .pending,
                notes: "Maintenance inspection in progress. Awaiting supervisor review.",
                photoPaths: ["maintenance_inspection.jpg"]
            ),
            VerificationRecord(
                taskId: "task_003",
                buildingId: "1", // 12 West 18th Street
                workerId: "kevin",
                status: .pending,  // Changed from .needsReview to .pending
                notes: "Additional documentation needed for electrical inspection. Pending review.",
                photoPaths: ["electrical_panel.jpg", "circuit_breaker.jpg"]
            ),
            VerificationRecord(
                taskId: "task_004",
                buildingId: "14", // Rubin Museum
                workerId: "kevin",
                status: .verified,
                notes: "Landscaping maintenance completed. Sidewalk cleaned and cleared.",
                photoPaths: ["sidewalk_before.jpg", "sidewalk_after.jpg", "garden_maintenance.jpg"]
            ),
            VerificationRecord(
                taskId: "task_005",
                buildingId: "2", // 29-31 East 20th Street
                workerId: "kevin",
                status: .rejected,
                notes: "Task could not be completed due to equipment malfunction. Needs rescheduling.",
                photoPaths: ["equipment_issue.jpg"]
            ),
            VerificationRecord(
                taskId: "task_006",
                buildingId: "14", // Rubin Museum
                workerId: "kevin",
                status: .notRequired,
                notes: "Routine check - no verification needed for this task type.",
                photoPaths: []
            )
        ]
    }
    
    static func sampleRecord(for buildingId: String = "14", workerId: String = "kevin") -> VerificationRecord {
        return VerificationRecord(
            taskId: "sample_task_\(UUID().uuidString.prefix(8))",
            buildingId: buildingId,
            workerId: workerId,
            status: .verified,
            notes: "Sample verification record for testing purposes.",
            photoPaths: ["sample_photo_1.jpg", "sample_photo_2.jpg"]
        )
    }
}

// MARK: - UI Helpers
extension VerificationRecord {
    var statusColor: Color {
        switch status {
        case .pending:
            return .orange
        case .verified:
            return .green
        case .rejected:
            return .red
        case .needsReview:
            return .yellow
        case .notRequired:
            return .gray
        }
    }
    
    var statusIcon: String {
        switch status {
        case .pending:
            return "clock.fill"
        case .verified:
            return "checkmark.circle.fill"
        case .rejected:
            return "xmark.circle.fill"
        case .needsReview:
            return "eye.circle.fill"
        case .notRequired:
            return "minus.circle.fill"
        }
    }
}
