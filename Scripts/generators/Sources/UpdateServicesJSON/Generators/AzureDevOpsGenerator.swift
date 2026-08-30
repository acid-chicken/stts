import Foundation

private struct AzureDevOpsDataProviders: Codable {
    struct ResponseData: Codable {
        struct MetadataProvider: Codable {
            let services: [[String: String]]

            var serviceNames: [String] { services.compactMap { $0["id"] } }
        }

        enum CodingKeys: String, CodingKey {
            case metadataProvider = "ms.vss-status-web.public-status-metadata-data-provider"
        }

        let metadataProvider: MetadataProvider
    }

    let data: ResponseData
}

struct AzureDevOpsGenerator: ServiceGenerator {
    let providerKey = "azuredevops"

    func discover() async -> [DiscoveredEntry] {
        guard
            let data = await HTTPClient.get(URL(string: "https://status.dev.azure.com")!),
            let body = String(data: data, encoding: .utf8) as NSString?
        else {
            print("warning: could not retrieve list of Azure DevOps services")
            return []
        }

        // swiftlint:disable:next force_try
        let regex = try! NSRegularExpression(
            pattern: "<script id=\"dataProviders\".*?>(.*?)</script>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )

        var entries: [DiscoveredEntry] = []
        let range = NSRange(location: 0, length: body.length)
        regex.enumerateMatches(in: body as String, options: [], range: range) { match, _, _ in
            guard let match, match.numberOfRanges == 2 else { return }

            let json = body.substring(with: match.range(at: 1))
            guard
                let jsonData = json.data(using: .utf8),
                let providers = try? JSONDecoder().decode(AzureDevOpsDataProviders.self, from: jsonData)
            else {
                print("warning: could not decode Azure DevOps services")
                return
            }

            for serviceName in providers.data.metadataProvider.serviceNames {
                let friendlyName = "Azure DevOps " + serviceName
                    .components(separatedBy: " ")
                    .map { $0.isEmpty ? $0 : $0.prefix(1).uppercased() + $0.dropFirst() }
                    .joined(separator: " ")
                entries.append(DiscoveredEntry(id: serviceName, name: friendlyName))
            }
        }

        return entries
    }
}
