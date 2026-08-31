//
//  Salesforce.swift
//  Salesforce
//

import Foundation

typealias Salesforce = BaseSalesforce & RequiredServiceProperties & SalesforceStoreService & InheritsSalesforceCategory
typealias BaseSalesforceCategory = BaseSalesforce & InheritsSalesforceCategory

protocol InheritsSalesforceCategory {
    static var store: SalesforceStore { get }
}

extension InheritsSalesforceCategory {
    var store: SalesforceStore {
        Self.store
    }
}

class BaseSalesforce: BaseIndependentService {
    override func updateStatus() async throws {
        guard let realSelf = self as? Salesforce else {
            fatalError("BaseSalesforce should not be used directly.")
        }

        statusDescription = try await realSelf.store.updatedStatus(for: realSelf)
    }
}

class SalesforceServiceDefinition: CodableServiceDefinition, ServiceDefinition {
    enum ExtraKeys: String, CodingKey {
        case id
        case name
        case product
        case oldNames = "old_names"
    }

    let id: String
    let product: String
    let providerIdentifier = "salesforce"

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ExtraKeys.self)
        id = try container.decode(String.self, forKey: .id)
        product = try container.decode(String.self, forKey: .product)
        let name = try container.decode(String.self, forKey: .name)
        let oldNames = try container.decodeIfPresent(Set<String>.self, forKey: .oldNames)
        let url = URL(string: "https://status.salesforce.com/products/\(product)")!

        super.init(name: name, url: url, isCategory: nil, isSubService: true, oldNames: oldNames)
    }

    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: ExtraKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(product, forKey: .product)
    }

    // One case per hand-written product in SalesforceCategories.swift. Salesforce adding a new
    // product is rare; add its category classes there and a case here when it happens.
    // swiftlint:disable:next cyclomatic_complexity
    func build() -> BaseService? {
        switch product {
        case "B2C_Commerce_Cloud": return SalesforceB2CCommerceCloudRegion(self)
        case "Community_Cloud": return SalesforceExperienceCloudRegion(self)
        case "Datorama": return DatoramaRegion(self)
        case "Heroku": return HerokuRegion(self)
        case "MCAccountEngagement": return MCAccountEngagementRegion(self)
        case "MCPersonalization": return MCPersonalizationRegion(self)
        case "Marketing_Cloud": return SalesforceMarketingCloudRegion(self)
        case "Mulesoft": return MulesoftRegion(self)
        case "Point_of_Sale": return Point_of_SaleRegion(self)
        case "Salesforce_Services": return SalesforceServicesRegion(self)
        case "Spiff": return SpiffRegion(self)
        case "Tableau": return TableauRegion(self)
        default:
            assertionFailure("Unknown Salesforce product \"\(product)\" — add it to SalesforceCategories.swift")
            return nil
        }
    }
}
