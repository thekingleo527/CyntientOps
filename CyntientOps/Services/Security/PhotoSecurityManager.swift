//
//  PhotoSecurityManager.swift
//  CyntientOps Production Security
//
//  Photo encryption, TTL management, and secure cleanup service
//  Critical for production readiness - handles 24-hour photo TTL requirement
//

import Foundation
import CryptoKit
import UIKit

@MainActor
public class PhotoSecurityManager: ObservableObject {
    public static let shared = PhotoSecurityManager()
    
    // MARK: - Published Properties
    @Published public var cleanupStatus: CleanupStatus = .idle
    @Published public var expiredPhotosCount: Int = 0
    
    public enum CleanupStatus {
        case idle
        case scanning
        case cleaning(Int, Int) // current, total
        case completed
        case error(String)
    }
    
    // MARK: - Configuration
    private struct SecurityConfig {
        static let photoTTL: TimeInterval = 24 * 60 * 60 // 24 hours
        static let encryptionKeySize = 32 // 256-bit AES
        static let cleanupInterval: TimeInterval = 60 * 60 // 1 hour
        static let emergencyCleanupThreshold = 1000 // Max photos before emergency cleanup
    }
    
    // MARK: - Dependencies
    private let grdbManager = GRDBManager.shared
    private let fileManager = FileManager.default
    
    // MARK: - Encryption Keys
    private let masterKey: SymmetricKey
    private var cleanupTimer: Timer?
    
    private init() {
        // Initialize master encryption key (in production, load from secure keychain)
        do {
            let keyData = try KeychainManager.shared.getData(for: "photo_master_key")
            self.masterKey = SymmetricKey(data: keyData)
        } catch {
            // Generate new key and store in keychain
            self.masterKey = SymmetricKey(size: .bits256)
            try? KeychainManager.shared.save(
                self.masterKey.withUnsafeBytes { Data($0) },
                for: "photo_master_key"
            )
        }
        
        // Start automatic cleanup
        startPeriodicCleanup()
        
        // Schedule immediate cleanup check
        Task {
            await performCleanup()
        }
    }
    
    // MARK: - Public Methods
    
    /// Encrypt photo data with TTL metadata
    public func encryptPhoto(
        _ imageData: Data,
        photoId: String,
        ttlHours: Int = 24
    ) throws -> EncryptedPhotoData {
        
        // Create photo metadata with expiration
        let expirationDate = Date().addingTimeInterval(TimeInterval(ttlHours * 3600))
        let metadata = PhotoMetadata(
            photoId: photoId,
            createdAt: Date(),
            expiresAt: expirationDate,
            originalSize: imageData.count
        )
        
        // Serialize metadata
        let metadataData = try JSONEncoder().encode(metadata)
        
        // Create combined payload: metadata + image data
        var payload = Data()
        payload.append(UInt32(metadataData.count).bigEndianData)
        payload.append(metadataData)
        payload.append(imageData)
        
        // Generate unique nonce for this photo
        let nonce = AES.GCM.Nonce()
        
        // Encrypt the payload
        let sealedBox = try AES.GCM.seal(payload, using: masterKey, nonce: nonce)
        
        return EncryptedPhotoData(
            photoId: photoId,
            encryptedData: sealedBox.ciphertext,
            nonce: nonce.withUnsafeBytes { Data($0) },
            tag: sealedBox.tag,
            expiresAt: expirationDate,
            encryptedSize: sealedBox.ciphertext.count
        )
    }
    
    /// Decrypt photo data if not expired
    public func decryptPhoto(_ encryptedData: EncryptedPhotoData) throws -> (Data, PhotoMetadata) {
        // Check if photo has expired
        if encryptedData.expiresAt < Date() {
            throw PhotoSecurityError.photoExpired
        }
        
        // Reconstruct the sealed box
        let nonce = try AES.GCM.Nonce(data: encryptedData.nonce)
        let sealedBox = try AES.GCM.SealedBox(
            nonce: nonce,
            ciphertext: encryptedData.encryptedData,
            tag: encryptedData.tag
        )
        
        // Decrypt the payload
        let decryptedPayload = try AES.GCM.open(sealedBox, using: masterKey)
        
        // Extract metadata size
        guard decryptedPayload.count >= 4 else {
            throw PhotoSecurityError.corruptedData
        }
        
        let metadataSize = UInt32(bigEndianData: decryptedPayload.prefix(4))
        guard decryptedPayload.count >= 4 + Int(metadataSize) else {
            throw PhotoSecurityError.corruptedData
        }
        
        // Extract metadata
        let metadataData = decryptedPayload.dropFirst(4).prefix(Int(metadataSize))
        let metadata = try JSONDecoder().decode(PhotoMetadata.self, from: metadataData)
        
        // Extract image data
        let imageData = decryptedPayload.dropFirst(4 + Int(metadataSize))
        
        return (Data(imageData), metadata)
    }
    
