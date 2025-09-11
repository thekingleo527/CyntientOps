//
//  AppClock.swift
//  CyntientOps
//
//  Lightweight controllable clock for deterministic fixtures and tests

import Foundation

public enum AppClock {
    private static var frozen: Date?
    private static var offset: TimeInterval = 0

    /// Returns the current time, honoring freeze or offset if set
    public static var now: Date {
        if let frozen = frozen { return frozen }
        if offset != 0 { return Date().addingTimeInterval(offset) }
        return Date()
    }

    /// Freeze the clock to a specific date/time
    public static func freeze(_ date: Date) { frozen = date }

    /// Unfreeze the clock
    public static func unfreeze() { frozen = nil }

    /// Apply a relative offset to current time (seconds)
    public static func setOffset(_ seconds: TimeInterval) { offset = seconds }

    /// Clear any applied offset
    public static func clearOffset() { offset = 0 }
}

