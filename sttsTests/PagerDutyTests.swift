//
//  PagerDutyTests.swift
//  sttsTests
//

import XCTest
@testable import stts

final class PagerDutyTests: XCTestCase {
    private func createPagerDutyService() throws -> PagerDutyService {
        let definition = try JSONDecoder().decode(
            PagerDutyServiceDefinition.self,
            from: Data("""
            {
                "name": "PagerDuty",
                "url": "https://status.pagerduty.com"
            }
            """.utf8)
        )

        return try XCTUnwrap(definition.build() as? PagerDutyService)
    }

    func testNormalStatus() async throws {
        let pagerDuty = try createPagerDutyService()

        DataLoader.shared = DataLoader(session: ResponseOverridingURLSession(overrides: [
            .init(
                url: pagerDuty.url,
                response: try Data(contentsOf: Bundle.test.url(forResource: "pagerduty-good", withExtension: "html")!)
            )
        ]))

        try await pagerDuty.updateStatus()
        XCTAssertEqual(pagerDuty.status, .good)
        XCTAssertEqual(pagerDuty.message, "No known issue")
    }

    func testMinorStatus() async throws {
        let pagerDuty = try createPagerDutyService()

        DataLoader.shared = DataLoader(session: ResponseOverridingURLSession(overrides: [
            .init(
                url: pagerDuty.url,
                response: try Data(contentsOf: Bundle.test.url(
                    forResource: "pagerduty-minor",
                    withExtension: "html"
                )!)
            )
        ]))

        try await pagerDuty.updateStatus()
        XCTAssertEqual(pagerDuty.status, .minor)
        XCTAssertEqual(pagerDuty.message, "Inconsistent Service Statuses")
    }
}
