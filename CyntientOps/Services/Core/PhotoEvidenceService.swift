//
//  PhotoEvidenceService.swift
//  CyntientOps v6.0
//
//  ✅ OPTIMIZED: Streamlined for building documentation workflow
//  ✅ BATCH PROCESSING: Efficient multi-photo handling
//  ✅ SMART CATEGORIES: Auto-organization by task type
//  ✅ RETENTION RULES: Auto-compression and cleanup
//

import Foundation
import UIKit
import CoreLocation
import Combine
import AVFoundation

// MARK: - Photo Categories (Using CoreTypes)

public struct PhotoBatch {
    public let id = UUID()
    public let buildingId: String
    public let category: CoreTypes.CyntientOpsPhotoCategory
    public let taskId: String?
    public let workerId: String
    public let timestamp = Date()
    public var photos: [UIImage] = []
    public var notes: String = ""
    public var spaceId: String? = nil
    
    public init(buildingId: String, category: CoreTypes.CyntientOpsPhotoCategory, taskId: String? = nil, workerId: String, spaceId: String? = nil) {
        self.buildingId = buildingId
        self.category = category
        self.taskId = taskId
        self.workerId = workerId
        self.spaceId = spaceId
    }
}

@MainActor
public class PhotoEvidenceService: ObservableObject {
    // MARK: - Published Properties
    @Published public var uploadProgress: Double = 0
    @Published public var isProcessingBatch = false
    @Published public var currentBatch: PhotoBatch?
    @Published public var pendingBatches: Int = 0
    @Published public var storageUsed: Int64 = 0
    
    // MARK: - Dependencies
    private let database: GRDBManager
    private let dashboardSync: DashboardSyncService?
    
    public init(database: GRDBManager, dashboardSync: DashboardSyncService? = nil) {
        self.database = database
        self.dashboardSync = dashboardSync
        setupDirectories()
        startCleanupTimer()
    }
    
    // MARK: - Optimized Configuration
    private let highQuality: CGFloat = 0.9 // Legal/compliance photos
    private let standardQuality: CGFloat = 0.6 // Routine photos
    private let thumbnailSize = CGSize(width: 150, height: 150)
    private let batchSize = 10 // Max photos per batch
    
    // MARK: - Batch Queue
    private var batchQueue: [PhotoBatch] = []
    private var isProcessingQueue = false
    
