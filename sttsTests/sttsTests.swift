//
//  sttsTests.swift
//  sttsTests
//

import XCTest
@testable import stts

// Live integration tests: each hits its provider's real status page(s) and asserts the parsed
// status isn't .undetermined. testServices() runs everything (slow — see the per-service stagger
// below); the rest run one JSON provider each, so e.g. `-only-testing:sttsTests/SttsTests/testAWSNamedServices`
// checks just AWS without waiting on StatusPage's throttle or any other provider.
class SttsTests: XCTestCase {
    override func setUpWithError() throws {
        DataLoader.shared = DataLoader(session: ResponseSizeTrackingURLSession())
    }

    private func assertLiveStatus(forProviders providerIdentifiers: Set<String>? = nil) async throws {
        var serviceDefinitionProviders: [ServiceDefinitionProvider] = []
        // swiftlint:disable:next force_try
        serviceDefinitionProviders.append(try! AppDefinedServiceDefinitionProvider())
        // swiftlint:disable:next force_try
        serviceDefinitionProviders.append(try! BundleServiceDefinitionProvider())
        if let userDefinedServiceDefinitionsProvider = try? UserDefinedServiceDefinitionProvider() {
            serviceDefinitionProviders.append(userDefinedServiceDefinitionsProvider)
        }

        var serviceDefinitions = await ServiceLoader(providers: serviceDefinitionProviders).allServices
        if let providerIdentifiers {
            serviceDefinitions = serviceDefinitions.filter { providerIdentifiers.contains($0.providerIdentifier) }
        }

        var testedServices: [BaseService] = [] // Have to retain services until the end of the test

        print("Retrieving status for \(serviceDefinitions.count) services")

        await withTaskGroup(of: Void.self) { group in
            var sleepDuration: TimeInterval = 0

            for serviceDefinition in serviceDefinitions {
                guard let service = serviceDefinition.build() as? Service else {
                    XCTFail("Could not build service for definition: \(serviceDefinition)")
                    continue
                }

                testedServices.append(service)

                if service is StatusPageService {
                    // Status page servers don't like being hammered by this many requests, so we slow it down.
                    // I really wish they would add an API for querying the status of many services at once.
                    sleepDuration += 1
                }

                print("Retrieving status for \(service.name)…")

                group.addTask { [sleepDuration] in
                    do {
                        try await Task.sleep(seconds: sleepDuration)
                        try await service.updateStatus()

                        print(
                            """
                            Retrieved status for \(service.name): \(service.status)\
                            (\(service.message))
                            """
                        )

                        XCTAssert(
                            service.status != .undetermined,
                            "Retrieved status for \(service.name) should not be .undetermined"
                        )
                    } catch {
                        XCTFail("Failed retrieving status for \(service.name): \(error)")
                    }
                }
            }
        }

        testedServices = []
    }

    func testServices() async throws {
        try await assertLiveStatus()
    }

    // One test per services.json top-level provider key (see ServicesStructure.CodingKeys), so any
    // one of these can run in isolation via -only-testing.
    func testIndependentServices() async throws { try await assertLiveStatus(forProviders: ["independent"]) }
    func testCachetServices() async throws { try await assertLiveStatus(forProviders: ["cachet"]) }
    func testLambServices() async throws { try await assertLiveStatus(forProviders: ["lamb"]) }
    func testSorryServices() async throws { try await assertLiveStatus(forProviders: ["sorry"]) }
    func testStatusCakeServices() async throws { try await assertLiveStatus(forProviders: ["statuscake"]) }
    func testStatusPageServices() async throws { try await assertLiveStatus(forProviders: ["statuspage"]) }
    func testInstatusServices() async throws { try await assertLiveStatus(forProviders: ["instatus"]) }
    func testStatusCastServices() async throws { try await assertLiveStatus(forProviders: ["statuscast"]) }
    func testIncidentIOServices() async throws { try await assertLiveStatus(forProviders: ["incidentio"]) }
    func testStatusioV1Services() async throws { try await assertLiveStatus(forProviders: ["statusiov1"]) }
    func testStatuspalServices() async throws { try await assertLiveStatus(forProviders: ["statuspal"]) }
    func testSite24x7Services() async throws { try await assertLiveStatus(forProviders: ["site24x7"]) }
    func testCStateServices() async throws { try await assertLiveStatus(forProviders: ["cstate"]) }
    func testStatusHubServices() async throws { try await assertLiveStatus(forProviders: ["statushub"]) }
    func testBetterUptimeServices() async throws { try await assertLiveStatus(forProviders: ["betteruptime"]) }
    func testBetterStackServices() async throws { try await assertLiveStatus(forProviders: ["betterstack"]) }
    func testSendbirdServices() async throws { try await assertLiveStatus(forProviders: ["sendbird"]) }
    func testMiroServices() async throws { try await assertLiveStatus(forProviders: ["miro"]) }
    func testPagerDutyServices() async throws { try await assertLiveStatus(forProviders: ["pagerduty"]) }
    func testAzureServices() async throws { try await assertLiveStatus(forProviders: ["azure"]) }
    func testAzureDevOpsServices() async throws { try await assertLiveStatus(forProviders: ["azuredevops"]) }
    func testFirebaseServices() async throws { try await assertLiveStatus(forProviders: ["firebase"]) }
    func testSalesforceServices() async throws { try await assertLiveStatus(forProviders: ["salesforce"]) }
    func testAdobeServices() async throws { try await assertLiveStatus(forProviders: ["adobe"]) }
    func testAppleServices() async throws { try await assertLiveStatus(forProviders: ["apple"]) }
    func testAppleDeveloperServices() async throws { try await assertLiveStatus(forProviders: ["appledeveloper"]) }
    func testGoogleCloudPlatformServices() async throws {
        try await assertLiveStatus(forProviders: ["googlecloudplatform"])
    }
    func testAWSRegionServices() async throws { try await assertLiveStatus(forProviders: ["awsregions"]) }
    func testAWSNamedServices() async throws { try await assertLiveStatus(forProviders: ["awsservices"]) }
}
