import XCTest
@testable import AuthenticationServicesMiddleware

final class AuthenticationServicesMiddlewareTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(AuthenticationServicesMiddleware().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
