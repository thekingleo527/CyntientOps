import SwiftUI
import MapKit

struct ClientPortfolioMapRevealSheet: View {
    let container: ServiceContainer
    let buildings: [NamedCoordinate]
    let onBuildingTap: (NamedCoordinate) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var revealed = true

    var body: some View {
        NavigationView {
            MapRevealContainer(
                buildings: buildings,
                currentBuildingId: nil,
                focusBuildingId: nil,
                isRevealed: $revealed,
                container: container,
                onBuildingTap: { b in onBuildingTap(b) }
            ) {
                VStack { Spacer() }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

