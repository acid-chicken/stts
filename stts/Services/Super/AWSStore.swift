//
//  AWSStore.swift
//  stts
//

import Foundation

// When all is good, the response from currentevents is empty; luckily I found this incident on web.archive.org:
//    [{
//        "date": "1678726651",
//        "region_name": "Oregon",
//        "status": "0",
//        "service": "internetconnectivity-us-west-2",
//        "service_name": "AWS Internet Connectivity",
//        "summary": "[RESOLVED] Internet Connectivity in the US-WEST-2 Region",
//        "event_log": [{
//            "summary": "[RESOLVED] Internet Connectivity in the US-WEST-2 Region",
//            "message": "Between 8:25 AM and 9:16 AM PDT, we experienced elevated packet loss and latency to a small set of internet destinations in the US-WEST-2 Region. Connectivity within the US-WEST-2 Region was not impacted. The issue has been resolved and the services are operating normally.",
//            "status": 1,
//            "timestamp": 1678726620
//        }],
//        "impacted_services": {
//            "elb-us-west-2": {
//                "service_name": "Amazon Elastic Load Balancing",
//                "current": "0",
//                "max": "1"
//            },
//            "natgateway-us-west-2": {
//                "service_name": "AWS NAT Gateway",
//                "current": "0",
//                "max": "1"
//            },
//            "ec2-us-west-2": {
//                "service_name": "Amazon Elastic Compute Cloud",
//                "current": "0",
//                "max": "1"
//            }
//        },
//        "end_time": "1678727476"
//    }]

struct AWSIncident: Codable {
    enum CodingKeys: String, CodingKey {
        case regionName = "region_name"
        case status
        case serviceID = "service"
        case serviceName = "service_name"
        case summary
        case impactedServices = "impacted_services"
    }

    let regionName: String?
    let status: String
    let serviceID: String
    let serviceName: String?
    let summary: String
    let impactedServices: [String: ImpactedService]

    // The status page shows an incident as "<summary> - <service_name> (<region_name>)", omitting
    // whichever of service_name/region_name isn't present.
    var description: String {
        switch (serviceName, regionName) {
        case let (serviceName?, regionName?):
            return "\(summary) - \(serviceName) (\(regionName))"
        case let (serviceName?, nil):
            return "\(summary) - \(serviceName)"
        case let (nil, regionName?):
            return "\(summary) (\(regionName))"
        case (nil, nil):
            return summary
        }
    }

    func impactedServices(for service: AWSNamedService) -> Set<String> {
        var result = Set<String>()

        if service.ids.contains(serviceID) {
            result.insert(serviceID)
        }

        return result.union(service.ids.intersection(Set<String>(impactedServices.keys)))
    }

    // Every id in this feed (e.g. "ec2-me-central-1", "multipleservices-me-central-1") is a
    // "<service>-<region id>" slug, so a region is affected iff it's the suffix of any of them.
    // `regionName` (e.g. "UAE") is the human-readable name shown on the status page and can't be
    // compared against a region's own display name (e.g. "AWS (UAE)"), so it's not used for matching.
    func affectsRegion(_ region: AWSRegionService) -> Bool {
        let suffix = "-\(region.id)"

        if serviceID.hasSuffix(suffix) {
            return true
        }

        return impactedServices.keys.contains { $0.hasSuffix(suffix) }
    }

    struct ImpactedService: Codable {
        let name: String

        private enum CodingKeys: String, CodingKey {
            case name = "service_name"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        regionName = try container.decodeIfPresent(String.self, forKey: .regionName)
        if let statusString = try? container.decode(String.self, forKey: .status) {
            status = statusString
        } else {
            status = String(try container.decode(Int.self, forKey: .status))
        }
        serviceID = try container.decode(String.self, forKey: .serviceID)
        serviceName = try container.decodeIfPresent(String.self, forKey: .serviceName)
        summary = try container.decode(String.self, forKey: .summary)
        impactedServices = try container.decode([String: ImpactedService].self, forKey: .impactedServices)
    }
}

class AWSStore: ServiceStore<[AWSIncident]> {
    private var url: URL

    init(url: URL) {
        self.url = url
    }

    override func retrieveUpdatedState() async throws -> [AWSIncident] {
        return try await decoded([AWSIncident].self, from: url)
    }

    func updatedStatus(for aws: AWSAllService) async throws -> ServiceStatusDescription {
        let updatedState = try await updatedState()
        let activeIncidents = updatedState.filter { $0.status != "0" }

        return ServiceStatusDescription(
            status: activeIncidents.isEmpty ? .good : .minor,
            message: message(for: activeIncidents)
        )
    }

    func updatedStatus(for region: AWSRegionService) async throws -> ServiceStatusDescription {
        let updatedState = try await updatedState()
        let activeIncidents = updatedState.filter { $0.status != "0" && $0.affectsRegion(region) }

        return ServiceStatusDescription(
            status: activeIncidents.isEmpty ? .good : .minor,
            message: message(for: activeIncidents)
        )
    }

    func updatedStatus(for namedService: AWSNamedService) async throws -> ServiceStatusDescription {
        let updatedState = try await updatedState()
        let activeIncidents = updatedState.filter {
            $0.status != "0" && !$0.impactedServices(for: namedService).isEmpty
        }

        return ServiceStatusDescription(
            status: activeIncidents.isEmpty ? .good : .minor,
            message: message(for: activeIncidents)
        )
    }

    private func message(for activeIncidents: [AWSIncident]) -> String {
        guard !activeIncidents.isEmpty else { return "No recent issues" }

        return activeIncidents.map(\.description).joined(separator: "\n")
    }
}
