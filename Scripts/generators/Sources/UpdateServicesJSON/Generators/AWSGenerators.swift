import Foundation

private struct AWSRawService: Codable {
    enum CodingKeys: String, CodingKey {
        case id = "service"
        case name = "service_name"
        case regionName = "region_name"
        case regionID = "region_id"
    }

    let id: String
    let name: String
    let regionName: String?
    let regionID: String?
}

private struct AWSDiscovery {
    let namedServices: [(name: String, ids: [String])]
    let regions: [(id: String, name: String)]

    static func fetch() async -> AWSDiscovery? {
        guard
            let data = await HTTPClient.get(URL(string: "https://d3s31nlw3sm5l8.cloudfront.net/services.json")!),
            let services = try? JSONDecoder().decode([AWSRawService].self, from: data)
        else {
            return nil
        }

        var idsByName: [String: Set<String>] = [:]
        var regionsByID: [String: String] = [:]

        for service in services {
            idsByName[service.name, default: []].insert(service.id)

            if let regionID = service.regionID, let regionName = service.regionName {
                regionsByID[regionID] = regionName
            }
        }

        let namedServices = idsByName.map { name, ids in (name: name, ids: Array(ids)) }
        let regions = regionsByID.map { id, name in (id: id, name: name) }
        return AWSDiscovery(namedServices: namedServices, regions: regions)
    }
}

private func awsPrefixed(_ name: String) -> String {
    if name.hasPrefix("Amazon ") || name.hasPrefix("AWS ") {
        return name
    }
    return "AWS \(name)"
}

struct AWSRegionsGenerator: ServiceGenerator {
    let providerKey = "awsregions"

    func discover() async -> [DiscoveredEntry] {
        guard let discovery = await AWSDiscovery.fetch() else {
            print("warning: could not retrieve list of AWS regions")
            return []
        }

        return discovery.regions.map { region in
            DiscoveredEntry(id: region.id, name: "AWS (\(region.name))")
        }
    }
}

struct AWSServicesGenerator: ServiceGenerator {
    let providerKey = "awsservices"

    func discover() async -> [DiscoveredEntry] {
        guard let discovery = await AWSDiscovery.fetch() else {
            print("warning: could not retrieve list of AWS services")
            return []
        }

        return discovery.namedServices.map { service in
            let sortedIDs = service.ids.sorted()
            return DiscoveredEntry(
                id: sortedIDs.first ?? service.name,
                name: awsPrefixed(service.name),
                extraFields: [("ids", .array(sortedIDs.map { .string($0) }))]
            )
        }
    }
}
