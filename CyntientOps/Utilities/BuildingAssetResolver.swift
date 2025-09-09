import SwiftUI

/// Unified resolver for building images used across dashboards and map components.
/// Order of precedence:
/// 1) Named coordinate's own imageAssetName (when present and bundled)
/// 2) Central `BuildingAssets` id->asset mapping
/// 3) Fallback to `BuildingConstants` mapping
/// 4) Special-case heuristics (Rubin/Stuyvesant)
/// 5) System placeholder
struct BuildingAssetResolver {
    // MARK: - Public API (SwiftUI)

    static func image(forBuildingId id: String) -> Image {
        if let name = assetName(forBuildingId: id), let _ = UIImage(named: name) {
            return Image(name)
        }
        return Image(systemName: "building.2")
    }

    static func image(for coordinate: NamedCoordinate) -> Image {
        if let name = assetName(for: coordinate), let _ = UIImage(named: name) {
            return Image(name)
        }
        return Image(systemName: "building.2")
    }

    // MARK: - Public API (UIKit helpers)

    static func uiImage(for coordinate: NamedCoordinate) -> UIImage? {
        if let name = assetName(for: coordinate) { return UIImage(named: name) }
        return nil
    }

    // MARK: - Asset name resolution

    static func assetName(for coordinate: NamedCoordinate) -> String? {
        // 1) Prefer explicit imageAssetName if provided on the coordinate
        if let explicit = coordinate.imageAssetName, !explicit.isEmpty, UIImage(named: explicit) != nil {
            return explicit
        }
        // 2) Central mapping
        if let mapped = BuildingAssets.assetName(for: coordinate.id), UIImage(named: mapped) != nil {
            return mapped
        }
        // 3) Mapping from BuildingConstants
        if let fromConstants = BuildingConstants.buildingData[coordinate.id]?.imageAsset,
           UIImage(named: fromConstants) != nil {
            return fromConstants
        }
        // 4) Name-based special-cases
        let lname = coordinate.name.lowercased()
        if lname.contains("rubin") || lname.contains("museum") {
            return "Rubin_Museum_142_148_West_17th_Street"
        }
        if lname.contains("stuyvesant") || lname.contains("cove park") {
            return "Stuyvesant_Cove_Park"
        }
        // 5) No asset
        return nil
    }

    static func assetName(forBuildingId id: String) -> String? {
        // Central mapping first
        if let name = BuildingAssets.assetName(for: id), UIImage(named: name) != nil {
            return name
        }
        // Constants mapping
        if let fromConstants = BuildingConstants.buildingData[id]?.imageAsset,
           UIImage(named: fromConstants) != nil {
            return fromConstants
        }
        return nil
    }
}
