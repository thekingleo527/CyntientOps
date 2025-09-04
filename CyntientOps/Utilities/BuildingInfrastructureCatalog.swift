import Foundation

struct BuildingInfrastructureCatalog {
    struct Info { let elevators: Int?; let staircases: Int?; let commercialUnits: Int? }

    // Authoritative per‑building infrastructure facts (by buildingId)
    // Populate from provided portfolio notes; extend as needed.
    static let map: [String: Info] = [
        // 17th Street complex (align with CanonicalIDs.Buildings)
        "3":  Info(elevators: 2, staircases: 2, commercialUnits: nil), // 135–139 W 17th — 2 elevators (passenger/freight)
        "5":  Info(elevators: 2, staircases: 1, commercialUnits: 2),   // 138 W 17th — mixed-use (museum/offices)
        "13": Info(elevators: 1, staircases: 2, commercialUnits: 1),   // 136 W 17th — ground commercial
        "9":  Info(elevators: 1, staircases: 1, commercialUnits: nil), // 117 W 17th
        // Rubin Museum Apartments group (142–148 W 17th) — verified walk-ups, no elevator
        "14": Info(elevators: 0, staircases: 2, commercialUnits: 0),   // Rubin Museum (142–148 W 17th) apartments

        // 18th Street
        "1":  Info(elevators: 2, staircases: 2, commercialUnits: nil), // 12 W 18th
        "7":  Info(elevators: 1, staircases: 1, commercialUnits: nil), // 112 W 18th — confirmed 1 elevator, 1 staircase

        // Perry / Elizabeth / Walker / Franklin
        "10": Info(elevators: 1, staircases: 2, commercialUnits: nil), // 131 Perry — 1 elevator, 2 staircases
        "6":  Info(elevators: 0, staircases: 1, commercialUnits: nil), // 68 Perry — no elevator, 1 staircase
        "8":  Info(elevators: 2, staircases: 2, commercialUnits: nil),   // 41 Elizabeth (commercial floors)
        "18": Info(elevators: 0, staircases: 1, commercialUnits: 3),   // 36 Walker — no elevator, 1 staircase (10 res + 3 com)
        "4":  Info(elevators: nil, staircases: 1, commercialUnits: 1),   // 104 Franklin (6 res + 1 com)

        // First Ave / Chambers / Spring
        "11": Info(elevators: nil, staircases: 1, commercialUnits: 1),   // 123 1st Ave (3 res + 1 com)
        "21": Info(elevators: 1, staircases: 1, commercialUnits: 1),    // 148 Chambers — 7 units; elevator opens into unit; 1 staircase
        "17": Info(elevators: 0, staircases: 1, commercialUnits: 1),    // 178 Spring — no elevator; 1 staircase (4 res + 1 com)

        // Other portfolio locations
        "15": Info(elevators: nil, staircases: nil, commercialUnits: 0),  // 133 East 15th Street — lobby ground; 4 units/floor (1–4)
        "16": Info(elevators: 0, staircases: nil, commercialUnits: nil),   // Stuyvesant Cove Park — outdoor, no elevator
        "19": Info(elevators: 0, staircases: nil, commercialUnits: 0),   // 115 7th Avenue — exterior maintenance only (no residential units)
        "20": Info(elevators: nil, staircases: nil, commercialUnits: nil)  // CyntientOps HQ — details TBD
    ]

    static func elevatorCount(for id: String) -> Int? { map[id]?.elevators }
    static func staircaseCount(for id: String) -> Int? { map[id]?.staircases }
    static func commercialUnits(for id: String) -> Int? { map[id]?.commercialUnits }

    // Special notes (e.g., key box location)
    static func notes(for id: String) -> String? {
        switch id {
        case "6":
            return "Key box to the right by garbage cans. Roof gutter + drain on 2nd floor roof (access via Apt 2R)."
        case "14":
            return "No elevator. Five-story walk-ups across 142–148 W 17th."
        case "16":
            return "Outdoor park site. No elevator; seasonal operations."
        case "15":
            return "Lobby on ground floor; 4 units on floors 1–4 (16 units)."
        case "19":
            return "No residential units. Daily poster removal, treepit cleaning, sidewalk hosing; paint graffiti as needed."
        case "21":
            return "7 residential units; top-floor duplex. Private elevator opens directly into unit. 1 staircase."
        default:
            return nil
        }
    }
}
