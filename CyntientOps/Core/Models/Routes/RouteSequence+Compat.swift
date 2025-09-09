import Foundation

// Compatibility shim: some callers expect `RouteSequence.routeName`.
// Our model uses `buildingName`. Provide a lightweight bridge.
public extension RouteSequence {
    var routeName: String? { self.buildingName }
}