    /// Save encrypted photo to secure storage
    public func saveSecurePhoto(
        _ encryptedData: EncryptedPhotoData,
        to directory: URL
    ) throws -> URL {
        
        let secureFileName = "\(encryptedData.photoId).secure"
        let secureFilePath = directory.appendingPathComponent(secureFileName)
        
        // Create secure file structure
        var fileData = Data()
        fileData.append(encryptedData.encryptedData)
        fileData.append(encryptedData.nonce)
        fileData.append(encryptedData.tag)
        
        // Add expiration timestamp
        let expirationTimestamp = encryptedData.expiresAt.timeIntervalSince1970
        fileData.append(expirationTimestamp.bigEndianData)
        
        // Write to file with secure attributes
        try fileData.write(to: secureFilePath)
        
        // Set file attributes for security (no backup, restricted access)
        try fileManager.setAttributes([
            .protectionKey: FileProtectionType.completeUnlessOpen,
            .extensionHidden: true
        ], ofItemAtPath: secureFilePath.path)
        
        return secureFilePath
    }
    
    /// Load encrypted photo from secure storage
    public func loadSecurePhoto(from filePath: URL) throws -> EncryptedPhotoData {
        let fileData = try Data(contentsOf: filePath)
        
        // Extract components (in reverse order)
        guard fileData.count >= 16 + 12 + 8 else { // min: tag + nonce + timestamp
            throw PhotoSecurityError.corruptedData
        }
        
        let timestampData = fileData.suffix(8)
        let expirationTimestamp = TimeInterval(bigEndianData: timestampData)
        let expiresAt = Date(timeIntervalSince1970: expirationTimestamp)
        
        let tagStart = fileData.count - 8 - 16
        let tag = fileData[tagStart..<(tagStart + 16)]
        
        let nonceStart = fileData.count - 8 - 16 - 12
        let nonce = fileData[nonceStart..<(nonceStart + 12)]
        
        let encryptedData = fileData.prefix(nonceStart)
        
        let photoId = filePath.deletingPathExtension().lastPathComponent
        
        return EncryptedPhotoData(
            photoId: photoId,
            encryptedData: encryptedData,
            nonce: nonce,
            tag: tag,
            expiresAt: expiresAt,
            encryptedSize: encryptedData.count
        )
    }
    
