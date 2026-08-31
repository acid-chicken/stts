import Foundation

struct AppleResponseData: Codable {
    struct Service: Codable {
        let serviceName: String
    }

    let services: [Service]
}

extension String {
    var innerJSONString: String {
        let callbackPrefix = "jsonCallback("
        let callbackSuffix = ");"

        let trimmedString = trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedString.hasPrefix(callbackPrefix) && trimmedString.hasSuffix(callbackSuffix) else { return self }

        return String(trimmedString[
            trimmedString.index(trimmedString.startIndex, offsetBy: callbackPrefix.count) ..<
            trimmedString.index(trimmedString.endIndex, offsetBy: -callbackSuffix.count)
        ])
    }
}

func fetchAppleServiceNames(_ url: URL) async -> [String]? {
    guard
        let data = await HTTPClient.get(url),
        let jsonData = String(data: data, encoding: .utf8)?.innerJSONString.data(using: .utf8),
        let responseData = try? JSONDecoder().decode(AppleResponseData.self, from: jsonData)
    else {
        return nil
    }

    return responseData.services.map { $0.serviceName }
}

func applePrefixed(_ name: String) -> String {
    name.hasPrefix("Apple") ? name : "Apple \(name)"
}

struct AppleGenerator: ServiceGenerator {
    let providerKey = "apple"

    static let url = URL(string: "https://www.apple.com/support/systemstatus/data/system_status_en_US.js")!

    func discover() async -> [DiscoveredEntry] {
        guard let serviceNames = await fetchAppleServiceNames(Self.url) else {
            print("warning: could not retrieve list of Apple services")
            return []
        }

        return serviceNames.map { DiscoveredEntry(id: $0, name: applePrefixed($0)) }
    }
}
