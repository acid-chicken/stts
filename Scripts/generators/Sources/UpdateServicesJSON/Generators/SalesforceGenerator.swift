import Foundation

// Only region-level entries ("NA"/"EMEA"/"APAC") are discovered here — the "(All Regions)"
// category per product is a fixed hand-written class in SalesforceCategories.swift, same as
// every other provider's category. Keep `knownProducts` in sync with the `switch` in
// SalesforceServiceDefinition.build() (stts/Services/Super/Salesforce.swift): an unknown product
// still gets written to services.json (so the diff surfaces it) but the app can't build a
// service for it until a human adds its hand-written category classes there.
private let knownProducts: Set<String> = [
    "B2C_Commerce_Cloud", "Community_Cloud", "Datorama", "Heroku", "MCAccountEngagement",
    "MCPersonalization", "Marketing_Cloud", "Mulesoft", "Point_of_Sale", "Salesforce_Services",
    "Spiff", "Tableau"
]

private let productDisplayNames: [String: String] = [
    "Salesforce_Services": "Salesforce Services",
    "Marketing_Cloud": "Salesforce Marketing Cloud",
    "B2C_Commerce_Cloud": "Salesforce B2C Commerce Cloud",
    "Social_Studio": "Salesforce Social Studio",
    "Community_Cloud": "Salesforce Experience Cloud"
]

private struct SalesforceInstance: Codable {
    enum CodingKeys: String, CodingKey {
        case location
        case products = "Products"
    }

    struct Product: Codable {
        let key: String
    }

    let location: String
    let products: [Product]
}

struct SalesforceGenerator: ServiceGenerator {
    let providerKey = "salesforce"

    func discover() async -> [DiscoveredEntry] {
        guard
            let data = await HTTPClient.get(
                URL(string: "https://api.status.salesforce.com/v1/instances?childProducts=false")!
            ),
            let instances = try? JSONDecoder().decode([SalesforceInstance].self, from: data)
        else {
            print("warning: could not retrieve list of Salesforce products")
            return []
        }

        var regionsByProduct: [String: Set<String>] = [:]
        for instance in instances {
            guard let product = instance.products.first else { continue }
            regionsByProduct[product.key, default: []].insert(instance.location)
        }

        var entries: [DiscoveredEntry] = []
        for (product, regions) in regionsByProduct.sorted(by: { $0.key < $1.key }) {
            if !knownProducts.contains(product) {
                print("warning: unknown Salesforce product \"\(product)\" — add it to SalesforceCategories.swift")
            }

            let displayName = productDisplayNames[product] ?? product
            for region in regions.sorted() {
                entries.append(DiscoveredEntry(
                    id: region,
                    name: "\(displayName) (\(region))",
                    extraFields: [("product", .string(product))]
                ))
            }
        }

        return entries
    }
}