    /// Perform cleanup of expired photos
    public func performCleanup() async {
        cleanupStatus = .scanning
        
        do {
            // Find expired photos in database
            let expiredPhotos = try await findExpiredPhotos()
            expiredPhotosCount = expiredPhotos.count
            
            if expiredPhotos.isEmpty {
                cleanupStatus = .idle
                print("✅ Photo cleanup: No expired photos found")
                return
            }
            
            cleanupStatus = .cleaning(0, expiredPhotos.count)
            
            var cleanedCount = 0
            for (index, photo) in expiredPhotos.enumerated() {
                do {
                    // Delete file
                    if fileManager.fileExists(atPath: photo.localPath) {
                        try fileManager.removeItem(atPath: photo.localPath)
                    }
                    
                    // Delete thumbnail
                    if let thumbnailPath = photo.thumbnailPath,
                       fileManager.fileExists(atPath: thumbnailPath) {
                        try fileManager.removeItem(atPath: thumbnailPath)
                    }
                    
                    // Remove from database
                    try await grdbManager.execute(
                        "DELETE FROM photo_evidence WHERE id = ?",
                        [photo.id]
                    )
                    
                    cleanedCount += 1
                    cleanupStatus = .cleaning(cleanedCount, expiredPhotos.count)
                    
                } catch {
                    print("Failed to clean up photo \(photo.id): \(error)")
                }
            }
            
            cleanupStatus = .completed
            print("✅ Photo cleanup completed: \(cleanedCount)/\(expiredPhotos.count) photos cleaned")
            
            // Reset status after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.cleanupStatus = .idle
            }
            
        } catch {
            cleanupStatus = .error(error.localizedDescription)
            print("❌ Photo cleanup failed: \(error)")
        }
    }
    
    /// Emergency cleanup when storage is critically low
    public func emergencyCleanup() async {
        print("🚨 Performing emergency photo cleanup")
        
        do {
            // Find all photos older than 12 hours (half TTL)
            let emergencyExpired = try await findPhotosOlderThan(hours: 12)
            
            for photo in emergencyExpired.prefix(100) { // Limit to 100 at once
                try? fileManager.removeItem(atPath: photo.localPath)
                if let thumbnailPath = photo.thumbnailPath {
                    try? fileManager.removeItem(atPath: thumbnailPath)
                }
                try? await grdbManager.execute(
                    "DELETE FROM photo_evidence WHERE id = ?",
                    [photo.id]
                )
            }
            
            print("🚨 Emergency cleanup: removed \(min(emergencyExpired.count, 100)) photos")
            
        } catch {
            print("❌ Emergency cleanup failed: \(error)")
        }
    }
    
    /// Get security statistics
    public func getSecurityStats() async -> SecurityStats {
        do {
            let totalPhotos = try await grdbManager.query("SELECT COUNT(*) as count FROM photo_evidence")
                .first?["count"] as? Int64 ?? 0
            
            let expiredPhotos = try await findExpiredPhotos().count
            
            let storageUsed = try calculateStorageUsage()
            
            return SecurityStats(
                totalPhotos: Int(totalPhotos),
                expiredPhotos: expiredPhotos,
                storageUsedMB: storageUsed,
                lastCleanup: Date(), // TODO: Store actual last cleanup time
                encryptionEnabled: true
            )
            
        } catch {
            return SecurityStats(
                totalPhotos: 0,
                expiredPhotos: 0,
                storageUsedMB: 0,
                lastCleanup: nil,
                encryptionEnabled: false
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func startPeriodicCleanup() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: SecurityConfig.cleanupInterval, repeats: true) { _ in
            Task {
                await self.performCleanup()
            }
        }
    }
    
    private func findExpiredPhotos() async throws -> [ExpiredPhoto] {
        let rows = try await grdbManager.query("""
            SELECT pe.id, pe.local_path, pe.thumbnail_path, pe.created_at
            FROM photo_evidence pe
            WHERE datetime(pe.created_at, '+24 hours') < datetime('now')
        """)
        
        return rows.compactMap { row in
            guard let id = row["id"] as? String,
                  let localPath = row["local_path"] as? String else {
                return nil
            }
            
            return ExpiredPhoto(
                id: id,
                localPath: localPath,
                thumbnailPath: row["thumbnail_path"] as? String
            )
        }
    }
    
    private func findPhotosOlderThan(hours: Int) async throws -> [ExpiredPhoto] {
        let rows = try await grdbManager.query("""
            SELECT pe.id, pe.local_path, pe.thumbnail_path, pe.created_at
            FROM photo_evidence pe
            WHERE datetime(pe.created_at, '+\(hours) hours') < datetime('now')
        """)
        
        return rows.compactMap { row in
            guard let id = row["id"] as? String,
                  let localPath = row["local_path"] as? String else {
                return nil
            }
            
            return ExpiredPhoto(
                id: id,
                localPath: localPath,
                thumbnailPath: row["thumbnail_path"] as? String
            )
        }
    }
    
    private func calculateStorageUsage() throws -> Double {
        let evidenceDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Evidence")
        
        guard let enumerator = fileManager.enumerator(at: evidenceDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: UInt64 = 0
        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            totalSize += UInt64(resourceValues.fileSize ?? 0)
        }
        
        return Double(totalSize) / (1024 * 1024) // Convert to MB
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
}

// MARK: - Supporting Types

public struct EncryptedPhotoData {
    public let photoId: String
    public let encryptedData: Data
    public let nonce: Data
    public let tag: Data
    public let expiresAt: Date
    public let encryptedSize: Int
}

public struct PhotoMetadata: Codable {
    public let photoId: String
    public let createdAt: Date
    public let expiresAt: Date
    public let originalSize: Int
}

public struct SecurityStats {
    public let totalPhotos: Int
    public let expiredPhotos: Int
    public let storageUsedMB: Double
    public let lastCleanup: Date?
    public let encryptionEnabled: Bool
}

private struct ExpiredPhoto {
    let id: String
    let localPath: String
    let thumbnailPath: String?
}

public enum PhotoSecurityError: LocalizedError {
    case photoExpired
    case corruptedData
    case encryptionFailed
    case decryptionFailed
    case keyGenerationFailed
    
    public var errorDescription: String? {
        switch self {
        case .photoExpired:
            return "Photo has exceeded 24-hour retention period"
        case .corruptedData:
            return "Photo data is corrupted or invalid"
        case .encryptionFailed:
            return "Failed to encrypt photo data"
        case .decryptionFailed:
            return "Failed to decrypt photo data"
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        }
    }
}

// MARK: - Data Extensions

extension UInt32 {
    var bigEndianData: Data {
        return withUnsafeBytes(of: self.bigEndian) { Data($0) }
    }
    
    init(bigEndianData: Data) {
        self = bigEndianData.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
    }
}

extension TimeInterval {
    var bigEndianData: Data {
        return withUnsafeBytes(of: self) { Data($0) }
    }
    
    init(bigEndianData: Data) {
        self = bigEndianData.withUnsafeBytes { $0.load(as: TimeInterval.self) }
    }
}

// Note: Using KeychainManager from Services/Configuration/KeychainManager.swift