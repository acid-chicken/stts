//
//  MiroService.swift
//  stts
//

import Foundation

class MiroServiceDefinition: IncidentIOServiceDefinition {
    override var providerIdentifier: String { "miro" }

    override func build() -> BaseService? {
        MiroService(self)
    }
}

class MiroService: IncidentIOService {}
