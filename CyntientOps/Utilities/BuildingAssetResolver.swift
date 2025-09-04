import SwiftUI

/// Unified resolver for building images used across dashboards and map components.
/// Uses the shared `BuildingAssets` id->asset mapping with graceful fallbacks.
struct BuildingAssetResolver {
    /// Returns a SwiftUI Image for a building id if available; otherwise a system fallback.
    static func image(forBuildingId id: String) -> Image {
        if let name = BuildingAssets.assetName(for: id), UIImage(named: name) != nil {
            return Image(name)
        }
        return Image(systemName: "building.2")
    }

    /// Returns the asset name for a building id if available.
    static func assetName(forBuildingId id: String) -> String? {
        BuildingAssets.assetName(for: id)
    }

    /// Returns an image for a NamedCoordinate using id mapping or a sensible fallback.
    static func image(for coordinate: NamedCoordinate) -> Image {
        image(forBuildingId: coordinate.id)
    }
}

