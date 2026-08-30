//
//  ServiceDefinitionProvider.swift
//  stts
//

import Foundation

protocol ServiceDefinitionProvider {
    func definedServices() throws -> [ServiceDefinition]?

    /// Identifiers (see `ServiceLoader.serviceDefinition(forIdentifier:)`) of services confirmed
    /// gone for good — not just currently broken/unreachable — so a stored preference for them can
    /// be pruned instead of silently never matching anything again. See
    /// `ServicesStructure.removedServices` for the exact bar for "gone for good".
    var removedIdentifiers: Set<String> { get }
}

extension ServiceDefinitionProvider {
    var removedIdentifiers: Set<String> { [] }
}

class JSONBasedServiceDefinitionProvider: ServiceDefinitionProvider {
    private let path: String
    let required: Bool

    private lazy var decodeResult: Result<ServicesStructure, Error> = Result {
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(ServicesStructure.self, from: jsonData)
    }

    var removedIdentifiers: Set<String> {
        Set((try? decodeResult.get())?.removedServices ?? [])
    }

    init(path: String, required: Bool) {
        self.path = path
        self.required = required
    }

    func definedServices() throws -> [ServiceDefinition]? {
        do {
            return try decodeResult.get().allServices
        } catch {
            if required {
                throw error
            } else {
                return []
            }
        }
    }
}

class ClassBasedServiceDefinitionProvider: ServiceDefinitionProvider {
    private let classNames: [String]

    init(classNames: [String]) {
        self.classNames = classNames
    }

    func definedServices() throws -> [ServiceDefinition]? {
        classNames.compactMap {
            IndependentServiceDefinition(fromClassName: $0)
        }
    }
}
