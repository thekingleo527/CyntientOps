//
//  Building.swift
//  CyntientOps
//
//  ✅ REFACTORED: Consolidated building utilities and extensions
//  ✅ INTEGRATED: With DatabaseStartupCoordinator seed data
//  ✅ FIXED: Removed non-existent imageAssetName references
//  ✅ ADDED: Centralized building image and metadata management
//

import Foundation
import CoreLocation

// MARK: - Building Constants
struct BuildingConstants {
    
    // MARK: - Building Metadata (From DatabaseStartupCoordinator)
    // IMPORTANT: Keep this aligned with CanonicalIDs.Buildings and DatabaseInitializer.seedBuildings()
    static let buildingData: [String: (name: String, address: String, imageAsset: String)] = [
        // Active portfolio
        "1":  ("12 West 18th Street",        "12 W 18th St, New York, NY 10011",   "12_West_18th_Street"),
        // "2": Building removed from portfolio
        "3":  ("135-139 West 17th Street",   "135-139 W 17th St, New York, NY 10011", "135West17thStreet"),
        "4":  ("104 Franklin Street",        "104 Franklin St, New York, NY 10013", "104_Franklin_Street"),
        "5":  ("138 West 17th Street",       "138 W 17th St, New York, NY 10011",   "138West17thStreet"),
        "6":  ("68 Perry Street",            "68 Perry St, New York, NY 10014",     "68_Perry_Street"),
        "7":  ("112 West 18th Street",       "112 W 18th St, New York, NY 10011",   "112_West_18th_Street"),
        "8":  ("41 Elizabeth Street",        "41 Elizabeth St, New York, NY 10013", "41_Elizabeth_Street"),
        "9":  ("117 West 17th Street",       "117 W 17th St, New York, NY 10011",   "117_West_17th_Street"),
        "10": ("131 Perry Street",           "131 Perry St, New York, NY 10014",    "131_Perry_Street"),
        "11": ("123 1st Avenue",             "123 1st Ave, New York, NY 10003",     "123_1st_Avenue"),
        // "12": not in use
        "13": ("136 West 17th Street",       "136 W 17th St, New York, NY 10011",   "136_West_17th_Street"),
        "14": ("Rubin Museum (142–148 W 17th)", "142–148 W 17th St, New York, NY 10011", "Rubin_Museum_142_148_West_17th_Street"),
        "15": ("133 East 15th Street",       "133 E 15th St, New York, NY 10003",   "133_East_15th_Street"),
        "16": ("Stuyvesant Cove Park",       "E 18th St & East River, New York, NY 10009", "Stuyvesant_Cove_Park"),
        "17": ("178 Spring Street",          "178 Spring St, New York, NY 10012",   "178_Spring_Street"),
        "18": ("36 Walker Street",           "36 Walker St, New York, NY 10013",    "36_Walker_Street"),
        "19": ("115 7th Avenue",             "115 7th Ave, New York, NY 10011",     "115_7th_Avenue"),
        // "20": internal/HQ (no image asset bundled)
        "21": ("148 Chambers Street",        "148 Chambers St, New York, NY 10007", "148_Chambers_Street")
    ]
    
    // MARK: - Building Type Icons
    static func getBuildingIcon(for buildingName: String) -> String {
        let name = buildingName.lowercased()
        
        if name.contains("museum") || name.contains("rubin") {
            return "building.columns.fill"
        } else if name.contains("park") || name.contains("stuyvesant") || name.contains("cove") {
            return "leaf.fill"
        } else if name.contains("perry") || name.contains("elizabeth") || name.contains("walker") {
            return "house.fill"
        } else if name.contains("west") || name.contains("east") || name.contains("franklin") {
            return "building.2.fill"
        } else if name.contains("avenue") || name.contains("ave") {
            return "building.fill"
        } else {
            return "building.2.fill"
        }
    }
}

// MARK: - NamedCoordinate Extensions

extension NamedCoordinate {
    
    /// Display name with fallback
    var displayName: String {
        // Try to get official name from constants
        if let data = BuildingConstants.buildingData[id] {
            return data.name
        }
        return name.isEmpty ? "Building \(id)" : name
    }
    
    /// Short name for UI constraints
    var shortName: String {
        let fullName = displayName
        
        // Special cases for known buildings
        switch id {
        case "14": return "Rubin"
        case "16": return "Stuyvesant"
        default: break
        }
        
        // Extract street number and first word
        let words = fullName.split(separator: " ")
        if words.count >= 2 {
            if let streetNumber = words.first, streetNumber.allSatisfy({ $0.isNumber || $0 == "-" }) {
                return "\(streetNumber) \(words[1].prefix(3))"
            }
        }
        
        return String(fullName.prefix(12))
    }
    
