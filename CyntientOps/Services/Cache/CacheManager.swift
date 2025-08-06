//
//  CacheManager.swift
//  CyntientOps Phase 7
//
//  Thread-safe cache manager with TTL support and automatic cleanup
//  Optimized for NYC API responses and application data
//

import Foundation
import Combine

@MainActor
public final class CacheManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var itemCount: Int = 0
    @Published public var totalMemoryUsage: Int = 0
    
    // MARK: - Private Properties
    private var cache: [String: CacheItem] = [:]
    private let accessQueue = DispatchQueue(label: "cache-access", attributes: .concurrent)
    private var cleanupTimer: Timer?
    
    // Configuration
    private struct Config {
        static let defaultTTL: TimeInterval = 300 // 5 minutes
        static let maxMemorySize: Int = 50 * 1024 * 1024 // 50MB
        static let cleanupInterval: TimeInterval = 60 // 1 minute
        static let maxItemAge: TimeInterval = 3600 // 1 hour maximum
    }
    
    public init() {
        Task {
            await startPeriodicCleanup()
        }
    }
    
    // MARK: - Public Methods
    
    /// Set value with key and optional TTL
    public func set<T: Codable>(key: String, value: T, expiry: TimeInterval = 300) {
        accessQueue.async(flags: .barrier) { [weak self] in
            do {
                let data = try JSONEncoder().encode(value)
                let item = CacheItem(
                    data: data,
                    expiry: Date().addingTimeInterval(expiry),
                    lastAccessed: Date(),
                    memorySize: data.count,
                    type: String(describing: T.self)
                )
                
                self?.cache[key] = item
                
                Task { @MainActor in
                    self?.updateMetrics()
                }
                
            } catch {
                print("Failed to cache item for key \(key): \(error)")
            }
        }
    }
    
    /// Get value by key with type safety
    public func get<T: Codable>(key: String, as type: T.Type = T.self) -> T? {
        return accessQueue.sync {
            guard let item = cache[key] else { return nil }
            
            // Check expiry
            if item.expiry < Date() {
                cache.removeValue(forKey: key)
                Task { @MainActor in
                    updateMetrics()
                }
                return nil
            }
            
            // Update last accessed time
            cache[key] = item.withUpdatedAccess()
            
            do {
                let value = try JSONDecoder().decode(type, from: item.data)
                return value
            } catch {
                print("Failed to decode cached item for key \(key): \(error)")
                cache.removeValue(forKey: key)
                Task { @MainActor in
                    updateMetrics()
                }
                return nil
            }
        }
    }
    
    /// Check if key exists and is not expired
    public func contains(key: String) -> Bool {
        return accessQueue.sync {
            guard let item = cache[key] else { return false }
            
            if item.expiry < Date() {
                cache.removeValue(forKey: key)
                Task { @MainActor in
                    updateMetrics()
                }
                return false
            }
            
            return true
        }
    }
    
    /// Remove specific key
    public func remove(key: String) {
        accessQueue.async(flags: .barrier) { [weak self] in
            self?.cache.removeValue(forKey: key)
            Task { @MainActor in
                self?.updateMetrics()
            }
        }
    }
    
    /// Clear all cached items
    public func clear() {
        accessQueue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAll()
            Task { @MainActor in
                self?.updateMetrics()
            }
        }
    }
    
    /// Get cache statistics
    public func getStatistics() -> CacheStatistics {
        return accessQueue.sync {
            let totalItems = cache.count
            let expiredItems = cache.values.filter { $0.expiry < Date() }.count
            let totalMemory = cache.values.reduce(0) { $0 + $1.memorySize }
            let oldestItem = cache.values.min { $0.lastAccessed < $1.lastAccessed }
            let newestItem = cache.values.max { $0.lastAccessed < $1.lastAccessed }
            
            let typeBreakdown = Dictionary(grouping: cache.values) { $0.type }
                .mapValues { $0.count }
            
            return CacheStatistics(
                totalItems: totalItems,
                expiredItems: expiredItems,
                totalMemoryBytes: totalMemory,
                oldestItemAge: oldestItem?.lastAccessed.timeIntervalSinceNow.magnitude,
                newestItemAge: newestItem?.lastAccessed.timeIntervalSinceNow.magnitude,
                typeBreakdown: typeBreakdown
            )
        }
    }
    
    /// Start periodic cleanup task
    public func startPeriodicCleanup() async {
        while !Task.isCancelled {
            await performCleanup()
            
            // Wait for cleanup interval
            try? await Task.sleep(nanoseconds: UInt64(Config.cleanupInterval * 1_000_000_000))
        }
    }
    
    // MARK: - Private Methods
    
    private func performCleanup() async {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let now = Date()
            var removedCount = 0
            var removedMemory = 0
            
            // Remove expired items
            for (key, item) in self.cache {
                if item.expiry < now {
                    removedMemory += item.memorySize
                    removedCount += 1
                    self.cache.removeValue(forKey: key)
                }
            }
            
            // Check memory pressure
            let currentMemory = self.cache.values.reduce(0) { $0 + $1.memorySize }
            if currentMemory > Config.maxMemorySize {
                // Remove least recently accessed items
                let sortedItems = self.cache.sorted { $0.value.lastAccessed < $1.value.lastAccessed }
                let itemsToRemove = sortedItems.prefix(max(1, self.cache.count / 4)) // Remove 25%
                
                for (key, item) in itemsToRemove {
                    removedMemory += item.memorySize
                    removedCount += 1
                    self.cache.removeValue(forKey: key)
                }
            }
            
            // Remove very old items regardless of expiry
            let maxAge = Config.maxItemAge
            for (key, item) in self.cache {
                if abs(item.lastAccessed.timeIntervalSinceNow) > maxAge {
                    removedMemory += item.memorySize
                    removedCount += 1
                    self.cache.removeValue(forKey: key)
                }
            }
            
            if removedCount > 0 {
                print("🧹 Cache cleanup: removed \(removedCount) items, freed \(removedMemory) bytes")
            }
            
            Task { @MainActor in
                self.updateMetrics()
            }
        }
    }
    
    private func updateMetrics() {
        accessQueue.async { [weak self] in
            guard let self = self else { return }
            
            let count = self.cache.count
            let memory = self.cache.values.reduce(0) { $0 + $1.memorySize }
            
            Task { @MainActor in
                self.itemCount = count
                self.totalMemoryUsage = memory
            }
        }
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
}

