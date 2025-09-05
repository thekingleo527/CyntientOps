import SwiftUI
import MapKit

struct WorkerPortfolioMapRevealSheet: View {
    let container: ServiceContainer
    let buildings: [NamedCoordinate]
    let currentBuildingId: String?
    let onBuildingTap: (NamedCoordinate) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var revealed = true

    var body: some View {
        NavigationView {
            MapRevealContainer(
                buildings: buildings,
                currentBuildingId: currentBuildingId,
                focusBuildingId: nil,
                assignedBuildingIds: nil, // Workers see full portfolio - no filtering
                forceShowAll: true, // Workers always see full portfolio
                isRevealed: $revealed,
                container: container,
                onBuildingTap: { b in
                    onBuildingTap(b)
                }
            ) {
                // Overlay content while map is in background
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

