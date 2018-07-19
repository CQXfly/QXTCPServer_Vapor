import XCTest
@testable import QXTCPServer

final class QXTCPServerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(QXTCPServer().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
