//
//  BetterStackTests.swift
//  sttsTests
//

import XCTest
@testable import stts

final class BetterStackTests: XCTestCase {
    private func createService() throws -> BetterStackService {
        let definition = try JSONDecoder().decode(
            BetterStackServiceDefinition.self,
            from: Data("""
            {
                "url": "https://status.keygen.sh",
                "name": "Keygen"
            }
            """.utf8)
        )

        return try XCTUnwrap(definition.build() as? BetterStackService)
    }

    func testNormalStatus() async throws {
        let keygen = try createService()

        DataLoader.shared = DataLoader(session: ResponseOverridingURLSession(overrides: [
            .init(
                url: keygen.url,
                response: try Data(
                    contentsOf: Bundle.test.url(forResource: "keygen-good", withExtension: "html")!
                )
            )
        ]))

        try await keygen.updateStatus()
        XCTAssertEqual(keygen.status, .good)
    }

    func testMajorStatus() async throws {
        let keygen = try createService()

        DataLoader.shared = DataLoader(session: ResponseOverridingURLSession(overrides: [
            .init(
                url: keygen.url,
                response: try Data(
                    contentsOf: Bundle.test.url(forResource: "eyloo-major", withExtension: "html")!
                )
            )
        ]))

        try await keygen.updateStatus()
        XCTAssertEqual(keygen.status, .major)
    }
}
