import Foundation

public enum AppFeatures {
    public enum RecentActivity {
        // Default OFF for workers, ON for admins
        public static var enabledForWorkers: Bool { false }
        public static var enabledForAdmins: Bool { true }
    }
}

