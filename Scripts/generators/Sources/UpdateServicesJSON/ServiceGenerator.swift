import Foundation

struct DiscoveredEntry {
    let id: String
    let name: String
    // Provider-specific extra JSON fields (e.g. Salesforce's "product"), written after "id".
    let extraFields: [(String, JSONValue)]

    init(id: String, name: String, extraFields: [(String, JSONValue)] = []) {
        self.id = id
        self.name = name
        self.extraFields = extraFields
    }
}

protocol ServiceGenerator: Sendable {
    var providerKey: String { get }

    // Return [] on fetch/parse failure — never treat "discovered nothing" as "provider has zero
    // services". ServicesJSONUpdater leaves the provider's existing data untouched in that case.
    func discover() async -> [DiscoveredEntry]
}
