//
//  SalesforceStore.swift
//  SalesforceStore
//

import Foundation

protocol SalesforceStoreService {
    var key: String { get }
    var location: String { get }
}

extension SalesforceStoreService {
    // Shared per-product, so a category row and its region subservices reuse one fetch instead of
    // each triggering their own (SalesforceStore/ServiceStore cache/throttle is per-instance).
    var store: SalesforceStore { SalesforceStoreCache.store(forProduct: key) }
}

private enum SalesforceStoreCache {
    // updateStatus() is called concurrently across services (see sttsTests.testServices()), so
    // this needs real synchronization, not a plain static var.
    @Atomic private static var stores: [String: SalesforceStore] = [:]

    static func store(forProduct product: String) -> SalesforceStore {
        if let existing = stores[product] { return existing }

        let store = SalesforceStore(key: product)
        stores[product] = store
        return store
    }
}

class SalesforceStore: ServiceStore<[String: ServiceStatus]> {
    let key: String

    private var url: URL {
        URL(string: "https://api.status.salesforce.com/v1/instances/status/preview?products=\(key)")!
    }

    init(key: String) {
        self.key = key
    }

    override func retrieveUpdatedState() async throws -> [String: ServiceStatus] {
        let instances = try await decoded([SalesforceResponseData.Instance].self, from: url)

        var serviceStatuses = [String: ServiceStatus]()

        instances.forEach { instance in
            var locationStatus = serviceStatuses[instance.location] ?? .undetermined
            locationStatus = [locationStatus, instance.status.serviceStatus].max() ?? .undetermined
            serviceStatuses[instance.location] = locationStatus

            var allLocationsStatus = serviceStatuses["*"] ?? .undetermined
            allLocationsStatus = [allLocationsStatus, instance.status.serviceStatus].max() ?? .undetermined
            serviceStatuses["*"] = allLocationsStatus
        }

        return serviceStatuses
    }

    func updatedStatus(for service: SalesforceStoreService) async throws -> ServiceStatusDescription {
        let updatedState = try await updatedState()
        let status = updatedState[service.location] ?? .undetermined
        let message: String

        switch status {
        case .good:
            message = "Available"
        case .minor:
            message = "Performance Degradation"
        case .major:
            message = "Service Disruption"
        case .maintenance:
            message = "Maintenance"
        case .notice:
            message = "Notice"
        case .undetermined:
            message = loadErrorMessage ?? "Unexpected error"
        }

        return ServiceStatusDescription(status: status, message: message)
    }
}

private struct SalesforceResponseData: Codable {
    struct Instance: Codable {
        enum CodingKeys: String, CodingKey {
            case location
            case status
        }

        let location: String
        let status: Status
    }

    enum Status: String, Codable {
        case ok = "OK"
        case maintenanceNonCore = "MAINTENANCE_NONCORE"
        case maintenanceCore = "MAINTENANCE_CORE"
        case minorNonCore = "MINOR_INCIDENT_NONCORE"
        case minorCore = "MINOR_INCIDENT_CORE"
        case majorNonCore = "MAJOR_INCIDENT_NONCORE"
        case majorCore = "MAJOR_INCIDENT_CORE"

        var serviceStatus: ServiceStatus {
            switch self {
            case .ok: return .good
            case .maintenanceNonCore, .maintenanceCore: return .maintenance
            case .minorNonCore, .minorCore, .majorNonCore: return .minor
            case .majorCore: return .major
            }
        }
    }
}
