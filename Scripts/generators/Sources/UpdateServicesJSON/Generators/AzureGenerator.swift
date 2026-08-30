import Foundation

struct AzureGenerator: ServiceGenerator {
    let providerKey = "azure"

    func discover() async -> [DiscoveredEntry] {
        guard
            let data = await HTTPClient.get(URL(string: "https://status.azure.com/en-us/status")!),
            var body = String(data: data, encoding: .utf8)
        else {
            print("warning: could not retrieve list of Azure zones")
            return []
        }

        body = body.replacingOccurrences(of: "\n", with: "")

        // swiftlint:disable:next force_try
        let regex = try! NSRegularExpression(
            pattern: "li role=\"presentation\".*?data-zone-name=\"(.*?)\".*?data-event-property=\"(.*?)\"",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )

        // Some tabs in the Azure status website do not correspond to actual zones, so we exclude them.
        let excludedZoneIdentifiers = Set(["current-impact"])

        var entries: [DiscoveredEntry] = []
        let range = NSRange(location: 0, length: body.count)
        regex.enumerateMatches(in: body, options: [], range: range) { match, _, _ in
            guard let match, match.numberOfRanges == 3 else { return }

            let identifier = body[match.range(at: 1)]
            var name = body[match.range(at: 2)]
            if !name.hasPrefix("Azure") {
                name = "Azure \(name)"
            }

            guard !excludedZoneIdentifiers.contains(identifier) else { return }
            entries.append(DiscoveredEntry(id: identifier, name: name))
        }

        return entries
    }
}
