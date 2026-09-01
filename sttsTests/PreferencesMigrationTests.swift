//
//  PreferencesMigrationTests.swift
//  sttsTests
//

import XCTest
@testable import stts

@MainActor
final class PreferencesMigrationTests: XCTestCase {
    private var savedSelectedServices: [String]?

    override func setUpWithError() throws {
        savedSelectedServices = UserDefaults.standard.array(forKey: "selectedServices") as? [String]
    }

    override func tearDownWithError() throws {
        if let savedSelectedServices {
            UserDefaults.standard.setValue(savedSelectedServices, forKey: "selectedServices")
        } else {
            UserDefaults.standard.removeObject(forKey: "selectedServices")
        }
    }

    func testMigratesProviderChangedIdentifiers() throws {
        let oldIdentifierToExpectedName: [String: String] = [
            "statuspage.Fivetran": "Fivetran",
            "statuspage.Notion": "Notion",
            "independent.Recurly": "Recurly",
            "statusiov1.SumoLogic": "SumoLogic",
            "independent.PagerDuty": "PagerDuty",
            "independent.SignalWire": "SignalWire",
            "statuspage.Platformsh": "Upsun",
            "instatus.Railway": "Railway"
        ]

        UserDefaults.standard.setValue(Array(oldIdentifierToExpectedName.keys), forKey: "selectedServices")

        // swiftlint:disable:next force_try
        let appDefined = try! AppDefinedServiceDefinitionProvider()
        // swiftlint:disable:next force_try
        let bundled = try! BundleServiceDefinitionProvider()
        let serviceLoader = ServiceLoader(providers: [appDefined, bundled])
        let preferences = Preferences(serviceLoader: serviceLoader)

        let resolvedNames = Set(preferences.selectedServices.map(\.name))
        XCTAssertEqual(resolvedNames, Set(oldIdentifierToExpectedName.values))
    }

    /// A service confirmed gone for good and one that's merely temporarily unreachable behave
    /// differently: only the former should ever be pruned. `services.json`'s real `_removed` list is
    /// deliberately empty right now (nothing the app has integrated has actually shut down), so this
    /// exercises the mechanism with a synthetic provider instead of depending on that being non-empty.
    private struct FakeRemovedServiceProvider: ServiceDefinitionProvider {
        func definedServices() throws -> [ServiceDefinition]? { [] }

        var removedIdentifiers: Set<String> {
            // "independent.Fivetran" is deliberately a real, currently-resolvable identifier: it
            // must NOT be pruned even though it's (incorrectly, for this test) listed as removed —
            // that's the safety net in `Preferences.removeDeletedServices()`.
            ["independent.DefinitelyGoneForGood", "independent.Fivetran"]
        }
    }

    func testPrunesOnlyServicesConfirmedGoneForGood() throws {
        UserDefaults.standard.setValue(
            ["independent.DefinitelyGoneForGood", "independent.Fivetran"],
            forKey: "selectedServices"
        )

        // swiftlint:disable:next force_try
        let appDefined = try! AppDefinedServiceDefinitionProvider()
        // swiftlint:disable:next force_try
        let bundled = try! BundleServiceDefinitionProvider()
        let serviceLoader = ServiceLoader(providers: [appDefined, bundled, FakeRemovedServiceProvider()])
        let preferences = Preferences(serviceLoader: serviceLoader)

        let resolvedNames = Set(preferences.selectedServices.map(\.name))
        XCTAssertEqual(resolvedNames, ["Fivetran"])

        let storedIdentifiers = UserDefaults.standard.array(forKey: "selectedServices") as? [String] ?? []
        XCTAssertFalse(storedIdentifiers.contains("independent.DefinitelyGoneForGood"))
        XCTAssertTrue(storedIdentifiers.contains("independent.Fivetran"))
    }
}
