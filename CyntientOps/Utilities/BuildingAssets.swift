import Foundation

enum BuildingAssets {
    // Shared mapping from buildingId to asset basename in XCAssets
    static let map: [String: String] = [
        "1": "12_West_18th_Street",
        // Use actual bundled asset filename
        "3": "135West17thStreet",
        "4": "104_Franklin_Street",
        // Use actual bundled asset filename
        "5": "138West17thStreet",
        "6": "68_Perry_Street",
        "7": "112_West_18th_Street",
        "8": "41_Elizabeth_Street",
        "9": "117_West_17th_Street",
        "10": "131_Perry_Street",
        "11": "123_1st_Avenue",
        "13": "136_West_17th_Street",
        "14": "Rubin_Museum_142_148_West_17th_Street",
        "15": "133_East_15th_Street",
        "16": "Stuyvesant_Cove_Park",
        "17": "178_Spring_Street",
        "18": "36_Walker_Street",
        "19": "115_7th_Avenue",
        "21": "148_Chambers_Street"
    ]

    static func assetName(for buildingId: String) -> String? {
        map[buildingId]
    }
}
