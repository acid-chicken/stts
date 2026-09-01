//
//  RemoteServiceDefinitionProvider.swift
//  stts
//

import Foundation

/// Reads services.json fetched from GitHub (via jsDelivr) by `RemoteServicesUpdater` and cached at
/// Application Support/stts/services.json. `required: false` so a fresh install (nothing fetched
/// yet) or an offline first launch just falls through to `AppDefinedServiceDefinitionProvider`'s
/// bundled copy — this provider is only ever a head start on data the bundle already ships.
enum RemoteServiceDefinitionProviderError: Error {
    case applicationSupportDirectoryNotFound
}

class RemoteServiceDefinitionProvider: JSONBasedServiceDefinitionProvider {
    static func cachedServicesJSONURL() throws -> URL {
        guard
            let applicationSupportURL = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first
        else {
            throw RemoteServiceDefinitionProviderError.applicationSupportDirectoryNotFound
        }

        let sttsAppSupportURL = applicationSupportURL.appendingPathComponent("stts")

        try FileManager.default.createDirectory(
            at: sttsAppSupportURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        return sttsAppSupportURL.appendingPathComponent("services.json")
    }

    init() throws {
        super.init(path: try Self.cachedServicesJSONURL().path, required: false)
    }
}
