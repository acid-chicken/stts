//
//  AWSService.swift
//  stts
//

import Foundation

typealias AWSAllService = BaseAWSAllService & RequiredServiceProperties & RequiredAWSAllServiceProperties
typealias AWSRegionService = BaseAWSRegionService & RequiredServiceProperties & RequiredAWSRegionServiceProperties
typealias AWSNamedService = BaseAWSNamedService & RequiredServiceProperties & RequiredAWSNamedServiceProperties

protocol RequiredAWSAllServiceProperties {}

protocol RequiredAWSNamedServiceProperties {
    var name: String { get }
    var ids: Set<String> { get }
}

protocol RequiredAWSRegionServiceProperties {
    var name: String { get }
    var id: String { get }
}

class BaseAWSAllService: BaseAWSService {}
class BaseAWSRegionService: BaseAWSService {}
class BaseAWSNamedService: BaseAWSService {}

class BaseAWSService: BaseIndependentService {
    private static var store = AWSStore(url: URL(string: "https://health.aws.amazon.com/public/currentevents")!)

    override func updateStatus() async throws {
        if let allService = self as? AWSAllService {
            statusDescription = try await BaseAWSService.store.updatedStatus(for: allService)
        } else if let namedService = self as? AWSNamedService {
            statusDescription = try await BaseAWSService.store.updatedStatus(for: namedService)
        } else if let regionService = self as? AWSRegionService {
            statusDescription = try await BaseAWSService.store.updatedStatus(for: regionService)
        } else {
            fatalError("BaseAWSService should not be used directly.")
        }
    }
}

let commonAWSURL = URL(string: "https://health.aws.amazon.com/health/status")!

class AWSRegionServiceDefinition: CodableServiceDefinition, ServiceDefinition {
    enum ExtraKeys: String, CodingKey {
        case id
        case name
        case oldNames = "old_names"
    }

    let id: String
    let providerIdentifier = "awsregions"

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ExtraKeys.self)
        id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let oldNames = try container.decodeIfPresent(Set<String>.self, forKey: .oldNames)

        super.init(name: name, url: commonAWSURL, isCategory: nil, isSubService: true, oldNames: oldNames)
    }

    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: ExtraKeys.self)
        try container.encode(id, forKey: .id)
    }

    func build() -> BaseService? {
        AWSRegionGeneric(self)
    }
}

final class AWSRegionGeneric: AWSRegionService, SubService {
    let name: String
    let url = commonAWSURL
    let id: String

    init(_ definition: AWSRegionServiceDefinition) {
        name = definition.name
        id = definition.id
        super.init()
    }

    required init() {
        fatalError("AWSRegionGeneric must be initialized with a definition")
    }
}

// Named services span multiple regions, each with a different underlying incident-feed id (e.g.
// "ec2-us-west-2", "ec2-eu-west-1"), so status lookup needs the full `ids` set, not a single id.
// "id" is still written (every entry needs one, see ServicesJSONUpdater) as a stable representative
// for JSON diff-matching/old_names purposes only — it's decoded but otherwise unused here.
class AWSServicesServiceDefinition: CodableServiceDefinition, ServiceDefinition {
    enum ExtraKeys: String, CodingKey {
        case id
        case name
        case ids
        case oldNames = "old_names"
    }

    let ids: Set<String>
    let providerIdentifier = "awsservices"

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ExtraKeys.self)
        ids = Set(try container.decode([String].self, forKey: .ids))
        let name = try container.decode(String.self, forKey: .name)
        let oldNames = try container.decodeIfPresent(Set<String>.self, forKey: .oldNames)

        super.init(name: name, url: commonAWSURL, isCategory: nil, isSubService: true, oldNames: oldNames)
    }

    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: ExtraKeys.self)
        try container.encode(ids.sorted().first ?? "", forKey: .id)
        try container.encode(ids.sorted(), forKey: .ids)
    }

    func build() -> BaseService? {
        AWSServicesGeneric(self)
    }
}

final class AWSServicesGeneric: AWSNamedService, SubService {
    let name: String
    let url = commonAWSURL
    let ids: Set<String>

    init(_ definition: AWSServicesServiceDefinition) {
        name = definition.name
        ids = definition.ids
        super.init()
    }

    required init() {
        fatalError("AWSServicesGeneric must be initialized with a definition")
    }
}
