import Foundation
import UIKit
import GRDB
import CoreLocation

actor PhotoStorageService {
    static let shared = PhotoStorageService()

    private let grdb = GRDBManager.shared
    private let compressionQuality: CGFloat = 0.7
    private let thumbnailSize = CGSize(width: 400, height: 400)

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Public API

    func loadPhotos(for buildingId: String) async throws -> [BuildingPhoto] {
        let rows = try await grdb.query("""
            SELECT pe.*, tc.worker_id, w.name as worker_name, tc.building_id as tc_building
            FROM photo_evidence pe
            LEFT JOIN task_completions tc ON pe.completion_id = tc.id
            LEFT JOIN workers w ON tc.worker_id = w.id
            WHERE tc.building_id = ? OR (pe.metadata LIKE ?)
            ORDER BY pe.created_at DESC
            LIMIT 300
        """, [buildingId, "%\"buildingId\":\"\(buildingId)\"%"])

        return rows.compactMap { (row) -> BuildingPhoto? in
            guard let id = row["id"] as? String ?? (row["id"] as? Int64).map(String.init) else { return (nil as BuildingPhoto?) }
            let local = row["local_path"] as? String ?? ""
            let thumb = row["thumbnail_path"] as? String
            let remote = row["remote_url"] as? String
            let notes = row["notes"] as? String
            let workerName = row["worker_name"] as? String
            let taskId = row["task_id"] as? String ?? (row["task_id"] as? Int64).map(String.init)
            let size = (row["file_size"] as? Int64).map(Int.init)

            // Derive category from metadata json if present; fallback to utilities
            let meta = row["metadata"] as? String ?? ""
            let cat: CoreTypes.CyntientOpsPhotoCategory = {
                for c in CoreTypes.CyntientOpsPhotoCategory.allCases where c != .all {
                    if meta.lowercased().contains("\"category\":\"\(c.rawValue.lowercased())\"") { return c }
                }
                return .utilities
            }()
            let ts = Date(timeIntervalSince1970: (row["uploaded_at"] as? Double) ?? Date().timeIntervalSince1970)
            let bId = (row["tc_building"] as? String) ?? buildingId

            return BuildingPhoto(
                id: id,
                buildingId: bId,
                category: cat,
                timestamp: ts,
                uploadedBy: workerName,
                notes: notes,
                localPath: local,
                remotePath: remote,
                thumbnailPath: thumb,
                hasIssue: false,
                isVerified: true,
                hasLocation: false,
                location: nil,
                taskId: taskId,
                fileSize: size
            )
        }
    }

    func savePhoto(_ image: UIImage, metadata: BuildingPhotoMetadata) async throws -> BuildingPhoto {
        let id = UUID().uuidString
        let photoDir = documentsDirectory.appendingPathComponent("Photos/\(metadata.buildingId)", isDirectory: true)
        try? FileManager.default.createDirectory(at: photoDir, withIntermediateDirectories: true)

        let fullURL = photoDir.appendingPathComponent("\(id).jpg")
        let thumbURL = photoDir.appendingPathComponent("\(id)_thumb.jpg")

        guard let fullData = image.jpegData(compressionQuality: compressionQuality) else {
            throw PhotoError.compressionFailed
        }
        try fullData.write(to: fullURL, options: .atomic)

        // Thumbnail
        let tn = await resized(image: image, target: thumbnailSize)
        let thumbData = tn.jpegData(compressionQuality: 0.6)
        try thumbData?.write(to: thumbURL, options: .atomic)

        let metaJSON: String = {
            var dict: [String: Any] = [
                "buildingId": metadata.buildingId,
                "category": metadata.category.rawValue,
                "notes": metadata.notes ?? ""
            ]
            if let loc = metadata.location {
                dict["lat"] = loc.coordinate.latitude
                dict["lon"] = loc.coordinate.longitude
            }
            let data = try? JSONSerialization.data(withJSONObject: dict, options: [])
            return String(data: data ?? Data(), encoding: .utf8) ?? "{}"
        }()

        try await grdb.execute("""
            INSERT OR REPLACE INTO photo_evidence (
                id, completion_id, task_id, worker_id, local_path, thumbnail_path, remote_url, file_size, mime_type, metadata, uploaded_at, created_at
            ) VALUES (?, NULL, ?, ?, ?, ?, NULL, ?, 'image/jpeg', ?, ?, datetime('now'))
        """, [
            id,
            metadata.taskId ?? "",
            metadata.workerId ?? "",
            fullURL.path,
            thumbURL.path,
            fullData.count,
            metaJSON,
            metadata.timestamp.timeIntervalSince1970
        ])

        return BuildingPhoto(
            id: id,
            buildingId: metadata.buildingId,
            category: metadata.category,
            timestamp: metadata.timestamp,
            uploadedBy: metadata.workerId,
            notes: metadata.notes,
            localPath: fullURL.path,
            remotePath: nil,
            thumbnailPath: thumbURL.path,
            hasIssue: false,
            isVerified: true,
            hasLocation: metadata.location != nil,
            location: metadata.location,
            taskId: metadata.taskId,
            fileSize: fullData.count
        )
    }

    func loadThumbnail(for photoId: String) async -> UIImage? {
        guard let row = try? await grdb.query("SELECT thumbnail_path FROM photo_evidence WHERE id = ? LIMIT 1", [photoId]).first,
              let path = row["thumbnail_path"] as? String else { return nil }
        return UIImage(contentsOfFile: path)
    }

    func loadFullImage(for photoId: String) async -> UIImage? {
        guard let row = try? await grdb.query("SELECT local_path FROM photo_evidence WHERE id = ? LIMIT 1", [photoId]).first,
              let path = row["local_path"] as? String else { return nil }
        return UIImage(contentsOfFile: path)
    }

    func markPhotoAsIssue(_ photoId: String) async {
        // Append a flag to metadata JSON for now
        if var row = try? await grdb.query("SELECT metadata FROM photo_evidence WHERE id = ?", [photoId]).first,
           let meta = row["metadata"] as? String {
            var dict = (try? JSONSerialization.jsonObject(with: Data(meta.utf8))) as? [String: Any] ?? [:]
            dict["hasIssue"] = true
            let data = try? JSONSerialization.data(withJSONObject: dict, options: [])
            let json = String(data: data ?? Data(), encoding: .utf8) ?? meta
            try? await grdb.execute("UPDATE photo_evidence SET metadata = ? WHERE id = ?", [json, photoId])
        }
    }

    func deletePhoto(_ photoId: String) async {
        if let row = try? await grdb.query("SELECT local_path, thumbnail_path FROM photo_evidence WHERE id = ?", [photoId]).first {
            if let lp = row["local_path"] as? String { try? FileManager.default.removeItem(atPath: lp) }
            if let tp = row["thumbnail_path"] as? String { try? FileManager.default.removeItem(atPath: tp) }
        }
        try? await grdb.execute("DELETE FROM photo_evidence WHERE id = ?", [photoId])
    }

    // MARK: - Helpers
    private func resized(image: UIImage, target: CGSize) async -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
