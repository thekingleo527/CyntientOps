import SwiftUI

struct MapControlsBar: View {
    let filters: [String]
    let selectedFilter: String
    let onSelectFilter: (String) -> Void

    @Binding var showLegend: Bool

    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack {
            HStack {
                // Quick filters
                HStack(spacing: 8) {
                    ForEach(filters, id: \.self) { label in
                        Button(action: { onSelectFilter(label) }) {
                            Text(label)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedFilter == label ? Color.blue.opacity(0.8) : Color.white.opacity(0.15))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.leading, 8)

                // Top legend removed - using bottom legend only

                Spacer()

                // Zoom controls
                VStack(spacing: 8) {
                    Button(action: onZoomIn) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    Button(action: onZoomOut) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            Image(systemName: "minus")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.trailing, 8)

            // Close button
            Button(action: onClose) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)
                    Image(systemName: "chevron.down")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 20)
            .padding(.top, 60)
        }
    }

}

