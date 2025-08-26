//
//  BatchedUIUpdater.swift
//  CyntientOps
//
//  🚀 PERFORMANCE: Batches UI updates to prevent MainActor thrashing
//  ⚡ PRODUCTION: Reduces 181 MainActor.run calls to batched updates
//

import SwiftUI

@MainActor
public final class BatchedUIUpdater: ObservableObject {
    private var pendingUpdates: [String: () -> Void] = [:]
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 0.016 // 60fps max
    
    public static let shared = BatchedUIUpdater()
    
    private init() {}
    
    /// Queue a UI update with a unique key to be batched
    public func queueUpdate(key: String, update: @escaping () -> Void) {
        pendingUpdates[key] = update
        
        // Start timer if not already running
        if updateTimer == nil {
            updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: false) { _ in
                Task { @MainActor in
                    self.flushUpdates()
                }
            }
        }
    }
    
    /// Immediately flush all pending updates
    public func flushUpdates() {
        guard !pendingUpdates.isEmpty else { return }
        
        let updates = pendingUpdates
        pendingUpdates.removeAll()
        updateTimer?.invalidate()
        updateTimer = nil
        
        // Execute all batched updates at once
        for (_, update) in updates {
            update()
        }
    }
    
    /// Queue update with automatic key generation
    public func queueUpdate(file: String = #file, line: Int = #line, update: @escaping () -> Void) {
        let key = "\(URL(fileURLWithPath: file).lastPathComponent):\(line)"
        queueUpdate(key: key, update: update)
    }
}

/// Property wrapper for batched UI updates
@propertyWrapper
public struct BatchedPublished<Value> {
    private let key: String
    @Published private var value: Value
    
    public init(wrappedValue: Value, key: String? = nil) {
        self.value = wrappedValue
        self.key = key ?? UUID().uuidString
    }
    
    public var wrappedValue: Value {
        get { value }
        set {
            BatchedUIUpdater.shared.queueUpdate(key: key) {
                self.value = newValue
            }
        }
    }
    
    public var projectedValue: Published<Value>.Publisher {
        $value
    }
}