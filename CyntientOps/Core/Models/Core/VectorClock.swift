//
//  VectorClock.swift
//  CyntientOps
//
//  Stream B: Gemini - Backend Services
//  Mission: Implement conflict resolution for real-time sync.
//

import Foundation

/// A data structure to determine the causal ordering of events in a distributed system.
/// Renamed to SyncVectorClock to avoid naming conflicts.
public struct SyncVectorClock: Codable, Equatable {
    
    private var clocks: [String: Int] = [:]
    
    /// Initializer
    public init() {}
    
    /// Increment the clock for a specific node
    public mutating func increment(for nodeId: String) {
        clocks[nodeId, default: 0] += 1
    }
    
    /// Check if this clock happens before another clock
    public func happensBefore(_ other: SyncVectorClock) -> Bool {
        var selfIsStrictlySmaller = false
        for (nodeId, selfTime) in clocks {
            let otherTime = other.clocks[nodeId] ?? 0
            if selfTime > otherTime {
                return false
            }
            if selfTime < otherTime {
                selfIsStrictlySmaller = true
            }
        }
        return selfIsStrictlySmaller
    }
    
    /// Check if this clock happens after another clock
    public func happensAfter(_ other: SyncVectorClock) -> Bool {
        return other.happensBefore(self)
    }
    
    /// Check if two clocks are concurrent (neither happens before the other)
    public func areConcurrent(with other: SyncVectorClock) -> Bool {
        return !self.happensBefore(other) && !other.happensBefore(self)
    }
    
    /// Merge two vector clocks, taking the maximum value for each node
    public func merge(with other: SyncVectorClock) -> SyncVectorClock {
        var mergedClock = self
        for (nodeId, otherTime) in other.clocks {
            let selfTime = mergedClock.clocks[nodeId] ?? 0
            mergedClock.clocks[nodeId] = max(selfTime, otherTime)
        }
        return mergedClock
    }
    
    /// Get a copy of the internal clocks dictionary
    public func getClocks() -> [String: Int] {
        return clocks
    }
    
    /// Get the clock value for a specific node
    public func getClock(for nodeId: String) -> Int {
        return clocks[nodeId] ?? 0
    }
}

// MARK: - Clock Comparison Result
public enum ClockComparison {
    case happensBefore
    case happensAfter
    case concurrent
    case equal
    case unknown  // Added for compatibility with ConflictResolutionService
}

// MARK: - Extensions
extension SyncVectorClock {
    /// Compare this clock with another and return the relationship
    public func compare(with other: SyncVectorClock) -> ClockComparison {
        if self == other {
            return .equal
        } else if self.happensBefore(other) {
            return .happensBefore
        } else if self.happensAfter(other) {
            return .happensAfter
        } else {
            return .concurrent
        }
    }
    
    /// Create a new vector clock with an incremented value for the given node
    public func incremented(for nodeId: String) -> SyncVectorClock {
        var newClock = self
        newClock.increment(for: nodeId)
        return newClock
    }
}

// MARK: - Debugging
extension SyncVectorClock: CustomStringConvertible {
    public var description: String {
        let clockStrings = clocks.map { "\($0.key):\($0.value)" }.sorted()
        return "SyncVectorClock{\(clockStrings.joined(separator: ", "))}"
    }
}
