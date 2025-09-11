import Foundation
import CoreLocation

public struct BuildingPhoto: Identifiable, Hashable {
    public let id: String
    public let buildingId: String
    public let category: CoreTypes.CyntientOpsPhotoCategory
    public let timestamp: Date
    public let uploadedBy: String?
    public let notes: String?
    public let localPath: String
    public let remotePath: String?
    public let thumbnailPath: String?
    public let hasIssue: Bool
    public let isVerified: Bool
    public let hasLocation: Bool
    public let location: CLLocation?
    public let taskId: String?
    public let fileSize: Int?

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: BuildingPhoto, rhs: BuildingPhoto) -> Bool { lhs.id == rhs.id }
}

public struct BuildingPhotoMetadata {
    public let buildingId: String
    public let category: CoreTypes.CyntientOpsPhotoCategory
    public let notes: String?
    public let location: CLLocation?
    public let taskId: String?
    public let workerId: String?
    public let timestamp: Date
}

