
//  DSNYModels.swift
//  CyntientOps
//
//  NYC Department of Sanitation API Models
//  Based on SODA (Socrata Open Data API)
//

import Foundation
import CoreLocation

// MARK: - DSNY Namespace
public struct DSNY {
    
    // MARK: - Collection Schedule Models
    
    /// Represents a DSNY collection schedule from API endpoint: p7k6-2pm8
    public struct CollectionSchedule: Codable {
        public let districtSection: String?
        public let borough: String?
        public let refuseSchedule: String?
        public let recyclingSchedule: String?
        public let organicsSchedule: String?
        public let bulkSchedule: String?
        public let geometry: GeometryData?
        
        enum CodingKeys: String, CodingKey {
            case districtSection = "district_section"
            case borough
            case refuseSchedule = "regular_coll"
            case recyclingSchedule = "recycle_coll"
            case organicsSchedule = "organics_collection"
            case bulkSchedule = "bulk_collection"
            case geometry = "the_geom"
        }
        
        /// Parse schedule string to days of week
        public func parseDays(from schedule: String?) -> Set<DayOfWeek> {
            guard let schedule = schedule?.uppercased() else { return [] }
            
            var days = Set<DayOfWeek>()
            
            // Common patterns: "MON/THU", "M/TH", "MONDAY/THURSDAY"
            let components = schedule.components(separatedBy: CharacterSet(charactersIn: "/,& "))
            
            for component in components {
                let cleaned = component.trimmingCharacters(in: .whitespaces)
                
                switch cleaned {
                case "M", "MON", "MONDAY":
                    days.insert(.monday)
                case "T", "TU", "TUE", "TUES", "TUESDAY":
                    days.insert(.tuesday)
                case "W", "WED", "WEDNESDAY":
                    days.insert(.wednesday)
                case "TH", "THU", "THUR", "THURSDAY":
                    days.insert(.thursday)
                case "F", "FRI", "FRIDAY":
                    days.insert(.friday)
                case "S", "SAT", "SATURDAY":
                    days.insert(.saturday)
                case "SU", "SUN", "SUNDAY":
                    days.insert(.sunday)
                default:
                    break
                }
            }
            
            return days
        }
    }
    
    /// Geometry data for collection zones
    public struct GeometryData: Codable {
        public let type: String?
        public let coordinates: [[[Double]]]?
    }
    
    // MARK: - Tonnage Data Models
    
    /// Monthly tonnage data from API endpoint: ebb7-mvp5
    public struct TonnageData: Codable {
        public let month: String?
        public let borough: String?
        public let communityDistrict: String?
        public let refuseTons: String?
        public let paperTons: String?
        public let mgpTons: String? // Metal, Glass, Plastic
        public let organicsTons: String?
        
        enum CodingKeys: String, CodingKey {
            case month
            case borough
            case communityDistrict = "communitydistrict"
            case refuseTons = "refusetonscollected"
            case paperTons = "papertonscollected"
            case mgpTons = "mgptonscollected"
            case organicsTons = "organicstons"
        }
    }
    
    // MARK: - Violation Models
    
    public struct Violation: Codable {
        public let violationId: String
        public let buildingAddress: String
        public let violationType: ViolationType
        public let issueDate: Date
        public let fineAmount: Decimal
        public let status: ViolationStatus
        public let description: String
        
        public init(
            violationId: String,
            buildingAddress: String,
            violationType: ViolationType,
            issueDate: Date,
            fineAmount: Decimal,
            status: ViolationStatus,
            description: String
        ) {
            self.violationId = violationId
            self.buildingAddress = buildingAddress
            self.violationType = violationType
            self.issueDate = issueDate
            self.fineAmount = fineAmount
            self.status = status
            self.description = description
        }
    }
    
    // MARK: - Enums
    
    public enum DayOfWeek: String, CaseIterable {
        case monday = "MON"
        case tuesday = "TUE"
        case wednesday = "WED"
        case thursday = "THU"
        case friday = "FRI"
        case saturday = "SAT"
        case sunday = "SUN"
        
        public var fullName: String {
            switch self {
            case .monday: return "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
            case .sunday: return "Sunday"
            }
        }
        
        public var calendarWeekday: Int {
            switch self {
            case .sunday: return 1
            case .monday: return 2
            case .tuesday: return 3
            case .wednesday: return 4
            case .thursday: return 5
            case .friday: return 6
            case .saturday: return 7
            }
        }
    }
    
    public enum CollectionType: String, CaseIterable {
        case refuse = "refuse"
        case recycling = "recycling"
        case organics = "organics"
        case bulk = "bulk"
        
        public var displayName: String {
            switch self {
            case .refuse: return "Trash"
            case .recycling: return "Recycling"
            case .organics: return "Organics"
            case .bulk: return "Bulk Items"
            }
        }
        
        public var icon: String {
            switch self {
            case .refuse: return "trash"
            case .recycling: return "arrow.3.trianglepath"
            case .organics: return "leaf"
            case .bulk: return "shippingbox"
            }
        }
    }
    
    public enum ViolationType: String, Codable, CaseIterable {
        case improperSetout = "improper_setout"
        case missedPickup = "missed_pickup"
        case noLid = "no_lid"
        case overflowing = "overflowing"
        case wrongDay = "wrong_day"
        case blockingSidewalk = "blocking_sidewalk"
        case contamination = "contamination"
        case other = "other"
        
