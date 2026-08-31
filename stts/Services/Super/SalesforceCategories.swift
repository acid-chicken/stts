//
//  SalesforceCategories.swift
//  stts
//
//  One entry per Salesforce product. The set of products is discovered live by
//  SalesforceGenerator, but adding a genuinely new product line here is a rare, deliberate,
//  one-line-per-class addition — see the "product" dispatch in SalesforceServiceDefinition.build()
//  and Scripts/services_json_migration.md.
//
// "Point_of_Sale" matches Salesforce's own product key verbatim.
// swiftlint:disable type_name

import Foundation

typealias SalesforceB2CCommerceCloud =
    BaseSalesforceB2CCommerceCloud & RequiredServiceProperties & SalesforceStoreService

class BaseSalesforceB2CCommerceCloud: BaseSalesforceCategory {
    static var store = SalesforceStore(key: "B2C_Commerce_Cloud")
    let url = URL(string: "https://status.salesforce.com/products/B2C_Commerce_Cloud")!
}

final class SalesforceB2CCommerceCloudAll: SalesforceB2CCommerceCloud, ServiceCategory {
    let categoryName = "Salesforce B2C Commerce Cloud"
    let subServiceSuperclass: AnyObject.Type = BaseSalesforceB2CCommerceCloud.self

    let name = "Salesforce B2C Commerce Cloud (All Regions)"
    let key = "B2C_Commerce_Cloud"
    let location = "*"
}

final class SalesforceB2CCommerceCloudRegion: SalesforceB2CCommerceCloud, SubService {
    let name: String
    let key = "B2C_Commerce_Cloud"
    let location: String

    init(_ definition: SalesforceServiceDefinition) {
        name = definition.name
        location = definition.id
        super.init()
    }

    required init() {
        fatalError("SalesforceB2CCommerceCloudRegion must be initialized with a definition")
    }
}

typealias SalesforceExperienceCloud =
    BaseSalesforceExperienceCloud & RequiredServiceProperties & SalesforceStoreService

class BaseSalesforceExperienceCloud: BaseSalesforceCategory {
    static var store = SalesforceStore(key: "Community_Cloud")
    let url = URL(string: "https://status.salesforce.com/products/Community_Cloud")!
}

final class SalesforceExperienceCloudAll: SalesforceExperienceCloud, ServiceCategory {
    let categoryName = "Salesforce Experience Cloud"
    let subServiceSuperclass: AnyObject.Type = BaseSalesforceExperienceCloud.self

    let name = "Salesforce Experience Cloud (All Regions)"
    let key = "Community_Cloud"
    let location = "*"
}

final class SalesforceExperienceCloudRegion: SalesforceExperienceCloud, SubService {
    let name: String
    let key = "Community_Cloud"
    let location: String

    init(_ definition: SalesforceServiceDefinition) {
        name = definition.name
        location = definition.id
        super.init()
    }

    required init() {
        fatalError("SalesforceExperienceCloudRegion must be initialized with a definition")
    }
}

typealias Datorama =
    BaseDatorama & RequiredServiceProperties & SalesforceStoreService

class BaseDatorama: BaseSalesforceCategory {
    static var store = SalesforceStore(key: "Datorama")
    let url = URL(string: "https://status.salesforce.com/products/Datorama")!
}

final class DatoramaAll: Datorama, ServiceCategory {
    let categoryName = "Datorama"
    let subServiceSuperclass: AnyObject.Type = BaseDatorama.self

    let name = "Datorama (All Regions)"
    let key = "Datorama"
    let location = "*"
}

final class DatoramaRegion: Datorama, SubService {
    let name: String
    let key = "Datorama"
    let location: String

    init(_ definition: SalesforceServiceDefinition) {
        name = definition.name
        location = definition.id
        super.init()
    }

    required init() {
        fatalError("DatoramaRegion must be initialized with a definition")
    }
}

typealias Heroku =
    BaseHeroku & RequiredServiceProperties & SalesforceStoreService

class BaseHeroku: BaseSalesforceCategory {
    static var store = SalesforceStore(key: "Heroku")
    let url = URL(string: "https://status.salesforce.com/products/Heroku")!
}

