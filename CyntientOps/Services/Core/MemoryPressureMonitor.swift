//
//  MemoryPressureMonitor.swift
//  CyntientOps
//
//  💾 MEMORY MANAGEMENT: Prevents simulator crashes by monitoring memory pressure
//  🛡️ CIRCUIT BREAKER: Disables heavy features when memory is low
//

import Foundation
import os.log

@MainActor
public final class MemoryPressureMonitor: ObservableObject {
    public static let shared = MemoryPressureMonitor()
    
    @Published public private(set) var memoryPressureLevel: MemoryPressureLevel = .normal
    @Published public private(set) var isMemoryCritical = false
    
    private var pressureSource: DispatchSourceMemoryPressure?
    private let logger = os.Logger(subsystem: "CyntientOps", category: "Memory")
    
    // Circuit breakers
    @Published public private(set) var backgroundTasksDisabled = false
    @Published public private(set) var imageLoadingDisabled = false
    @Published public private(set) var complexAnimationsDisabled = false
    @Published public private(set) var apiCallsThrottled = false
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        pressureSource?.cancel()
    }
    
    private func startMonitoring() {
        pressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.normal, .warning, .critical],
            queue: DispatchQueue.main
        )
        
        pressureSource?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            let event = self.pressureSource?.mask ?? []
            
            if event.contains(.critical) {
                self.handleCriticalMemoryPressure()
            } else if event.contains(.warning) {
                self.handleWarningMemoryPressure()
            } else if event.contains(.normal) {
                self.handleNormalMemoryPressure()
            }
        }
        
        pressureSource?.resume()
        logger.info("Memory pressure monitoring started")
    }
    
    private func handleCriticalMemoryPressure() {
        logger.critical("Critical memory pressure detected - enabling all circuit breakers")
        
        memoryPressureLevel = .critical
        isMemoryCritical = true
        
        // Enable all circuit breakers
        backgroundTasksDisabled = true
        imageLoadingDisabled = true
        complexAnimationsDisabled = true
        apiCallsThrottled = true
        
        // Emergency cleanup
        performEmergencyCleanup()
        
        // Post notification for other components
        NotificationCenter.default.post(
            name: .memoryPressureCritical,
            object: nil
        )
    }
    
    private func handleWarningMemoryPressure() {
        logger.warning("Memory pressure warning - enabling selective circuit breakers")
        
        memoryPressureLevel = .warning
        isMemoryCritical = false
        
        // Enable some circuit breakers
        backgroundTasksDisabled = true
        imageLoadingDisabled = true
        complexAnimationsDisabled = false
        apiCallsThrottled = true
        
        // Moderate cleanup
        performModerateCleanup()
        
        NotificationCenter.default.post(
            name: .memoryPressureWarning,
            object: nil
        )
    }
    
    private func handleNormalMemoryPressure() {
        logger.info("Memory pressure normalized - disabling circuit breakers")
        
        memoryPressureLevel = .normal
        isMemoryCritical = false
        
        // Disable circuit breakers gradually
        Task {
            // Wait a bit before re-enabling features
            try? await Task.sleep(for: .seconds(2))
            
            await MainActor.run {
                self.backgroundTasksDisabled = false
                self.imageLoadingDisabled = false
                self.complexAnimationsDisabled = false
                self.apiCallsThrottled = false
            }
        }
        
        NotificationCenter.default.post(
            name: .memoryPressureNormal,
            object: nil
        )
    }
    
    private func performEmergencyCleanup() {
        // Clear image caches
        URLCache.shared.removeAllCachedResponses()
        
        // Force garbage collection
        autoreleasepool {
            // Trigger any pending releases
        }
        
        // Clear query cache
        NotificationCenter.default.post(
            name: .clearQueryCache,
            object: nil
        )
        
        logger.info("Emergency memory cleanup completed")
    }
    
    private func performModerateCleanup() {
        // Clear old cached responses
        URLCache.shared.removeCachedResponses(since: Date().addingTimeInterval(-300))
        
        logger.info("Moderate memory cleanup completed")
    }
    
    /// Check if feature should be disabled due to memory pressure
    public func shouldDisableFeature(_ feature: MemoryIntensiveFeature) -> Bool {
        switch feature {
        case .backgroundTasks:
            return backgroundTasksDisabled
        case .imageLoading:
            return imageLoadingDisabled
        case .complexAnimations:
            return complexAnimationsDisabled
        case .apiCalls:
            return apiCallsThrottled
        case .heavyComputation:
            return memoryPressureLevel == .critical
        }
    }
    
    /// Get current memory usage (approximate)
    public func getCurrentMemoryUsage() -> MemoryUsage {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / 1024 / 1024 // MB
            return MemoryUsage(usedMB: usedMemory, pressureLevel: memoryPressureLevel)
        } else {
            return MemoryUsage(usedMB: 0, pressureLevel: memoryPressureLevel)
        }
    }
}

// MARK: - Supporting Types

public enum MemoryPressureLevel: String, CaseIterable {
    case normal = "normal"
    case warning = "warning" 
    case critical = "critical"
}

public enum MemoryIntensiveFeature {
    case backgroundTasks
    case imageLoading
    case complexAnimations
    case apiCalls
    case heavyComputation
}

public struct MemoryUsage {
    public let usedMB: Double
    public let pressureLevel: MemoryPressureLevel
    
    public var isHigh: Bool {
        return usedMB > 150 || pressureLevel != .normal
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let memoryPressureCritical = Notification.Name("memoryPressureCritical")
    static let memoryPressureWarning = Notification.Name("memoryPressureWarning")
    static let memoryPressureNormal = Notification.Name("memoryPressureNormal")
    static let clearQueryCache = Notification.Name("clearQueryCache")
}