        public var displayName: String {
            switch self {
            case .improperSetout: return "Improper Set-Out"
            case .missedPickup: return "Missed Pickup"
            case .noLid: return "No Secure Lid"
            case .overflowing: return "Overflowing Bins"
            case .wrongDay: return "Wrong Collection Day"
            case .blockingSidewalk: return "Blocking Sidewalk"
            case .contamination: return "Contamination"
            case .other: return "Other"
            }
        }
        
        public var severity: ComplianceSeverity {
            switch self {
            case .blockingSidewalk, .contamination:
                return .high
            case .improperSetout, .noLid, .wrongDay:
                return .medium
            case .missedPickup, .overflowing, .other:
                return .low
            }
        }
    }
    
    public enum ViolationStatus: String, Codable {
        case pending = "pending"
        case issued = "issued"
        case contested = "contested"
        case paid = "paid"
        case dismissed = "dismissed"
    }
    
    public enum ComplianceSeverity: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
    
    // MARK: - Compliance Window
    
    public struct ComplianceWindow {
        public let type: CollectionType
        public let setOutAfter: TimeInterval // Seconds after midnight
        public let pickupBefore: TimeInterval // Seconds after midnight
        
        public init(type: CollectionType, setOutAfter: TimeInterval = 72000, pickupBefore: TimeInterval = 43200) {
            self.type = type
            self.setOutAfter = setOutAfter // Default: 8 PM (20:00)
            self.pickupBefore = pickupBefore // Default: 12 PM (noon)
        }
        
        public var setOutTime: String {
            let hours = Int(setOutAfter) / 3600
            return "\(hours % 12 == 0 ? 12 : hours % 12) \(hours >= 12 ? "PM" : "AM")"
        }
        
        public var pickupTime: String {
            let hours = Int(pickupBefore) / 3600
            return "\(hours % 12 == 0 ? 12 : hours % 12) \(hours >= 12 ? "PM" : "AM")"
        }
    }
    
    // MARK: - Building Schedule
    
    public struct BuildingSchedule {
        public let buildingId: String
        public let address: String
        public let districtSection: String
        public let refuseDays: Set<DayOfWeek>
        public let recyclingDays: Set<DayOfWeek>
        public let organicsDays: Set<DayOfWeek>
        public let bulkDays: Set<DayOfWeek>
        public let complianceWindows: [CollectionType: ComplianceWindow]
        public let lastUpdated: Date
        
        public init(
            buildingId: String,
            address: String,
            districtSection: String,
            refuseDays: Set<DayOfWeek> = [],
            recyclingDays: Set<DayOfWeek> = [],
            organicsDays: Set<DayOfWeek> = [],
            bulkDays: Set<DayOfWeek> = [],
            complianceWindows: [CollectionType: ComplianceWindow] = [:],
            lastUpdated: Date = Date()
        ) {
            self.buildingId = buildingId
            self.address = address
            self.districtSection = districtSection
            self.refuseDays = refuseDays
            self.recyclingDays = recyclingDays
            self.organicsDays = organicsDays
            self.bulkDays = bulkDays
            self.complianceWindows = complianceWindows.isEmpty ? Self.defaultWindows : complianceWindows
            self.lastUpdated = lastUpdated
        }
        
        static let defaultWindows: [CollectionType: ComplianceWindow] = [
            .refuse: ComplianceWindow(type: .refuse),
            .recycling: ComplianceWindow(type: .recycling),
            .organics: ComplianceWindow(type: .organics),
            .bulk: ComplianceWindow(type: .bulk)
        ]
        
        /// Get collection days for a specific type
        public func collectionDays(for type: CollectionType) -> Set<DayOfWeek> {
            switch type {
            case .refuse: return refuseDays
            case .recycling: return recyclingDays
            case .organics: return organicsDays
            case .bulk: return bulkDays
            }
        }
        
        /// Check if today is a collection day
        public func isCollectionDay(for type: CollectionType, on date: Date = Date()) -> Bool {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: date)
            let days = collectionDays(for: type)
            
            return days.contains { day in
                day.calendarWeekday == weekday
            }
        }
        
        /// Get next collection date
        public func nextCollectionDate(for type: CollectionType, from date: Date = Date()) -> Date? {
            let calendar = Calendar.current
            let days = collectionDays(for: type)
            
            guard !days.isEmpty else { return nil }
            
            // Check next 7 days
            for i in 0..<7 {
                if let checkDate = calendar.date(byAdding: .day, value: i, to: date) {
                    let weekday = calendar.component(.weekday, from: checkDate)
                    if days.contains(where: { $0.calendarWeekday == weekday }) {
                        return checkDate
                    }
                }
            }
            
            return nil
        }
    }
}

// MARK: - Extensions

extension DSNY.CollectionSchedule {
    /// Convert API response to BuildingSchedule
    public func toBuildingSchedule(buildingId: String, address: String) -> DSNY.BuildingSchedule {
        return DSNY.BuildingSchedule(
            buildingId: buildingId,
            address: address,
            districtSection: districtSection ?? "Unknown",
            refuseDays: parseDays(from: refuseSchedule),
            recyclingDays: parseDays(from: recyclingSchedule),
            organicsDays: parseDays(from: organicsSchedule),
            bulkDays: parseDays(from: bulkSchedule)
        )
    }
}
