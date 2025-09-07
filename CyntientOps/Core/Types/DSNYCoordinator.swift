//
//  DSNYCoordinator.swift
//  CyntientOps v6.0
//
//  DSNY (Department of Sanitation New York) coordination logic for Kevin Dutan's workflow
//  Handles multi-building trash set-out and retrieval operations
//

import Foundation
import CoreLocation

public enum CollectionDay: String, CaseIterable {
    case sunday = "Sunday"
    case monday = "Monday" 
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    
    public static func from(weekday: Int) -> CollectionDay {
        // weekday: 1 = Sunday, 2 = Monday, etc.
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .sunday
        }
    }
    
    public var weekday: Int {
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

public struct DSNYBuilding {
    public let buildingId: String
    public let name: String
    public let address: String
    public let coordinate: CLLocationCoordinate2D
    public let setOutDays: Set<CollectionDay>
    public let retrievalDays: Set<CollectionDay>
    
    public init(buildingId: String, name: String, address: String, coordinate: CLLocationCoordinate2D, setOutDays: Set<CollectionDay>, retrievalDays: Set<CollectionDay>) {
        self.buildingId = buildingId
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.setOutDays = setOutDays
        self.retrievalDays = retrievalDays
    }
}

public struct DSNYCoordinator {
    
    // Kevin's DSNY circuit buildings (17th Street area)
    private static let dsnyBuildings: [DSNYBuilding] = [
        DSNYBuilding(
            buildingId: CanonicalIDs.Buildings.westSeventeenth135_139,
            name: "135-139 West 17th Street",
            address: "135-139 West 17th Street, New York, NY 10011",
            coordinate: CLLocationCoordinate2D(latitude: 40.7395, longitude: -73.9960),
            setOutDays: [.sunday, .tuesday, .thursday],
            retrievalDays: [.monday, .wednesday, .friday]
        ),
        DSNYBuilding(
            buildingId: CanonicalIDs.Buildings.westSeventeenth138,
            name: "138 West 17th Street", 
            address: "138 West 17th Street, New York, NY 10011",
            coordinate: CLLocationCoordinate2D(latitude: 40.7396, longitude: -73.9961),
            setOutDays: [.sunday, .tuesday, .thursday],
            retrievalDays: [.monday, .wednesday, .friday]
        ),
        DSNYBuilding(
            buildingId: CanonicalIDs.Buildings.westSeventeenth117,
            name: "117 West 17th Street",
            address: "117 West 17th Street, New York, NY 10011", 
            coordinate: CLLocationCoordinate2D(latitude: 40.7394, longitude: -73.9958),
            setOutDays: [.sunday, .tuesday, .thursday],
            retrievalDays: [.monday, .wednesday, .friday]
        ),
        DSNYBuilding(
            buildingId: CanonicalIDs.Buildings.westSeventeenth136,
            name: "136 West 17th Street",
            address: "136 West 17th Street, New York, NY 10011",
            coordinate: CLLocationCoordinate2D(latitude: 40.7395, longitude: -73.9960),
            setOutDays: [.sunday, .tuesday, .thursday], 
            retrievalDays: [.monday, .wednesday, .friday]
        ),
        DSNYBuilding(
            buildingId: CanonicalIDs.Buildings.rubinMuseum,
            name: "Rubin Museum (142–148 W 17th)",
            address: "150 West 17th Street, New York, NY 10011",
            coordinate: CLLocationCoordinate2D(latitude: 40.7396, longitude: -73.9962),
            setOutDays: [.sunday, .tuesday, .thursday],
            retrievalDays: [.monday, .wednesday, .friday]
        )
    ]
    
    /// Get buildings that need bin set-out for the given collection day
    public static func buildingsForBinSetOut(on day: CollectionDay) -> [DSNYBuilding] {
        return dsnyBuildings.filter { $0.setOutDays.contains(day) }
    }
    
    /// Get buildings that need bin retrieval for the given collection day  
    public static func buildingsForBinRetrieval(on day: CollectionDay) -> [DSNYBuilding] {
        return dsnyBuildings.filter { $0.retrievalDays.contains(day) }
    }
    
    /// Check if it's currently within the DSNY set-out window (8-9 PM on set-out days)
    public static func isSetOutWindow(for day: CollectionDay, at time: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday, .hour], from: time)
        
        guard let weekday = components.weekday,
              let hour = components.hour else { return false }
        
        let currentDay = CollectionDay.from(weekday: weekday)
        return currentDay == day && hour >= 20 && hour < 21 // 8-9 PM
    }
    
    /// Check if it's currently within the DSNY retrieval window (7-8 AM on retrieval days)
    public static func isRetrievalWindow(for day: CollectionDay, at time: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday, .hour], from: time)
        
        guard let weekday = components.weekday,
              let hour = components.hour else { return false }
        
        let currentDay = CollectionDay.from(weekday: weekday)
        return currentDay == day && hour >= 7 && hour < 8 // 7-8 AM
    }
    
    /// Get the next DSNY operation for Kevin
    public static func nextDSNYOperation(from time: Date = Date()) -> (type: String, day: CollectionDay, time: Date)? {
        let calendar = Calendar.current
        let now = time
        
        // Check next 7 days for upcoming operations
        for i in 0..<7 {
            guard let checkDate = calendar.date(byAdding: .day, value: i, to: now) else { continue }
            let weekday = calendar.component(.weekday, from: checkDate)
            let day = CollectionDay.from(weekday: weekday)
            
            // Check for set-out operations (8 PM on Sun/Tue/Thu)
            if [CollectionDay.sunday, .tuesday, .thursday].contains(day) {
                if let setOutTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: checkDate),
                   setOutTime > now {
                    return ("Set Out Trash", day, setOutTime)
                }
            }
            
            // Check for retrieval operations (7 AM on Mon/Wed/Fri)
            if [CollectionDay.monday, .wednesday, .friday].contains(day) {
                if let retrievalTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: checkDate),
                   retrievalTime > now {
                    return ("Retrieve Bins", day, retrievalTime)
                }
            }
        }
        
        return nil
    }
}