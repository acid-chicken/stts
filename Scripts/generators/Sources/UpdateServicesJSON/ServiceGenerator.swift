import Foundation

struct DiscoveredEntry {
    let id: String
    let name: String
}

protocol ServiceGenerator: Sendable {
    var providerKey: String { get }

    // Return [] on fetch/parse failure — never treat "discovered nothing" as "provider has zero
    // services". ServicesJSONUpdater leaves the provider's existing data untouched in that case.
    func discover() async -> [DiscoveredEntry]
}