// MARK: - Supporting Types

private struct CacheItem {
    let data: Data
    let expiry: Date
    let lastAccessed: Date
    let memorySize: Int
    let type: String
    
    func withUpdatedAccess() -> CacheItem {
        return CacheItem(
            data: data,
            expiry: expiry,
            lastAccessed: Date(),
            memorySize: memorySize,
            type: type
        )
    }
}

public struct CacheStatistics {
    public let totalItems: Int
    public let expiredItems: Int
    public let totalMemoryBytes: Int
    public let oldestItemAge: TimeInterval?
    public let newestItemAge: TimeInterval?
    public let typeBreakdown: [String: Int]
    
    public var memoryUsageMB: Double {
        return Double(totalMemoryBytes) / (1024 * 1024)
    }
    
    public var hitRatio: Double {
        let validItems = totalItems - expiredItems
        return totalItems > 0 ? Double(validItems) / Double(totalItems) : 0.0
    }
}

// MARK: - Cache Extensions for Common Types

extension CacheManager {
    
    /// Cache NYC API response with default TTL of 1 hour
    public func cacheNYCResponse<T: Codable>(_ response: T, forEndpoint endpoint: String) {
        let key = "nyc_api_\(endpoint)"
        set(key: key, value: response, expiry: 3600) // 1 hour for NYC data
    }
    
    /// Get cached NYC API response
    public func getNYCResponse<T: Codable>(_ type: T.Type, forEndpoint endpoint: String) -> T? {
        let key = "nyc_api_\(endpoint)"
        return get(key: key, as: type)
    }
    
    /// Cache worker data with shorter TTL
    public func cacheWorkerData<T: Codable>(_ data: T, forWorker workerId: String) {
        let key = "worker_\(workerId)"
        set(key: key, value: data, expiry: 600) // 10 minutes for worker data
    }
    
    /// Get cached worker data
    public func getWorkerData<T: Codable>(_ type: T.Type, forWorker workerId: String) -> T? {
        let key = "worker_\(workerId)"
        return get(key: key, as: type)
    }
    
    /// Cache building data with medium TTL
    public func cacheBuildingData<T: Codable>(_ data: T, forBuilding buildingId: String) {
        let key = "building_\(buildingId)"
        set(key: key, value: data, expiry: 1800) // 30 minutes for building data
    }
    
    /// Get cached building data
    public func getBuildingData<T: Codable>(_ type: T.Type, forBuilding buildingId: String) -> T? {
        let key = "building_\(buildingId)"
        return get(key: key, as: type)
    }
}