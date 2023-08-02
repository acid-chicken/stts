//
//  SignalWire.swift
//  stts
//

import Foundation

class SignalWire: Service {
    let url = URL(string: "https://status.signalwire.com")!

    override func updateStatus(callback: @escaping (BaseService) -> Void) {
        let componentsURL = URL(string: "https://status.signalwire.com/api/components")!

        loadData(with: componentsURL) { [weak self] data, _, error in
            guard let self else { return }
            defer { callback(self) }

            guard let data = data else { return self._fail(error) }
            guard let components = try? JSONDecoder().decode([Component].self, from: data) else {
                return self._fail("Couldn't parse response")
            }

            let affectedComponents = components.filter { $0.status.status != .good }

            let status: ServiceStatus
            let message: String
            if affectedComponents.isEmpty {
                status = .good
                message = "Operational"
            } else {
                status = affectedComponents.map { $0.status.status }.max() ?? .undetermined
                message = affectedComponents.map { "* \($0.name): \($0.status.rawValue)" }.joined(separator: "\n")
            }

            statusDescription = ServiceStatusDescription(status: status, message: message)
        }
    }
}

private struct Component: Codable {
    enum ComponentStatus: String, Codable {
        case operational = "Operational"
        case underMaintenance = "Under Maintenance"
        case degradedPerformance = "Degraded Performance"
        case partialOutage = "Partial Outage"
        case majorOutage = "Major Outage"

        var status: ServiceStatus {
            switch self {
            case .operational:
                return .good
            case .underMaintenance:
                return .maintenance
            case .degradedPerformance, .partialOutage:
                return .minor
            case .majorOutage:
                return .major
            }
        }
    }

    let name: String
    let status: ComponentStatus
}