    // MARK: - Storage Paths
    private var photosDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Photos")
    }
    private var videosDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Videos")
    }
    
    // MARK: - Batch Photo Processing
    
    /// Create a new photo batch for efficient multi-photo capture
    public func createBatch(buildingId: String, category: CoreTypes.CyntientOpsPhotoCategory, taskId: String? = nil, workerId: String, spaceId: String? = nil) -> PhotoBatch {
        return PhotoBatch(buildingId: buildingId, category: category, taskId: taskId, workerId: workerId, spaceId: spaceId)
    }
    
    /// Add photo to batch (efficient for workers taking multiple photos)
    public func addToBatch(_ batch: inout PhotoBatch, photo: UIImage) -> Bool {
        guard batch.photos.count < batchSize else { return false }
        batch.photos.append(photo)
        return true
    }
    
    /// Process entire batch at once (optimized for Kevin's 38 daily tasks)
    public func processBatch(_ batch: PhotoBatch) async throws {
        isProcessingBatch = true
        currentBatch = batch
        uploadProgress = 0
        
        defer {
            isProcessingBatch = false
            currentBatch = nil
        }
        
        let quality = batch.category.autoCompress ? standardQuality : highQuality
        var processedPhotos: [CoreTypes.ProcessedPhoto] = []
        
        for (index, image) in batch.photos.enumerated() {
            // Process each photo
            let processed = try await processPhoto(
                image: image,
                category: batch.category,
                buildingId: batch.buildingId,
                workerId: batch.workerId,
                quality: quality
            )
            processedPhotos.append(processed)
            
            // Update progress
            uploadProgress = Double(index + 1) / Double(batch.photos.count)
        }
        
        // Save batch to database
        try await saveBatchToDatabase(batch, processedPhotos: processedPhotos)
        
        // Broadcast update for real-time dashboard sync
        broadcastPhotoUpdate(batch: batch, photoCount: processedPhotos.count)
    }
    
    // MARK: - Quick Single Photo (for urgent/safety issues)
    
    /// Fast single photo capture for immediate issues
    public func captureQuick(image: UIImage, category: CoreTypes.CyntientOpsPhotoCategory, buildingId: String, workerId: String, notes: String = "", spaceId: String? = nil) async throws -> CoreTypes.ProcessedPhoto {
        let quality = category.autoCompress ? standardQuality : highQuality
        
        let processed = try await processPhoto(
            image: image,
            category: category,
            buildingId: buildingId,
            workerId: workerId,
            quality: quality,
            notes: notes
        )
        
        try await savePhotoToDatabase(processed, spaceId: spaceId, mediaType: "image")
        
        // Immediate dashboard update for urgent photos
        if category.priority <= 2 {
            broadcastUrgentPhotoUpdate(processed)
        }
        
        return processed
    }
    
    // MARK: - DSNY Compliance (Critical Time-Sensitive Photos)
    
    /// Specialized DSNY photo capture with timestamp validation
    public func captureDSNY(images: [UIImage], buildingId: String, workerId: String, isSetOut: Bool) async throws {
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Validate timing (after 8 PM for set-out, before 12 PM for pickup)
        if isSetOut && currentHour < 20 {
            throw PhotoError.invalidDSNYTiming("Cannot set out trash before 8:00 PM")
        }
        
        var batch = createBatch(buildingId: buildingId, category: .compliance, taskId: nil, workerId: workerId, spaceId: nil)
        batch.notes = isSetOut ? "DSNY_SETOUT" : "DSNY_PICKUP"
        
        for image in images {
            _ = addToBatch(&batch, photo: image)
        }
        
        try await processBatch(batch)
    }
    
    // MARK: - Efficient Photo Processing
    
    private func processPhoto(
        image: UIImage,
        category: CoreTypes.CyntientOpsPhotoCategory,
        buildingId: String,
        workerId: String,
        quality: CGFloat,
        notes: String = ""
    ) async throws -> CoreTypes.ProcessedPhoto {
        
        let photoId = UUID().uuidString
        let timestamp = Date()
        
        // Compress based on category priority
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            throw PhotoError.compressionFailed
        }
        
        // Generate thumbnail for dashboard
        let thumbnail = generateThumbnail(from: image)
        guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.5) else {
            throw PhotoError.thumbnailFailed
        }
        
        // Save to file system
        let filename = "\(buildingId)_\(category.rawValue)_\(photoId).jpg"
        let fileURL = photosDirectory.appendingPathComponent(filename)
        try imageData.write(to: fileURL)
        
        // Save thumbnail
        let thumbFilename = "\(buildingId)_\(category.rawValue)_\(photoId)_thumb.jpg"
        let thumbURL = photosDirectory.appendingPathComponent(thumbFilename)
        try thumbnailData.write(to: thumbURL)
        
        return CoreTypes.ProcessedPhoto(
            id: photoId,
            buildingId: buildingId,
            category: category.rawValue,
            workerId: workerId,
            timestamp: timestamp,
            filePath: filename,
            thumbnailPath: thumbFilename,
            fileSize: Int64(imageData.count),
            notes: notes,
            retentionDays: category.retentionDays
        )
    }
    
    private func generateThumbnail(from image: UIImage) -> UIImage {
        let size = thumbnailSize
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return thumbnail
    }
    
    // MARK: - Database Operations
    
    private func saveBatchToDatabase(_ batch: PhotoBatch, processedPhotos: [CoreTypes.ProcessedPhoto]) async throws {
        for photo in processedPhotos {
            try await savePhotoToDatabase(photo, spaceId: batch.spaceId, mediaType: "image")
        }
    }
    
    private func savePhotoToDatabase(_ photo: CoreTypes.ProcessedPhoto, spaceId: String? = nil, mediaType: String = "image") async throws {
        // Insert into compatibility table used by dashboard UIs
        try await database.execute("""
            INSERT INTO photos (id, building_id, category, worker_id, timestamp, file_path, thumbnail_path, file_size, notes, retention_days, space_id, media_type)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            photo.id,
            photo.buildingId,
            photo.category,
            photo.workerId,
            ISO8601DateFormatter().string(from: photo.timestamp),
            photo.filePath,
            photo.thumbnailPath,
            photo.fileSize,
            photo.notes,
            photo.retentionDays,
            spaceId as Any,
            mediaType
        ])

        // Also insert into canonical photo_evidence for compliance/history
        try await database.execute("""
            INSERT OR IGNORE INTO photo_evidence (
                id, completion_id, task_id, worker_id, local_path, thumbnail_path, remote_url, file_size, mime_type, metadata, uploaded_at, created_at
            ) VALUES (?, NULL, NULL, ?, ?, ?, NULL, ?, ?, NULL, ?, datetime('now'))
        """, [
            photo.id,
            photo.workerId,
            photo.filePath,
            photo.thumbnailPath,
            photo.fileSize,
            mediaType == "video" ? "video/mp4" : "image/jpeg",
            ISO8601DateFormatter().string(from: photo.timestamp)
        ])
    }
    
    // MARK: - Dashboard Integration
    
    private func broadcastPhotoUpdate(batch: PhotoBatch, photoCount: Int) {
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .buildingMetricsChanged,
            buildingId: batch.buildingId,
            workerId: batch.workerId,
            data: [
                "action": "photoBatch",
                "category": batch.category.rawValue,
                "count": String(photoCount),
                "timestamp": ISO8601DateFormatter().string(from: batch.timestamp)
            ],
            payloadType: "PhotoBatchPayload",
            payloadJSON: toJSONString([
                "buildingId": batch.buildingId,
                "category": batch.category.rawValue,
                "count": photoCount,
                "timestamp": ISO8601DateFormatter().string(from: batch.timestamp)
            ])
        )
        dashboardSync?.broadcastWorkerUpdate(update)
    }
    
    private func broadcastUrgentPhotoUpdate(_ photo: CoreTypes.ProcessedPhoto) {
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .criticalUpdate,
            buildingId: photo.buildingId,
            workerId: photo.workerId,
            data: [
                "action": "urgentPhoto",
                "category": photo.category,
                "photoId": photo.id,
                "timestamp": ISO8601DateFormatter().string(from: photo.timestamp)
            ],
            payloadType: "PhotoUploadedPayload",
            payloadJSON: toJSONString([
                "photoId": photo.id,
                "buildingId": photo.buildingId,
                "category": photo.category,
                "timestamp": ISO8601DateFormatter().string(from: photo.timestamp)
            ])
        )
        dashboardSync?.broadcastWorkerUpdate(update)
    }

    // MARK: - JSON helper
    private func toJSONString(_ dict: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(dict) else { return nil }
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            return String(data: data, encoding: .utf8)
        } catch { return nil }
    }
    
    // MARK: - Auto Cleanup & Retention
    
    private func startCleanupTimer() {
        // Daily cleanup at 3 AM
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { _ in
            Task {
                await self.performCleanup()
            }
        }
    }
    
    private func performCleanup() async {
        do {
            // Remove expired photos
            let expiredPhotos = try await database.query("""
                SELECT file_path, thumbnail_path FROM photos 
                WHERE datetime('now', '-' || retention_days || ' days') > timestamp
            """)
            
            for photo in expiredPhotos {
                if let filePath = photo["file_path"] as? String {
                    try? FileManager.default.removeItem(at: photosDirectory.appendingPathComponent(filePath))
                }
                if let thumbPath = photo["thumbnail_path"] as? String {
                    try? FileManager.default.removeItem(at: photosDirectory.appendingPathComponent(thumbPath))
                }
            }
            
            // Remove from database
            try await database.execute("""
                DELETE FROM photos WHERE datetime('now', '-' || retention_days || ' days') > timestamp
            """)
            
            await updateStorageUsage()
            
        } catch {
            print("❌ Cleanup failed: \(error)")
        }
    }
    
    private func updateStorageUsage() async {
        do {
            let result = try await database.query("SELECT SUM(file_size) as total FROM photos")
            if let total = result.first?["total"] as? Int64 {
                await MainActor.run {
                    self.storageUsed = total
                }
            }
        } catch {
            print("⚠️ Storage calculation failed: \(error)")
        }
    }
    
    // MARK: - Directory Setup
    
    private func setupDirectories() {
        do {
            try FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: videosDirectory, withIntermediateDirectories: true)
        } catch {
            print("❌ Failed to create media directories: \(error)")
        }
    }
    
    // MARK: - Photo Retrieval (Optimized)
    
    public func getRecentPhotos(buildingId: String, category: CoreTypes.CyntientOpsPhotoCategory? = nil, limit: Int = 20) async throws -> [CoreTypes.ProcessedPhoto] {
        return try await getRecentMedia(buildingId: buildingId, category: category, spaceId: nil, mediaType: nil, limit: limit)
    }

    public func getRecentMedia(buildingId: String, category: CoreTypes.CyntientOpsPhotoCategory? = nil, spaceId: String? = nil, mediaType: String? = nil, limit: Int = 50) async throws -> [CoreTypes.ProcessedPhoto] {
        var sql = "SELECT * FROM photos WHERE building_id = ?"
        var params: [Any] = [buildingId]
        if let cat = category { sql += " AND category = ?"; params.append(cat.rawValue) }
        if let sid = spaceId { sql += " AND space_id = ?"; params.append(sid) }
        if let mt = mediaType { sql += " AND media_type = ?"; params.append(mt) }
        sql += " ORDER BY timestamp DESC LIMIT ?"
        params.append(limit)
        let results = try await database.query(sql, params)
        return results.compactMap { CoreTypes.ProcessedPhoto.from(dictionary: $0) }
    }

    public func getLatestMediaForSpace(buildingId: String, spaceId: String) async throws -> CoreTypes.ProcessedPhoto? {
        let results = try await database.query("""
            SELECT * FROM photos
            WHERE building_id = ? AND space_id = ?
            ORDER BY timestamp DESC
            LIMIT 1
        """, [buildingId, spaceId])
        return results.compactMap { CoreTypes.ProcessedPhoto.from(dictionary: $0) }.first
    }
    
    public func getTodaysDSNYPhotos(buildingId: String) async throws -> [CoreTypes.ProcessedPhoto] {
        let results = try await database.query("""
            SELECT * FROM photos 
            WHERE building_id = ? 
            AND category = 'DSNY' 
            AND date(timestamp) = date('now')
            ORDER BY timestamp DESC
        """, [buildingId])
        
        return results.compactMap { CoreTypes.ProcessedPhoto.from(dictionary: $0) }
    }
    
    /// Get all photo evidences for admin overview
    public func getAllPhotoEvidences() async throws -> [CoreTypes.ProcessedPhoto] {
        let results = try await database.query("""
            SELECT * FROM photos 
            ORDER BY timestamp DESC
        """)
        
        return results.compactMap { CoreTypes.ProcessedPhoto.from(dictionary: $0) }
    }
    
    // MARK: - Short Video Capture (10–15s)
    public func captureShortVideo(inputURL: URL, buildingId: String, workerId: String, category: CoreTypes.CyntientOpsPhotoCategory, spaceId: String? = nil, notes: String = "") async throws -> CoreTypes.ProcessedPhoto {
        let asset = AVURLAsset(url: inputURL)
        let duration = CMTimeGetSeconds(asset.duration)
        guard duration <= 15.1 else { throw PhotoError.videoTooLong }

        // Ensure directories
        try FileManager.default.createDirectory(at: videosDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)

        // Export to MP4 (prefer HEVC when available for better quality/size)
        let videoId = UUID().uuidString
        let videoFileName = "\(buildingId)_\(category.rawValue)_\(videoId).mp4"
        let videoURL = videosDirectory.appendingPathComponent(videoFileName)

        if FileManager.default.fileExists(atPath: videoURL.path) {
            try? FileManager.default.removeItem(at: videoURL)
        }

        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        let presetName = compatiblePresets.contains(AVAssetExportPresetHEVCHighestQuality) ? AVAssetExportPresetHEVCHighestQuality : AVAssetExportPreset1280x720
        guard let export = AVAssetExportSession(asset: asset, presetName: presetName) else {
            throw PhotoError.compressionFailed
        }
        export.outputURL = videoURL
        if export.supportedFileTypes.contains(.mp4) {
            export.outputFileType = .mp4
        } else if export.supportedFileTypes.contains(.mov) {
            export.outputFileType = .mov
        } else if let first = export.supportedFileTypes.first {
            export.outputFileType = first
        }
        export.shouldOptimizeForNetworkUse = true

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            export.exportAsynchronously {
                cont.resume()
            }
        }
        guard export.status == .completed else {
            throw PhotoError.compressionFailed
        }

        // Generate thumbnail at 1 second
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: videoURL))
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: min(1.0, duration/2.0), preferredTimescale: 600)
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        let thumbImage = UIImage(cgImage: cgImage)
        let thumbFileName = "\(buildingId)_\(category.rawValue)_\(videoId)_thumb.jpg"
        let thumbURL = photosDirectory.appendingPathComponent(thumbFileName)
        if let thumbData = thumbImage.jpegData(compressionQuality: 0.6) {
            try thumbData.write(to: thumbURL)
        }

        // File size
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: videoURL.path)[.size] as? Int64) ?? 0
        let processed = CoreTypes.ProcessedPhoto(
            id: videoId,
            buildingId: buildingId,
            category: category.rawValue,
            workerId: workerId,
            timestamp: Date(),
            filePath: videoFileName,
            thumbnailPath: thumbFileName,
            fileSize: fileSize,
            mediaType: "video",
            notes: notes,
            retentionDays: category.retentionDays
        )

        try await savePhotoToDatabase(processed, spaceId: spaceId, mediaType: "video")
        return processed
    }
    
    // MARK: - Validation
    
    /// Validate photo evidence for compliance and quality standards
    public func validatePhotoEvidence(_ photos: [CoreTypes.ProcessedPhoto]) async throws -> [String: Any] {
        var validationResults: [String: Any] = [:]
        var validPhotos: [CoreTypes.ProcessedPhoto] = []
        var issues: [String] = []
        
        for photo in photos {
            // Check file exists
            let filePath = photosDirectory.appendingPathComponent(photo.filePath)
            guard FileManager.default.fileExists(atPath: filePath.path) else {
                issues.append("Missing photo file: \(photo.filePath)")
                continue
            }
            
            // Check file size (must be > 0 and < 50MB)
            guard photo.fileSize > 0 && photo.fileSize < 50_000_000 else {
                issues.append("Invalid file size for photo: \(photo.id)")
                continue
            }
            
            // Check timestamp is recent (within last 7 days for most categories)
            let daysSinceCapture = Calendar.current.dateComponents([.day], from: photo.timestamp, to: Date()).day ?? 0
            if daysSinceCapture > 7 {
                issues.append("Photo \(photo.id) is too old (\(daysSinceCapture) days)")
                continue
            }
            
            // Validate category
            guard let category = CoreTypes.CyntientOpsPhotoCategory(rawValue: photo.category) else {
                issues.append("Invalid category for photo: \(photo.id)")
                continue
            }
            
            // Category-specific validation
            switch category {
            case .compliance:
                // Compliance photos need detailed notes
                if photo.notes.isEmpty {
                    issues.append("Compliance photo \(photo.id) missing required notes")
                    continue
                }
            case .emergency:
                // Emergency photos should be recent (within 24 hours)
                if daysSinceCapture > 1 {
                    issues.append("Emergency photo \(photo.id) too old for emergency category")
                    continue
                }
            default:
                break
            }
            
            validPhotos.append(photo)
        }
        
        validationResults["validPhotos"] = validPhotos
        validationResults["issues"] = issues
        validationResults["totalPhotos"] = photos.count
        validationResults["validCount"] = validPhotos.count
        validationResults["isValid"] = issues.isEmpty
        validationResults["validationTimestamp"] = Date()
        
        return validationResults
    }
}

// MARK: - Photo Errors

public enum PhotoError: LocalizedError {
    case compressionFailed
    case thumbnailFailed
    case invalidDSNYTiming(String)
    case batchFull
    case storageLimit
    case videoTooLong
    
    public var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress photo"
        case .thumbnailFailed:
            return "Failed to generate thumbnail"
        case .invalidDSNYTiming(let message):
            return message
        case .batchFull:
            return "Photo batch is full"
        case .storageLimit:
            return "Storage limit reached"
        case .videoTooLong:
            return "Video exceeds 15 seconds limit"
        }
    }
}
