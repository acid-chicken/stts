//
//  RemoteServicesUpdater.swift
//  stts
//

import Foundation

/// Fetches services.json from GitHub (via jsDelivr) and caches it at `destinationURL` — see
/// `RemoteServiceDefinitionProvider` for how the cached copy gets loaded back in and prioritized
/// over the bundled one.
final class RemoteServicesUpdater: Loading {
    static let remoteURL = URL(string: "https://cdn.jsdelivr.net/gh/inket/stts@master/Resources/services.json")!

    private let destinationURL: URL

    init(destinationURL: URL) {
        self.destinationURL = destinationURL
    }

    /// Fetches the latest services.json and, only if it's well-formed, overwrites the cached copy.
    /// Returns whether the cache was actually updated. A network failure or a response that doesn't
    /// decode as `ServicesStructure` (e.g. jsDelivr serving an error page) leaves whatever was
    /// already cached untouched — the same "never destroy good data on a bad fetch" principle
    /// `Scripts/update_services_json.swift` follows, applied here on the consuming side.
    @discardableResult
    func update() async -> Bool {
        do {
            let data = try await rawData(from: Self.remoteURL)
            guard !data.isEmpty else { return false }
            _ = try JSONDecoder().decode(ServicesStructure.self, from: data)

            try data.write(to: destinationURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
