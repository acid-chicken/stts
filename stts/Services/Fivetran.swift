//
//  Fivetran.swift
//  stts
//

import Foundation

final class Fivetran: IndependentService {
    let url = URL(string: "https://status.fivetran.com")!

    override func updateStatus() async throws {
        let statusURL = URL(string: "https://status.fivetran.com/api/v1/status")!
        let activeURL = URL(string: "https://status.fivetran.com/api/v1/active")!

        let statusResponse = try await decoded(StatusResponse.self, from: statusURL)
        let activeResponse = try await decoded(ActiveResponse.self, from: activeURL)

        let status = (statusResponse.groups.map(\.status) + statusResponse.ungroupedServices.map(\.status))
            .map(\.serviceStatus)
            .max() ?? .undetermined

        let message: String
        if activeResponse.incidents.isEmpty {
            message = status == .good ? "All Systems Operational" : "Some systems are experiencing problems"
        } else {
            message = activeResponse.incidents.map { "* \($0.title)" }.joined(separator: "\n")
        }

        statusDescription = ServiceStatusDescription(status: status, message: message)
    }
}

private enum FivetranStatus: String, Codable {
    case operational
    case degradedPerformance = "degraded_performance"
    case partialOutage = "partial_outage"
    case majorOutage = "major_outage"
    case underMaintenance = "under_maintenance"

    var serviceStatus: ServiceStatus {
        switch self {
        case .operational: return .good
        case .underMaintenance: return .maintenance
        case .degradedPerformance, .partialOutage: return .minor
        case .majorOutage: return .major
        }
    }
}

private struct FivetranComponent: Codable {
    let status: FivetranStatus
}

private struct FivetranGroup: Codable {
    let status: FivetranStatus
}

private struct StatusResponse: Codable {
    let groups: [FivetranGroup]
    let ungroupedServices: [FivetranComponent]

    enum CodingKeys: String, CodingKey {
        case groups
        case ungroupedServices = "ungrouped_services"
    }
}

private struct FivetranIncident: Codable {
    let title: String
}

private struct ActiveResponse: Codable {
    let incidents: [FivetranIncident]
}
