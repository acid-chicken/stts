//
//  Railway.swift
//  stts
//

import Foundation

final class Railway: IndependentService {
    let url = URL(string: "https://status.railway.com")!

    override func updateStatus() async throws {
        let statusURL = URL(string: "https://status.railway.com/api/status")!
        let response = try await decoded(RailwayStatusResponse.self, from: statusURL)

        if response.activeIncidents.isEmpty {
            statusDescription = ServiceStatusDescription(status: .good, message: "All Systems Operational")
        } else {
            let status = response.activeIncidents
                .flatMap(\.components)
                .map(\.impact.serviceStatus)
                .max() ?? .undetermined
            let message = response.activeIncidents.map { "* \($0.title)" }.joined(separator: "\n")

            statusDescription = ServiceStatusDescription(status: status, message: message)
        }
    }
}

private enum RailwayImpact: String, Codable {
    case operational = "OPERATIONAL"
    case degradedPerformance = "DEGRADED_PERFORMANCE"
    case partialOutage = "PARTIAL_OUTAGE"
    case majorOutage = "MAJOR_OUTAGE"

    var serviceStatus: ServiceStatus {
        switch self {
        case .operational: return .good
        case .degradedPerformance, .partialOutage: return .minor
        case .majorOutage: return .major
        }
    }
}

private struct RailwayComponent: Codable {
    let impact: RailwayImpact
}

private struct RailwayIncident: Codable {
    let title: String
    let components: [RailwayComponent]
}

private struct RailwayStatusResponse: Codable {
    let activeIncidents: [RailwayIncident]
}
