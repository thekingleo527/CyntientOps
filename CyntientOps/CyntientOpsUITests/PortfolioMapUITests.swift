import XCTest

final class PortfolioMapUITests: XCTestCase {
    func testMapIsPrimaryAndNoPortfolioSheet() throws {
        let app = XCUIApplication()
        app.launch()

        // Assert a map exists on the main screen (SwiftUI Map renders as MKMapView)
        // We look for any map by querying for an element with type .map or identified by accessibility
        let mapExists = app.maps.element(boundBy: 0).waitForExistence(timeout: 5)
        XCTAssertTrue(mapExists, "Expected primary full-screen map to be present")

        // Ensure no sheet titled "My Buildings Portfolio" is presented
        let portfolioTitle = app.staticTexts["My Buildings Portfolio"]
        XCTAssertFalse(portfolioTitle.exists, "Portfolio drawer/sheet should not be presented")
    }
}

