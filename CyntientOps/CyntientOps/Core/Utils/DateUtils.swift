//
//  DateUtils.swift
//  CyntientOps v6.0
//
//  ✅ TIMEZONE FIX: Consistent local timezone handling for all date operations
//  ✅ WINDOW LOGIC: Proper time windowing for immediate/upcoming tasks
//  ✅ SHARED: Used across all ViewModels to prevent UTC/local mixing
//

import Foundation

public struct DateUtils {
    
    // MARK: - Timezone & Calendar
    
    /// Current timezone (local device timezone)
    public static var tz: TimeZone { .current }
    
    /// Calendar configured with local timezone
    public static var calendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = tz
        return cal
    }()
    
    // MARK: - Today Boundaries
    
    /// Start of today in local timezone (midnight)
    public static func startOfToday() -> Date {
        calendar.startOfDay(for: Date())
    }
    
    /// End of today in local timezone (midnight tomorrow)
    public static func endOfToday() -> Date {
        let start = startOfToday()
        return calendar.date(byAdding: .day, value: 1, to: start)!
    }
    
    /// Today's date range (startOfToday...endOfToday)
    public static var todayRange: ClosedRange<Date> {
        startOfToday()...endOfToday()
    }
    
    // MARK: - Time Windows
    
    /// Creates a time window from now for the specified hours
    /// - Parameter hours: Number of hours from now
    /// - Returns: ClosedRange from now to now + hours
    public static func window(hours: Int) -> ClosedRange<Date> {
        let now = Date()
        let end = calendar.date(byAdding: .hour, value: hours, to: now)!
        return now...end
    }
    
    /// Creates a time window from now for the specified minutes
    /// - Parameter minutes: Number of minutes from now
    /// - Returns: ClosedRange from now to now + minutes
    public static func window(minutes: Int) -> ClosedRange<Date> {
        let now = Date()
        let end = calendar.date(byAdding: .minute, value: minutes, to: now)!
        return now...end
    }
    
    // MARK: - Tomorrow Helpers
    
    /// Start of tomorrow in local timezone
    public static func startOfTomorrow() -> Date {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday())!
        return tomorrow
    }
    
    /// End of tomorrow in local timezone
    public static func endOfTomorrow() -> Date {
        let start = startOfTomorrow()
        return calendar.date(byAdding: .day, value: 1, to: start)!
    }
    
    /// Tomorrow's date range
    public static var tomorrowRange: ClosedRange<Date> {
        startOfTomorrow()...endOfTomorrow()
    }
    
    // MARK: - Week Helpers
    
    /// Get the current weekday (1=Sunday, 7=Saturday) in local timezone
    public static func currentWeekday() -> Int {
        calendar.component(.weekday, from: Date())
    }
    
    /// Get weekday for a specific date in local timezone
    public static func weekday(for date: Date) -> Int {
        calendar.component(.weekday, from: date)
    }
    
    /// Get weekday name for a date in local timezone
    public static func weekdayName(for date: Date, abbreviated: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = abbreviated ? "E" : "EEEE"
        return formatter.string(from: date)
    }
    
    // MARK: - Time Checks
    
    /// Check if a date is today in local timezone
    public static func isToday(_ date: Date) -> Bool {
        todayRange.contains(date)
    }
    
    /// Check if a date is tomorrow in local timezone
    public static func isTomorrow(_ date: Date) -> Bool {
        tomorrowRange.contains(date)
    }
    
    /// Check if a date is in the future from now
    public static func isFuture(_ date: Date) -> Bool {
        date > Date()
    }
    
    /// Check if a date is within the next N hours
    public static func isWithinHours(_ date: Date, hours: Int) -> Bool {
        window(hours: hours).contains(date)
    }
    
    // MARK: - Formatters
    
    /// Time formatter for local timezone (e.g., "7:00 AM")
    public static var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// Date formatter for local timezone (e.g., "Aug 27")
    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateStyle = .short
        return formatter
    }()
    
    /// DateTime formatter for local timezone (e.g., "Aug 27, 7:00 AM")
    public static var dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// ISO formatter for local timezone (useful for debugging)
    public static var isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    // MARK: - Schedule Instance Helpers
    
    /// Convert UTC date to local equivalent (for schedule instances)
    public static func toLocal(_ utcDate: Date) -> Date {
        // NSDate is timezone-agnostic, but ensure we're working with local interpretation
        return Date(timeIntervalSince1970: utcDate.timeIntervalSince1970)
    }
    
    /// Group dates by weekday in local timezone
    public static func groupByWeekday<T>(_ items: [T], dateKeyPath: KeyPath<T, Date>) -> [Int: [T]] {
        return Dictionary(grouping: items) { item in
            weekday(for: item[keyPath: dateKeyPath])
        }
    }
    
    // MARK: - Debug Helpers
    
    /// Format date for logging with timezone info
    public static func debugString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss (zzz)"
        return formatter.string(from: date)
    }
    
    /// Current time as debug string
    public static var nowDebugString: String {
        debugString(for: Date())
    }
}

// MARK: - Schedule Instance Extensions

public extension Date {
    
    /// Check if this date is today using DateUtils
    var isToday: Bool {
        DateUtils.isToday(self)
    }
    
    /// Check if this date is tomorrow using DateUtils
    var isTomorrow: Bool {
        DateUtils.isTomorrow(self)
    }
    
    /// Check if this date is in the future using DateUtils
    var isFuture: Bool {
        DateUtils.isFuture(self)
    }
    
    /// Format as local time string
    var localTimeString: String {
        DateUtils.timeFormatter.string(from: self)
    }
    
    /// Format as local date string
    var localDateString: String {
        DateUtils.dateFormatter.string(from: self)
    }
    
    /// Format as local date-time string
    var localDateTimeString: String {
        DateUtils.dateTimeFormatter.string(from: self)
    }
    
    /// Weekday in local timezone
    var localWeekday: Int {
        DateUtils.weekday(for: self)
    }
    
    /// Debug string with timezone
    var debugString: String {
        DateUtils.debugString(for: self)
    }
}

// MARK: - Time Window Constants

public extension DateUtils {
    
    /// Common time windows for task filtering
    enum TimeWindow {
        case immediate      // Next 12 hours
        case urgent         // Next 6 hours
        case upcoming       // Next 24 hours
        case soon           // Next 2 hours
        
        var hours: Int {
            switch self {
            case .immediate: return 12
            case .urgent: return 6
            case .upcoming: return 24
            case .soon: return 2
            }
        }
        
        var range: ClosedRange<Date> {
            DateUtils.window(hours: hours)
        }
    }
}

#if DEBUG
// MARK: - Preview Helpers

public extension DateUtils {
    /// Create a date for testing (in local timezone)
    static func testDate(hour: Int, minute: Int = 0) -> Date {
        let today = startOfToday()
        return calendar.date(byAdding: .hour, value: hour, to: today)!
            .addingTimeInterval(TimeInterval(minute * 60))
    }
    
    /// Create tomorrow's date at specific hour
    static func testTomorrowDate(hour: Int, minute: Int = 0) -> Date {
        let tomorrow = startOfTomorrow()
        return calendar.date(byAdding: .hour, value: hour, to: tomorrow)!
            .addingTimeInterval(TimeInterval(minute * 60))
    }
}
#endif