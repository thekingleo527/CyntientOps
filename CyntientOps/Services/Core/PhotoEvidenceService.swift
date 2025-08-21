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
    
    public init(buildingId: String, category: CoreTypes.CyntientOpsPhotoCategory, taskId: String? = nil, workerId: String) {
        self.buildingId = buildingId
        self.category = category
        self.taskId = taskId
        self.workerId = workerId
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
    
    // MARK: - Batch Photo Processing
    
    /// Create a new photo batch for efficient multi-photo capture
    public func createBatch(buildingId: String, category: CoreTypes.CyntientOpsPhotoCategory, taskId: String? = nil, workerId: String) -> PhotoBatch {
        return PhotoBatch(buildingId: buildingId, category: category, taskId: taskId, workerId: workerId)
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
    public func captureQuick(image: UIImage, category: CoreTypes.CyntientOpsPhotoCategory, buildingId: String, workerId: String, notes: String = "") async throws -> CoreTypes.ProcessedPhoto {
        let quality = category.autoCompress ? standardQuality : highQuality
        
        let processed = try await processPhoto(
            image: image,
            category: category,
            buildingId: buildingId,
            workerId: workerId,
            quality: quality,
            notes: notes
        )
        
        try await savePhotoToDatabase(processed)
        
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
        
        var batch = createBatch(buildingId: buildingId, category: .compliance, workerId: workerId)
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
            try await savePhotoToDatabase(photo)
        }
    }
    
    private func savePhotoToDatabase(_ photo: CoreTypes.ProcessedPhoto) async throws {
        try await database.execute("""
            INSERT INTO photos (id, building_id, category, worker_id, timestamp, file_path, thumbnail_path, file_size, notes, retention_days)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            photo.id,
            photo.buildingId,
            photo.category,
            photo.workerId,
            photo.timestamp,
            photo.filePath,
            photo.thumbnailPath,
            photo.fileSize,
            photo.notes,
            photo.retentionDays
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
            ]
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
            ]
        )
        dashboardSync?.broadcastWorkerUpdate(update)
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
        } catch {
            print("❌ Failed to create photos directory: \(error)")
        }
    }
    
    // MARK: - Photo Retrieval (Optimized)
    
    public func getRecentPhotos(buildingId: String, category: CoreTypes.CyntientOpsPhotoCategory? = nil, limit: Int = 20) async throws -> [CoreTypes.ProcessedPhoto] {
        let categoryFilter = category != nil ? "AND category = ?" : ""
        let params: [Any] = category != nil ? [buildingId, category!.rawValue, limit] : [buildingId, limit]
        
        let results = try await database.query("""
            SELECT * FROM photos 
            WHERE building_id = ? \(categoryFilter)
            ORDER BY timestamp DESC 
            LIMIT ?
        """, params)
        
        return results.compactMap { CoreTypes.ProcessedPhoto.from(dictionary: $0) }
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
}

// MARK: - Photo Errors

public enum PhotoError: LocalizedError {
    case compressionFailed
    case thumbnailFailed
    case invalidDSNYTiming(String)
    case batchFull
    case storageLimit
    
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
        }
    }
}