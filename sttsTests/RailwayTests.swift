//
//  RailwayTests.swift
//  sttsTests
//

import XCTest
@testable import stts

final class RailwayTests: XCTestCase {
    private let statusURL = URL(string: "https://status.railway.com/api/status")!

    func testGoodStatus() async throws {
        let railway = Railway()

        DataLoader.shared = DataLoader(session: ResponseOverridingURLSession(overrides: [
            .init(url: statusURL, response: Data("""
            { "activeIncidents": [] }
            """.utf8))
        ]))

        try await railway.updateStatus()
        XCTAssertEqual(railway.status, .good)
        XCTAssertEqual(railway.message, "All Systems Operational")
    }

    func testMajorStatusFromActiveIncident() async throws {
        let railway = Railway()

        DataLoader.shared = DataLoader(session: ResponseOverridingURLSession(overrides: [
            .init(url: statusURL, response: Data("""
            { "activeIncidents": [
                { "title": "Storage and networking issues affecting some services in US West",
                  "components": [
                    { "impact": "PARTIAL_OUTAGE" },
                    { "impact": "MAJOR_OUTAGE" }
                  ] },
                { "title": "Elevated error rates in EU West",
                  "components": [{ "impact": "DEGRADED_PERFORMANCE" }] }
            ] }
            """.utf8))
        ]))

        try await railway.updateStatus()
        XCTAssertEqual(railway.status, .major)
        XCTAssertEqual(
            railway.message,
            "* Storage and networking issues affecting some services in US West\n* Elevated error rates in EU West"
        )
    }
}