final class HerokuAll: Heroku, ServiceCategory {
    let categoryName = "Heroku"
    let subServiceSuperclass: AnyObject.Type = BaseHeroku.self

    let name = "Heroku (All Regions)"
    let key = "Heroku"
    let location = "*"
}

final class HerokuRegion: Heroku, SubService {
    let name: String
    let key = "Heroku"
    let location: String

    init(_ definition: SalesforceServiceDefinition) {
        name = definition.name
        location = definition.id
        super.init()
    }

    required init() {
        fatalError("HerokuRegion must be initialized with a definition")
    }
}

typealias MCAccountEngagement =
    BaseMCAccountEngagement & RequiredServiceProperties & SalesforceStoreService

class BaseMCAccountEngagement: BaseSalesforceCategory {
    static var store = SalesforceStore(key: "MCAccountEngagement")
    let url = URL(string: "https://status.salesforce.com/products/MCAccountEngagement")!
}

final class MCAccountEngagementAll: MCAccountEngagement, ServiceCategory {
    let categoryName = "MCAccountEngagement"
    let subServiceSuperclass: AnyObject.Type = BaseMCAccountEngagement.self

    let name = "MCAccountEngagement (All Regions)"
    let key = "MCAccountEngagement"
    let location = "*"
}

final class MCAccountEngagementRegion: MCAccountEngagement, SubService {
    let name: String
    let key = "MCAccountEngagement"
    let location: String

    init(_ definition: SalesforceServiceDefinition) {
        name = definition.name
        location = definition.id
        super.init()
    }

    required init() {
        fatalError("MCAccountEngagementRegion must be initialized with a definition")
    }
}

typealias MCPersonalization =
    BaseMCPersonalization & RequiredServiceProperties & SalesforceStoreService

class BaseMCPersonalization: BaseSalesforceCategory {
    static var store = SalesforceStore(key: "MCPersonalization")
    let url = URL(string: "https://status.salesforce.com/products/MCPersonalization")!
}

final class MCPersonalizationAll: MCPersonalization, ServiceCategory {
    let categoryName = "MCPersonalization"
    let subServiceSuperclass: AnyObject.Type = BaseMCPersonalization.self

    let name = "MCPersonalization (All Regions)"
    let key = "MCPersonalization"
    let location = "*"
}

final class MCPersonalizationRegion: MCPersonalization, SubService {
    let name: String
    let key = "MCPersonalization"
    let location: String

    init(_ definition: SalesforceServiceDefinition) {
        name = definition.name
        location = definition.id
        super.init()
    }

    required init() {
        fatalError("MCPersonalizationRegion must be initialized with a definition")
    }
}

typealias SalesforceMarketingCloud =
    BaseSalesforceMarketingCloud & RequiredServiceProperties & SalesforceStoreService

class BaseSalesforceMarketingCloud: BaseSalesforceCategory {
    static var store = SalesforceStore(key: "Marketing_Cloud")
    let url = URL(string: "https://status.salesforce.com/products/Marketing_Cloud")!
}

final class SalesforceMarketingCloudAll: SalesforceMarketingCloud, ServiceCategory {
    let categoryName = "Salesforce Marketing Cloud"
    let subServiceSuperclass: AnyObject.Type = BaseSalesforceMarketingCloud.self

    let name = "Salesforce Marketing Cloud (All Regions)"
    let key = "Marketing_Cloud"
    let location = "*"
}

final class SalesforceMarketingCloudRegion: SalesforceMarketingCloud, SubService {
    let name: String
    let key = "Marketing_Cloud"
    let location: String

    init(_ definition: SalesforceServiceDefinition) {
        name = definition.name
        location = definition.id
        super.init()
    }

    required init() {
        fatalError("SalesforceMarketingCloudRegion must be initialized with a definition")
    }
}

typealias Mulesoft =
    BaseMulesoft & RequiredServiceProperties & SalesforceStoreService

class BaseMulesoft: BaseSalesforceCategory {
    static var store = SalesforceStore(key: "Mulesoft")
    let url = URL(string: "https://status.salesforce.com/products/Mulesoft")!
}

final class MulesoftAll: Mulesoft, ServiceCategory {
    let categoryName = "Mulesoft"
    let subServiceSuperclass: AnyObject.Type = BaseMulesoft.self