    /// Full address with proper formatting
    var fullAddress: String {
        // First check if address property is populated
        if !address.isEmpty {
            return address
        }
        
        // Then check our constants
        if let data = BuildingConstants.buildingData[id] {
            return data.address
        }
        
        // Fallback
        return "\(name), New York, NY"
    }
    
    /// Get the image asset name for this building
    var imageAssetName: String? {
        return BuildingConstants.buildingData[id]?.imageAsset
    }
    
    /// Check if building has a valid image asset
    var hasValidImageAsset: Bool {
        return imageAssetName != nil
    }
    
    /// Get the appropriate system icon for this building type
    var buildingIcon: String {
        return BuildingConstants.getBuildingIcon(for: name)
    }
    
    /// Get a color associated with building type
    var buildingTypeColor: Color {
        switch buildingIcon {
        case "building.columns.fill": return .purple  // Museums
        case "leaf.fill": return .green              // Parks
        case "house.fill": return .blue              // Residential
        case "building.fill": return .orange         // Commercial
        default: return .gray                        // Default
        }
    }
}

// MARK: - Array Extensions for Buildings

extension Array where Element == NamedCoordinate {
    
    /// Filter by IDs
    func withIds(_ ids: [String]) -> [NamedCoordinate] {
        return self.filter { ids.contains($0.id) }
    }
    
    /// Find by ID
    func building(withId id: String) -> NamedCoordinate? {
        return self.first { $0.id == id }
    }
    
    /// Find by name (fuzzy match)
    func building(named name: String) -> NamedCoordinate? {
        let lowercaseName = name.lowercased()
        
        // First try exact match
        if let exact = self.first(where: { $0.name.lowercased() == lowercaseName }) {
            return exact
        }
        
        // Then try contains
        return self.first { building in
            building.name.lowercased().contains(lowercaseName) ||
            lowercaseName.contains(building.name.lowercased())
        }
    }
    
    /// Sort by distance from coordinate
    func sortedByDistance(from coordinate: CLLocationCoordinate2D) -> [NamedCoordinate] {
        let fromLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return self.sorted { building1, building2 in
            let location1 = CLLocation(latitude: building1.latitude, longitude: building1.longitude)
            let location2 = CLLocation(latitude: building2.latitude, longitude: building2.longitude)
            
            return fromLocation.distance(from: location1) < fromLocation.distance(from: location2)
        }
    }
    
    /// Get buildings within radius (in meters)
    func within(meters: Double, of coordinate: CLLocationCoordinate2D) -> [NamedCoordinate] {
        let fromLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return self.filter { building in
            let buildingLocation = CLLocation(latitude: building.latitude, longitude: building.longitude)
            return fromLocation.distance(from: buildingLocation) <= meters
        }
    }
    
    /// Group by building type
    func groupedByType() -> [String: [NamedCoordinate]] {
        return Dictionary(grouping: self) { building in
            building.buildingIcon
        }
    }
    
    /// Get center coordinate for map region
    var centerCoordinate: CLLocationCoordinate2D {
        guard !isEmpty else {
            return CLLocationCoordinate2D(latitude: 40.7590, longitude: -73.9845) // NYC default
        }
        
        let avgLat = self.map(\.latitude).reduce(0, +) / Double(count)
        let avgLon = self.map(\.longitude).reduce(0, +) / Double(count)
        
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }
    
    /// Get bounding region for map
    var boundingRegion: MKCoordinateRegion? {
        guard !isEmpty else { return nil }
        
        let latitudes = self.map(\.latitude)
        let longitudes = self.map(\.longitude)
        
        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else { return nil }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.2,  // Add 20% padding
            longitudeDelta: (maxLon - minLon) * 1.2
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Building Image Helper
struct BuildingImageHelper {
    
    /// Get the image name for a building ID
    static func imageName(for buildingId: String) -> String? {
        return BuildingConstants.buildingData[buildingId]?.imageAsset
    }
    
    /// Get a SwiftUI Image for a building
    static func image(for building: NamedCoordinate) -> Image {
        if let assetName = building.imageAssetName {
            return Image(assetName)
        } else {
            return Image(systemName: building.buildingIcon)
        }
    }
    
    /// Check if an image exists in assets
    static func hasImage(for buildingId: String) -> Bool {
        guard let assetName = BuildingConstants.buildingData[buildingId]?.imageAsset else {
            return false
        }
        return UIImage(named: assetName) != nil
    }
}

// MARK: - SwiftUI Color Extension
import SwiftUI

extension Color {
    // Define colors if not already available
    static let buildingMuseum = Color.purple
    static let buildingPark = Color.green
    static let buildingResidential = Color.blue
    static let buildingCommercial = Color.orange
}

// MARK: - MapKit Import
import MapKit
