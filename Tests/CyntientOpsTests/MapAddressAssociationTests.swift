import XCTest
@testable import CyntientOps

final class MapAddressAssociationTests: XCTestCase {
    func testBuildingAddressesAndCoordinatesArePlausible() async throws {
        let db = GRDBManager.shared
        // Pull all buildings
        let rows = try await db.query("SELECT id, name, address, latitude, longitude FROM buildings ORDER BY id")
        XCTAssertGreaterThan(rows.count, 0, "No buildings found in database")

        for row in rows {
            let id = String(describing: row["id"] ?? "")
            let name = row["name"] as? String ?? ""
            let address = row["address"] as? String ?? ""
            let lat = row["latitude"] as? Double ?? 0
            let lon = row["longitude"] as? Double ?? 0

            // Basic sanity: non-empty address and plausible Manhattan-ish coordinates
            XCTAssertFalse(address.isEmpty, "Building \(id) (\(name)) has empty address")
            XCTAssertTrue(lat > 40.4 && lat < 41.1, "Latitude out of NYC bounds for building \(id)")
            XCTAssertTrue(lon > -74.4 && lon < -73.5, "Longitude out of NYC bounds for building \(id)")
        }
    }

    func testKeyPortfolioAddresses() async throws {
        // Spot-check key buildings for expected address fragments
        let db = GRDBManager.shared
        let perry131 = try await db.query("SELECT address FROM buildings WHERE id = ?", ["10"]).first?["address"] as? String ?? ""
        let firstAve123 = try await db.query("SELECT address FROM buildings WHERE id = ?", ["11"]).first?["address"] as? String ?? ""

        XCTAssertTrue(perry131.lowercased().contains("perry"), "131 Perry address should contain 'Perry' but was \(perry131)")
        XCTAssertTrue(firstAve123.lowercased().contains("1st") || firstAve123.lowercased().contains("first"), "123 1st Ave address should contain '1st' or 'First' but was \(firstAve123)")
    }

    func testBuildingAssetMappingExistsForKeyBuildings() {
        XCTAssertEqual(BuildingAssets.assetName(for: "10"), "131_Perry_Street")
        XCTAssertEqual(BuildingAssets.assetName(for: "11"), "123_1st_Avenue")
    }
}

