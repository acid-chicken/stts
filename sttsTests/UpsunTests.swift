//
//  UpsunTests.swift
//  sttsTests
//

import XCTest
@testable import stts

@MainActor
final class UpsunTests: XCTestCase {
    private let incidentsURL = URL(string: "https://status.upsun.com/data/incidents.json")!

    func testResolvesFromLegacyIdentifiers() throws {
        // swiftlint:disable:next force_try
        let appDefined = try! AppDefinedServiceDefinitionProvider()
        // swiftlint:disable:next force_try
        let bundled = try! BundleServiceDefinitionProvider()
        let loader = ServiceLoader(providers: [appDefined, bundled])

        for legacyIdentifier in ["Platform.sh", "PlatformSH"] {
            let definition = try XCTUnwrap(
                loader.serviceDefinition(forIdentifier: legacyIdentifier),
                "Expected \(legacyIdentifier) to resolve to the Upsun definition"
            )
            XCTAssertEqual(definition.name, "Upsun")
        }
    }

    func testGoodStatus() async throws {
        let upsun = Upsun()

        DataLoader.shared = DataLoader(session: ResponseOverridingURLSession(overrides: [
            .init(url: incidentsURL, response: Data("""
            { "incidents": [
                { "description": "Old resolved incident", "closed_at": "2026-08-01T00:00:00Z",
                  "components": [{ "status": "major_outage" }] }
            ] }
            """.utf8))
        ]))

        try await upsun.updateStatus()
        XCTAssertEqual(upsun.status, .good)
        XCTAssertEqual(upsun.message, "All Systems Operational")
    }

    func testMajorStatusFromOpenIncident() async throws {
        let upsun = Upsun()

        DataLoader.shared = DataLoader(session: ResponseOverridingURLSession(overrides: [
            .init(url: incidentsURL, response: Data("""
            { "incidents": [
                { "description": "Old resolved incident", "closed_at": "2026-08-01T00:00:00Z",
                  "components": [{ "status": "major_outage" }] },
                { "description": "Outage on uk-1.platform.sh", "closed_at": null,
                  "components": [{ "status": "major_outage" }] },
                { "description": "Degraded Performance on fr-3.platform.sh", "closed_at": null,
                  "components": [{ "status": "degraded_performance" }] }
            ] }
            """.utf8))
        ]))

        try await upsun.updateStatus()
        XCTAssertEqual(upsun.status, .major)
        XCTAssertEqual(
            upsun.message,
            "* Outage on uk-1.platform.sh\n* Degraded Performance on fr-3.platform.sh"
        )
    }
}
