import Foundation

struct FirebaseGenerator: ServiceGenerator {
    let providerKey = "firebase"

    func discover() async -> [DiscoveredEntry] {
        guard
            let data = await HTTPClient.get(URL(string: "https://status.firebase.google.com")!),
            let body = String(data: data, encoding: .utf8)
        else {
            print("warning: could not retrieve list of Firebase services")
            return []
        }

        let normalized = body.replacingOccurrences(of: "\n", with: "")

        // swiftlint:disable:next force_try
        let regex = try! NSRegularExpression(
            pattern: "class=\"product-name\">.*?[\\s\\n]*([^>]*?)[\\s\\n]*<\\/",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )

        var entries: [DiscoveredEntry] = []
        let range = NSRange(location: 0, length: normalized.count)
        regex.enumerateMatches(in: normalized, options: [], range: range) { match, _, _ in
            guard let match, match.numberOfRanges == 2 else { return }

            let dashboardName = normalized[match.range(at: 1)]
            let name = dashboardName.hasPrefix("Firebase") ? dashboardName : "Firebase \(dashboardName)"
            entries.append(DiscoveredEntry(id: dashboardName, name: name))
        }

        return entries
    }
}
