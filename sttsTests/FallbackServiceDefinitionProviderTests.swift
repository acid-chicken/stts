//
//  FallbackServiceDefinitionProviderTests.swift
//  sttsTests
//

import XCTest
@testable import stts

// Covers the case where a service removed from a remote-fetched services.json would still show up
// because it lingers in the (older) bundled copy — ServiceLoader unions providers by identifier
// (first-seen wins, never subtracts), so a plain [remote, bundled] provider list can't express
// "remote's absence of X should hide bundled's X". FallbackServiceDefinitionProvider fixes this by
// making primary wholesale-replace fallback (not merge) once primary has any data.
@MainActor
final class FallbackServiceDefinitionProviderTests: XCTestCase {
    private final class FakeServiceDefinitionProvider: ServiceDefinitionProvider {
        var definitions: [ServiceDefinition]?
        var removed: Set<String>
        private(set) var reloadCallCount = 0

        init(definitions: [ServiceDefinition]?, removed: Set<String> = []) {
            self.definitions = definitions
            self.removed = removed
        }

        func definedServices() throws -> [ServiceDefinition]? { definitions }
        var removedIdentifiers: Set<String> { removed }
        func reload() { reloadCallCount += 1 }
    }

    private func realDefinitions(count: Int) throws -> [ServiceDefinition] {
        // swiftlint:disable:next force_try
        let allDefined = try XCTUnwrap(try! AppDefinedServiceDefinitionProvider().definedServices())
        return Array(allDefined.prefix(count))
    }

    func testPrimaryReplacesFallbackWholesaleRatherThanMerging() throws {
        let shared = try realDefinitions(count: 1)
        let fallbackOnly = try realDefinitions(count: 2).last.map { [$0] } ?? []

        let primary = FakeServiceDefinitionProvider(definitions: shared)
        let fallback = FakeServiceDefinitionProvider(definitions: shared + fallbackOnly)
        let wrapped = FallbackServiceDefinitionProvider(primary: primary, fallback: fallback)

        let result = try XCTUnwrap(try wrapped.definedServices())
        let resultIdentifiers = Set(result.map(\.globalIdentifier))

        XCTAssertEqual(resultIdentifiers, Set(shared.map(\.globalIdentifier)))
        for definition in fallbackOnly {
            XCTAssertFalse(
                resultIdentifiers.contains(definition.globalIdentifier),
                "\(definition.globalIdentifier) only exists in the fallback source and should not " +
                "leak through once primary has data"
            )
        }
    }

    func testFallsBackWhenPrimaryIsEmpty() throws {
        let fallbackDefinitions = try realDefinitions(count: 2)

        let primary = FakeServiceDefinitionProvider(definitions: [])
        let fallback = FakeServiceDefinitionProvider(definitions: fallbackDefinitions)
        let wrapped = FallbackServiceDefinitionProvider(primary: primary, fallback: fallback)

        let result = try XCTUnwrap(try wrapped.definedServices())
        XCTAssertEqual(Set(result.map(\.globalIdentifier)), Set(fallbackDefinitions.map(\.globalIdentifier)))
    }

    func testFallsBackWhenPrimaryIsNil() throws {
        let fallbackDefinitions = try realDefinitions(count: 1)

        let primary = FakeServiceDefinitionProvider(definitions: nil)
        let fallback = FakeServiceDefinitionProvider(definitions: fallbackDefinitions)
        let wrapped = FallbackServiceDefinitionProvider(primary: primary, fallback: fallback)

        let result = try XCTUnwrap(try wrapped.definedServices())
        XCTAssertEqual(Set(result.map(\.globalIdentifier)), Set(fallbackDefinitions.map(\.globalIdentifier)))
    }

    func testRemovedIdentifiersOnlyReflectTheActiveSource() throws {
        let definitions = try realDefinitions(count: 1)

        let primary = FakeServiceDefinitionProvider(definitions: definitions, removed: ["primary.Removed"])
        let fallback = FakeServiceDefinitionProvider(definitions: definitions, removed: ["fallback.Removed"])
        let wrapped = FallbackServiceDefinitionProvider(primary: primary, fallback: fallback)

        XCTAssertEqual(wrapped.removedIdentifiers, ["primary.Removed"])

        primary.definitions = []
        XCTAssertEqual(wrapped.removedIdentifiers, ["fallback.Removed"])
    }

    func testReloadForwardsToBothSources() {
        let primary = FakeServiceDefinitionProvider(definitions: [])
        let fallback = FakeServiceDefinitionProvider(definitions: [])
        let wrapped = FallbackServiceDefinitionProvider(primary: primary, fallback: fallback)

        wrapped.reload()

        XCTAssertEqual(primary.reloadCallCount, 1)
        XCTAssertEqual(fallback.reloadCallCount, 1)
    }

    /// End-to-end through `ServiceLoader` (not just the isolated wrapper): a service present in the
    /// real bundled services.json but absent from a "remote" fetch must not show up in
    /// `allServices` — this is the exact scenario the user asked about.
    func testServiceRemovedFromPrimaryDoesNotLeakThroughServiceLoader() throws {
        // swiftlint:disable:next force_try
        let appDefined = try! AppDefinedServiceDefinitionProvider()
        let allBundledDefinitions = try XCTUnwrap(try appDefined.definedServices())
        let removedDefinition = try XCTUnwrap(allBundledDefinitions.first)
        let remainingDefinitions = allBundledDefinitions.filter {
            $0.globalIdentifier != removedDefinition.globalIdentifier
        }

        let fakeRemote = FakeServiceDefinitionProvider(definitions: remainingDefinitions)
        let wrapped = FallbackServiceDefinitionProvider(primary: fakeRemote, fallback: appDefined)
        let loader = ServiceLoader(providers: [wrapped])

        XCTAssertNil(loader.serviceDefinition(forIdentifier: removedDefinition.globalIdentifier))
        XCTAssertEqual(loader.allServices.count, remainingDefinitions.count)
    }
}
