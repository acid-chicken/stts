//
//  Adobe.swift
//  stts
//

import Foundation

typealias AdobeCreativeCloud = BaseAdobeCreativeCloud & RequiredServiceProperties & AdobeStoreService
class BaseAdobeCreativeCloud: BaseAdobe {}

class BaseAdobeDocumentCloud: BaseAdobe {}
typealias AdobeDocumentCloud = BaseAdobeDocumentCloud & RequiredServiceProperties & AdobeStoreService

typealias AdobeExperienceCloud = BaseAdobeExperienceCloud & RequiredServiceProperties & AdobeStoreService
class BaseAdobeExperienceCloud: BaseAdobe {}

typealias AdobeExperiencePlatform = BaseAdobeExperiencePlatform & RequiredServiceProperties & AdobeStoreService
class BaseAdobeExperiencePlatform: BaseAdobe {}

typealias AdobeServices = BaseAdobeServices & RequiredServiceProperties & AdobeStoreService
class BaseAdobeServices: BaseAdobe {}

typealias Adobe = BaseAdobe & RequiredServiceProperties & AdobeStoreService
class BaseAdobe: BaseIndependentService {
    static var store = AdobeStore()

    let url = URL(string: "https://status.adobe.com")!

    override func updateStatus() async throws {
        guard let realSelf = self as? Adobe else {
            fatalError("BaseAdobe should not be used directly.")
        }

        statusDescription = try await BaseAdobe.store.updatedStatus(for: realSelf)
    }
}

class AdobeServiceDefinition: CodableServiceDefinition, ServiceDefinition {
    enum ExtraKeys: String, CodingKey {
        case id
        case name
        case cloud
        case isCategory = "category"
        case oldNames = "old_names"
    }

    let id: String
    let cloud: String
    let providerIdentifier = "adobe"

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ExtraKeys.self)
        id = try container.decode(String.self, forKey: .id)
        cloud = try container.decode(String.self, forKey: .cloud)
        let name = try container.decode(String.self, forKey: .name)
        let isCategory = try container.decodeIfPresent(Bool.self, forKey: .isCategory) ?? false
        let oldNames = try container.decodeIfPresent(Set<String>.self, forKey: .oldNames)

        super.init(
            name: name,
            url: URL(string: "https://status.adobe.com")!,
            isCategory: isCategory ? true : nil,
            isSubService: isCategory ? nil : true,
            oldNames: oldNames
        )
    }

    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: ExtraKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(cloud, forKey: .cloud)
    }

    // One pair of cases per hand-written cloud below. Adobe adding a new cloud is rare; add its
    // category/subservice classes below and a pair of cases here when it happens.
    // swiftlint:disable:next cyclomatic_complexity
    func build() -> BaseService? {
        switch (cloud, isCategory == true) {
        case ("CreativeCloud", true): return AdobeCreativeCloudAll(self)
        case ("CreativeCloud", false): return AdobeCreativeCloudGeneric(self)
        case ("DocumentCloud", true): return AdobeDocumentCloudAll(self)
        case ("DocumentCloud", false): return AdobeDocumentCloudGeneric(self)
        case ("ExperienceCloud", true): return AdobeExperienceCloudAll(self)
        case ("ExperienceCloud", false): return AdobeExperienceCloudGeneric(self)
        case ("ExperiencePlatform", true): return AdobeExperiencePlatformAll(self)
        case ("ExperiencePlatform", false): return AdobeExperiencePlatformGeneric(self)
        case ("Services", true): return AdobeServicesAll(self)
        case ("Services", false): return AdobeServicesGeneric(self)
        default:
            assertionFailure("Unknown Adobe cloud \"\(cloud)\" — add it to Adobe.swift")
            return nil
        }
    }
}

final class AdobeCreativeCloudAll: AdobeCreativeCloud, ServiceCategory {
    let categoryName: String
    let subServiceSuperclass: AnyObject.Type = BaseAdobeCreativeCloud.self

    let name: String
    let id: String

