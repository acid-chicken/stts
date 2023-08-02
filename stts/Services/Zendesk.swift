//
//  Zendesk.swift
//  stts
//

import Foundation

private struct ZendeskIncidentsResponse: Codable {
    struct Incident: Codable {
        struct Attributes: Codable {
            let outage: Bool
            let resolvedAt: String?
        }

        let id: String
        let type: String
        let attributes: Attributes

        var status: ServiceStatus {
            if attributes.resolvedAt != nil {
                return .good
            } else if attributes.outage {
                return .major
            } else {
                return .minor
            }
        }
    }

    let data: [Incident]

    var globalStatus: ServiceStatus {
        data.map { $0.status }.max() ?? .undetermined
    }
}

class Zendesk: Service {
    let url = URL(string: "https://status.zendesk.com")!

    override func updateStatus(callback: @escaping (BaseService) -> Void) {
        loadData(with: url.appendingPathComponent("api/ssp/incidents.json")) { [weak self] data, _, error in
            guard let strongSelf = self else { return }
            defer { callback(strongSelf) }

            guard let data = data else { return strongSelf._fail(error) }
            guard let response = try? JSONDecoder().decode(ZendeskIncidentsResponse.self, from: data) else {
                return strongSelf._fail("Couldn't parse response")
            }

            let status = response.globalStatus
            let message: String
            switch status {
            case .good:
                message = "No incidents"
            case .major, .minor:
                message = "Active incidents"
            default:
                message = "Unexpected response"
            }

            strongSelf.statusDescription = ServiceStatusDescription(status: status, message: message)
        }
    }
}
