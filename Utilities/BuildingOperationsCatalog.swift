import Foundation

/// Operational policies per building which inform weather-triggered and routine tasks.
/// Keep this catalog as the single source for building-specific nuances (rain mats, roof drains, DSNY windows, etc.).
struct BuildingOperationsCatalog {
    struct RainMatPolicy { let hasRainMats: Bool; let responsibleWorkerId: String? }
    struct RoofDrainPolicy { let checkBeforeRain: Bool; let responsibleWorkerId: String? }
    struct DSNYPolicy { let bringInByHour: Int? } // e.g., 10am next day
    struct WinterPolicy { let saltBeforeSnow: Bool; let shovelAfterSnowWithinHours: Int }
    struct SeasonalPolicy { let leafBlower: Bool; let fallMonths: [Int]; let curbClearInches: Int }
    struct BackyardPolicy { let drainSweepMonthly: Bool }

    struct Policy {
        let rainMats: RainMatPolicy?
        let roofDrains: RoofDrainPolicy?
        let dsny: DSNYPolicy?
        let winter: WinterPolicy?
        let seasonal: SeasonalPolicy?
        let backyard: BackyardPolicy?
    }

    /// Catalog keyed by buildingId (see CanonicalIDs.Buildings)
    static let map: [String: Policy] = {
        let edwin = CanonicalIDs.Workers.edwinLema
        let greg  = CanonicalIDs.Workers.gregHutson

        // Shared policies
        let defaultWinter = WinterPolicy(saltBeforeSnow: true, shovelAfterSnowWithinHours: 4)
        let defaultDSNY   = DSNYPolicy(bringInByHour: 10)
        let defaultFall   = SeasonalPolicy(leafBlower: true, fallMonths: [9,10,11], curbClearInches: 18)

        var m: [String: Policy] = [:]

        // 12 West 18th — Rain mats, roof drains (Greg)
        m[CanonicalIDs.Buildings.westEighteenth12] = Policy(
            rainMats: RainMatPolicy(hasRainMats: true, responsibleWorkerId: greg),
            roofDrains: RoofDrainPolicy(checkBeforeRain: true, responsibleWorkerId: greg),
            dsny: defaultDSNY, winter: defaultWinter, seasonal: defaultFall, backyard: nil
        )

        // 112 West 18th — Rain mats, roof drains (Edwin)
        m[CanonicalIDs.Buildings.westEighteenth112] = Policy(
            rainMats: RainMatPolicy(hasRainMats: true, responsibleWorkerId: edwin),
            roofDrains: RoofDrainPolicy(checkBeforeRain: true, responsibleWorkerId: edwin),
            dsny: defaultDSNY, winter: defaultWinter, seasonal: defaultFall, backyard: nil
        )

        // 117 West 17th — Rain mats, roof drains (Edwin)
        m[CanonicalIDs.Buildings.westSeventeenth117] = Policy(
            rainMats: RainMatPolicy(hasRainMats: true, responsibleWorkerId: edwin),
            roofDrains: RoofDrainPolicy(checkBeforeRain: true, responsibleWorkerId: edwin),
            dsny: defaultDSNY, winter: defaultWinter, seasonal: defaultFall, backyard: nil
        )

        // 135–139 West 17th — Roof drains (Edwin), backyard drain/sweep monthly at 135
        m[CanonicalIDs.Buildings.westSeventeenth135_139] = Policy(
            rainMats: nil,
            roofDrains: RoofDrainPolicy(checkBeforeRain: true, responsibleWorkerId: edwin),
            dsny: defaultDSNY, winter: defaultWinter, seasonal: defaultFall,
            backyard: BackyardPolicy(drainSweepMonthly: true)
        )

        // 138 West 17th — Roof drains (Edwin), backyard swept monthly
        m[CanonicalIDs.Buildings.westSeventeenth138] = Policy(
            rainMats: nil,
            roofDrains: RoofDrainPolicy(checkBeforeRain: true, responsibleWorkerId: edwin),
            dsny: defaultDSNY, winter: defaultWinter, seasonal: defaultFall,
            backyard: BackyardPolicy(drainSweepMonthly: true)
        )

        // Others — apply default winter + DSNY + fall leaves as baseline
        for id in [
            CanonicalIDs.Buildings.perry68,
            CanonicalIDs.Buildings.perry131,
            CanonicalIDs.Buildings.firstAvenue123,
            CanonicalIDs.Buildings.elizabeth41,
            CanonicalIDs.Buildings.walker36,
            CanonicalIDs.Buildings.franklin104,
            CanonicalIDs.Buildings.rubinMuseum,
            CanonicalIDs.Buildings.eastFifteenth133,
            CanonicalIDs.Buildings.stuyvesantCove,
            CanonicalIDs.Buildings.springStreet178,
            CanonicalIDs.Buildings.seventhAvenue115,
            CanonicalIDs.Buildings.chambers148
        ] {
            if m[id] == nil { m[id] = Policy(rainMats: nil, roofDrains: nil, dsny: defaultDSNY, winter: defaultWinter, seasonal: defaultFall, backyard: nil) }
        }

        return m
    }()

    // Helpers
    static func buildingsWithRainMats(groupedByWorker: Bool = false) -> [String: [String]] {
        var byWorker: [String: [String]] = [:]
        for (id, policy) in map {
            guard let mats = policy.rainMats, mats.hasRainMats else { continue }
            let wid = mats.responsibleWorkerId ?? ""
            byWorker[wid, default: []].append(id)
        }
        return byWorker
    }

    static func buildingsForRoofDrainsGroupedByWorker() -> [String: [String]] {
        var byWorker: [String: [String]] = [:]
        for (id, policy) in map {
            if let drains = policy.roofDrains, drains.checkBeforeRain {
                let wid = drains.responsibleWorkerId ?? ""
                byWorker[wid, default: []].append(id)
            }
        }
        return byWorker
    }
}

