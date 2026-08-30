//
//  Upsun.swift
//  stts
//

import Foundation

final class Upsun: IndependentService {
    override static var oldNames: Set<String>? { ["Platform.sh", "PlatformSH"] }

    let name = "Upsun"
    let url = URL(string: "https://status.upsun.com")!

    override func updateStatus() async throws {
        let incidentsURL = URL(string: "https://status.upsun.com/data/incidents.json")!
        let response = try await decoded(IncidentsResponse.self, from: incidentsURL)

        let openIncidents = response.incidents.filter { $0.closedAt == nil }

        if openIncidents.isEmpty {
            statusDescription = ServiceStatusDescription(status: .good, message: "All Systems Operational")
        } else {
            let status = openIncidents
                .flatMap(\.components)
                .map(\.status.serviceStatus)
                .max() ?? .undetermined
            let message = openIncidents.map { "* \($0.description)" }.joined(separator: "\n")

            statusDescription = ServiceStatusDescription(status: status, message: message)
        }
    }
}

private enum UpsunComponentStatus: String, Codable {
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

private struct UpsunComponent: Codable {
    let status: UpsunComponentStatus
}

private struct UpsunIncident: Codable {
    let description: String
    let closedAt: String?
    let components: [UpsunComponent]

    enum CodingKeys: String, CodingKey {
        case description
        case closedAt = "closed_at"
        case components
    }
}

private struct IncidentsResponse: Codable {
    let incidents: [UpsunIncident]
}
