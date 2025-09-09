import Foundation
import os

public enum AppLog {
    public static let ui = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cyntientops.app", category: "ui")
    public static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cyntientops.app", category: "network")
    public static let db = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cyntientops.app", category: "db")
    public static let ai = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cyntientops.app", category: "ai")
}