    init(_ definition: AdobeServiceDefinition) {
        categoryName = definition.name
        name = "\(definition.name) (All)"
        id = definition.id
        super.init()
    }

    required init() {
        fatalError("AdobeCreativeCloudAll must be initialized with a definition")
    }
}

final class AdobeCreativeCloudGeneric: AdobeCreativeCloud, SubService {
    let name: String
    let id: String

    init(_ definition: AdobeServiceDefinition) {
        name = definition.name
        id = definition.id
        super.init()
    }

    required init() {
        fatalError("AdobeCreativeCloudGeneric must be initialized with a definition")
    }
}

final class AdobeDocumentCloudAll: AdobeDocumentCloud, ServiceCategory {
    let categoryName: String
    let subServiceSuperclass: AnyObject.Type = BaseAdobeDocumentCloud.self

    let name: String
    let id: String

    init(_ definition: AdobeServiceDefinition) {
        categoryName = definition.name
        name = "\(definition.name) (All)"
        id = definition.id
        super.init()
    }

    required init() {
        fatalError("AdobeDocumentCloudAll must be initialized with a definition")
    }
}

final class AdobeDocumentCloudGeneric: AdobeDocumentCloud, SubService {
    let name: String
    let id: String

    init(_ definition: AdobeServiceDefinition) {
        name = definition.name
        id = definition.id
        super.init()
    }

    required init() {
        fatalError("AdobeDocumentCloudGeneric must be initialized with a definition")
    }
}

final class AdobeExperienceCloudAll: AdobeExperienceCloud, ServiceCategory {
    let categoryName: String
    let subServiceSuperclass: AnyObject.Type = BaseAdobeExperienceCloud.self

    let name: String
    let id: String

    init(_ definition: AdobeServiceDefinition) {
        categoryName = definition.name
        name = "\(definition.name) (All)"
        id = definition.id
        super.init()
    }

    required init() {
        fatalError("AdobeExperienceCloudAll must be initialized with a definition")
    }
}

final class AdobeExperienceCloudGeneric: AdobeExperienceCloud, SubService {
    let name: String
    let id: String

    init(_ definition: AdobeServiceDefinition) {
        name = definition.name
        id = definition.id
        super.init()
    }

    required init() {
        fatalError("AdobeExperienceCloudGeneric must be initialized with a definition")
    }
}

final class AdobeExperiencePlatformAll: AdobeExperiencePlatform, ServiceCategory {
    let categoryName: String
    let subServiceSuperclass: AnyObject.Type = BaseAdobeExperiencePlatform.self

    let name: String
    let id: String

    init(_ definition: AdobeServiceDefinition) {
        categoryName = definition.name
        name = "\(definition.name) (All)"
        id = definition.id
        super.init()
    }

    required init() {
        fatalError("AdobeExperiencePlatformAll must be initialized with a definition")
    }
}

final class AdobeExperiencePlatformGeneric: AdobeExperiencePlatform, SubService {
    let name: String
    let id: String

    init(_ definition: AdobeServiceDefinition) {
        name = definition.name
        id = definition.id
        super.init()
    }

    required init() {
        fatalError("AdobeExperiencePlatformGeneric must be initialized with a definition")
    }
}

final class AdobeServicesAll: AdobeServices, ServiceCategory {
    let categoryName: String
    let subServiceSuperclass: AnyObject.Type = BaseAdobeServices.self

    let name: String
    let id: String

    init(_ definition: AdobeServiceDefinition) {
        categoryName = definition.name
        name = "\(definition.name) (All)"
        id = definition.id
        super.init()
    }

    required init() {
        fatalError("AdobeServicesAll must be initialized with a definition")
    }
}

final class AdobeServicesGeneric: AdobeServices, SubService {
    let name: String
    let id: String

    init(_ definition: AdobeServiceDefinition) {
        name = definition.name
        id = definition.id
        super.init()
    }

    required init() {
        fatalError("AdobeServicesGeneric must be initialized with a definition")
    }
}
