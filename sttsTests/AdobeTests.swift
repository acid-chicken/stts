//
//  AdobeTests.swift
//  sttsTests
//

import XCTest
@testable import stts

final class AdobeTests: XCTestCase {
    private func createService(id: String, name: String, cloud: String, isCategory: Bool) throws -> BaseService {
        let categoryField = isCategory ? ", \"category\": true" : ""
        let definition = try JSONDecoder().decode(
            AdobeServiceDefinition.self,
            from: Data("""
            {
                "id": "\(id)",
                "name": "\(name)",
                "cloud": "\(cloud)"\(categoryField)
            }
            """.utf8)
        )

        return try XCTUnwrap(definition.build())
    }

    func testParsingStatus() async throws {
        let adobeCreativeCloud = try createService(
            id: "503459", name: "Adobe Creative Cloud", cloud: "CreativeCloud", isCategory: true
        )
        let adobePremierePro = try createService(
            id: "999999999", name: "Adobe Premiere Pro", cloud: "CreativeCloud", isCategory: false
        )

        // Should be .minor because Adobe Analytics is affected
        let adobeExperienceCloud = try createService(
            id: "503461", name: "Adobe Experience Cloud", cloud: "ExperienceCloud", isCategory: true
        )
        let adobeAnalytics = try createService(
            id: "503467", name: "Adobe Analytics", cloud: "ExperienceCloud", isCategory: false
        )

        DataLoader.shared = DataLoader(session: ResponseOverridingURLSession(overrides: [
            .init(
                url: BaseAdobe.store.url,
                response: try Data(
                    contentsOf: Bundle.test.url(forResource: "adobe-analytics-minor", withExtension: "json")!
                )
            )
        ]))

        try await adobePremierePro.updateStatus()
        XCTAssertEqual(adobePremierePro.status, .good)

        try await adobeCreativeCloud.updateStatus()
        XCTAssertEqual(adobeCreativeCloud.status, .good)

        try await adobeAnalytics.updateStatus()
        XCTAssertEqual(adobeAnalytics.status, .minor)

        try await adobeExperienceCloud.updateStatus()
        XCTAssertEqual(adobeExperienceCloud.status, .minor)
    }
}
