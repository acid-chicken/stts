import Foundation

// Fetches the main Apple service list too, purely to rename any developer service whose display
// name would otherwise collide with a regular Apple one (same as the old generator did) — a
// small redundant fetch, but it keeps this generator self-contained.
struct AppleDeveloperGenerator: ServiceGenerator {
    let providerKey = "appledeveloper"

    static let url = URL(
        string: "https://www.apple.com/support/systemstatus/data/developer/system_status_en_US.js"
    )!

    func discover() async -> [DiscoveredEntry] {
        guard let developerServiceNames = await fetchAppleServiceNames(Self.url) else {
            print("warning: could not retrieve list of Apple Developer services")
            return []
        }

        let appleNames = Set((await fetchAppleServiceNames(AppleGenerator.url) ?? []).map(applePrefixed))

        return developerServiceNames.map { serviceName in
            var name = applePrefixed(serviceName)
            if appleNames.contains(name) {
                name += " (Developer)"
            }
            return DiscoveredEntry(id: serviceName, name: name)
        }
    }
}
