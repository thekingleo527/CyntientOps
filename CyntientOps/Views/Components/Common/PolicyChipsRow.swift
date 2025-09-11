import SwiftUI

/// A view that displays a row of policy chips for a given building.
struct PolicyChipsRow: View {
    let buildingId: String

    private var chips: [Chip] {
        generateChips(for: buildingId)
    }

    var body: some View {
        if !chips.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(chips) { chip in
                        ChipView(chip: chip)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func generateChips(for buildingId: String) -> [Chip] {
        var generatedChips: [Chip] = []
        guard let policy = BuildingOperationsCatalog.map[buildingId] else {
            return []
        }

        if policy.rainMats?.hasRainMats == true {
            generatedChips.append(Chip(label: "Rain Mats", symbol: "cloud.rain"))
        }

        if policy.roofDrains?.checkBeforeRain == true {
            generatedChips.append(Chip(label: "Roof Drains", symbol: "drop"))
        }

        if policy.winter?.saltBeforeSnow == true {
            generatedChips.append(Chip(label: "Salt Pre-Snow", symbol: "snow"))
        }

        if policy.dsny != nil {
            generatedChips.append(Chip(label: "DSNY Schedule", symbol: "trash"))
        }
        
        if policy.backyard?.drainSweepMonthly == true {
            generatedChips.append(Chip(label: "Backyard Drain", symbol: "leaf"))
        }

        return generatedChips
    }
}

/// A model for a single chip.
struct Chip: Identifiable {
    let id = UUID()
    let label: String
    let symbol: String
}

/// A view for a single chip.
struct ChipView: View {
    let chip: Chip

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: chip.symbol)
                .font(.caption)
            Text(chip.label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
    }
}