    let name = "Mulesoft (All Regions)"
    let key = "Mulesoft"
    let location = "*"
}

final class MulesoftRegion: Mulesoft, SubService {
    let name: String
    let key = "Mulesoft"
    let location: String

    init(_ definition: SalesforceServiceDefinition) {
        name = definition.name
        location = definition.id
        super.init()
    }

    required init() {
        fatalError("MulesoftRegion must be initialized with a definition")
    }
}

typealias Point_of_Sale =
    BasePoint_of_Sale & RequiredServiceProperties & SalesforceStoreService

class BasePoint_of_Sale: BaseSalesforceCategory {
    static var store = SalesforceStore(key: "Point_of_Sale")
    let url = URL(string: "https://status.salesforce.com/products/Point_of_Sale")!
}

final class Point_of_SaleAll: Point_of_Sale, ServiceCategory {
    let categoryName = "Point_of_Sale"
    let subServiceSuperclass: AnyObject.Type = BasePoint_of_Sale.self

    let name = "Point_of_Sale (All Regions)"
    let key = "Point_of_Sale"
    let location = "*"
}

final class Point_of_SaleRegion: Point_of_Sale, SubService {
    let name: String
    let key = "Point_of_Sale"
    let location: String

    init(_ definition: SalesforceServiceDefinition) {
        name = definition.name
        location = definition.id
        super.init()
    }

    required init() {
        fatalError("Point_of_SaleRegion must be initialized with a definition")
    }
}

typealias SalesforceServices =
    BaseSalesforceServices & RequiredServiceProperties & SalesforceStoreService

class BaseSalesforceServices: BaseSalesforceCategory {
    static var store = SalesforceStore(key: "Salesforce_Services")
    let url = URL(string: "https://status.salesforce.com/products/Salesforce_Services")!
}

final class SalesforceServicesAll: SalesforceServices, ServiceCategory {
    let categoryName = "Salesforce Services"
    let subServiceSuperclass: AnyObject.Type = BaseSalesforceServices.self

    let name = "Salesforce Services (All Regions)"
    let key = "Salesforce_Services"
    let location = "*"
}

final class SalesforceServicesRegion: SalesforceServices, SubService {
    let name: String
    let key = "Salesforce_Services"
    let location: String

    init(_ definition: SalesforceServiceDefinition) {
        name = definition.name
        location = definition.id
        super.init()
    }

    required init() {
        fatalError("SalesforceServicesRegion must be initialized with a definition")
    }
}

typealias Spiff =
    BaseSpiff & RequiredServiceProperties & SalesforceStoreService

class BaseSpiff: BaseSalesforceCategory {
    static var store = SalesforceStore(key: "Spiff")
    let url = URL(string: "https://status.salesforce.com/products/Spiff")!
}

final class SpiffAll: Spiff, ServiceCategory {
    let categoryName = "Spiff"
    let subServiceSuperclass: AnyObject.Type = BaseSpiff.self

    let name = "Spiff (All Regions)"
    let key = "Spiff"
    let location = "*"
}

final class SpiffRegion: Spiff, SubService {
    let name: String
    let key = "Spiff"
    let location: String

    init(_ definition: SalesforceServiceDefinition) {
        name = definition.name
        location = definition.id
        super.init()
    }

    required init() {
        fatalError("SpiffRegion must be initialized with a definition")
    }
}

typealias Tableau =
    BaseTableau & RequiredServiceProperties & SalesforceStoreService

class BaseTableau: BaseSalesforceCategory {
    static var store = SalesforceStore(key: "Tableau")
    let url = URL(string: "https://status.salesforce.com/products/Tableau")!
}

final class TableauAll: Tableau, ServiceCategory {
    let categoryName = "Tableau"
    let subServiceSuperclass: AnyObject.Type = BaseTableau.self

    let name = "Tableau (All Regions)"
    let key = "Tableau"
    let location = "*"
}

final class TableauRegion: Tableau, SubService {
    let name: String
    let key = "Tableau"
    let location: String

    init(_ definition: SalesforceServiceDefinition) {
        name = definition.name
        location = definition.id
        super.init()
    }

    required init() {
        fatalError("TableauRegion must be initialized with a definition")
    }
}
