import Foundation

struct GoogleCloudPlatformGenerator: ServiceGenerator {
    let providerKey = "googlecloudplatform"

    func discover() async -> [DiscoveredEntry] {
        guard
            let data = await HTTPClient.get(URL(string: "https://status.cloud.google.com")!),
            var body = String(data: data, encoding: .utf8)
        else {
            print("warning: could not retrieve list of Google Cloud Platform services")
            return []
        }

        body = body.replacingOccurrences(of: "\n", with: "")

        // swiftlint:disable:next force_try
        let regex = try! NSRegularExpression(
            pattern: "__product\" scope=\"row\">[\\s\\n]*(.+?)[\\s\\n]*<.*?\\/th>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )

        var entries: [DiscoveredEntry] = []
        let range = NSRange(location: 0, length: body.count)
        regex.enumerateMatches(in: body, options: [], range: range) { match, _, _ in
            guard let match, match.numberOfRanges == 2 else { return }

            let dashboardName = body[match.range(at: 1)]
            let name = dashboardName.hasPrefix("Google") ? dashboardName : "Google \(dashboardName)"
            entries.append(DiscoveredEntry(id: dashboardName, name: name))
        }

        return entries
    }
}
