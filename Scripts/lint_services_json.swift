#!/usr/bin/swift

import Foundation

// Keep this in sync with ServicesStructure.CodingKeys (stts/ServiceLoader/ServicesStructure.swift).
let knownProviders: Set<String> = [
    "independent", "cachet", "lamb", "sorry", "statuscake", "statuspage", "instatus",
    "statuscast", "incidentio", "statusiov1", "statuspal", "site24x7", "cstate",
    "statushub", "betteruptime", "betterstack", "sendbird", "miro", "pagerduty",
    "azure", "azuredevops", "firebase", "salesforce", "adobe", "apple", "appledeveloper",
    "googlecloudplatform", "awsregions", "awsservices"
]

// Not a provider: a flat array of identifier strings for services confirmed gone for good (company
// shut down/bankrupt, product discontinued) — NOT services that are just currently unreachable/broken
// for a company that's still operating (those might get a working integration again later, so they
// must not be listed here).
let removedServicesKey = "_removed"

// Providers that don't require "url" per entry — either a fixed commonURL with an optional
// per-entry override (Azure, Azure DevOps, Firebase), or a url computed from other fields and
// never stored at all (Salesforce, from "product"). See each provider's *ServiceDefinition.
let providersWithOptionalURL: Set<String> = [
    "azure", "azuredevops", "firebase", "salesforce", "adobe", "apple", "appledeveloper",
    "googlecloudplatform", "awsregions", "awsservices"
]

// Providers with data-driven categories (see ServiceDefinition.categoryKey): the JSON field that
// carries the shared grouping value between a "category": true row and its "subservice": true
// children. Keep in sync with each provider's *ServiceDefinition.categoryKey in stts/Services/Super/.
let categoryKeyFieldByProvider: [String: String] = [
    "salesforce": "product",
    "adobe": "cloud"
]

func envVariable(forKey key: String) -> String {
    guard let variable = ProcessInfo.processInfo.environment[key] else {
        print("error: Environment variable '\(key)' not set")
        exit(1)
    }

    return variable
}

var errors: [String] = []

func fail(_ message: String) {
    errors.append(message)
}

func lintEntry(provider: String, entry: Any, index: Int, seenIdentifiers: inout Set<String>) {
    guard let entry = entry as? [String: Any] else {
        fail("\(provider)[\(index)] is not an object")
        return
    }

    guard let name = entry["name"] as? String, !name.trimmingCharacters(in: .whitespaces).isEmpty else {
        fail("\(provider)[\(index)] is missing a non-empty \"name\"")
        return
    }

    if let urlValue = entry["url"] {
        guard let urlString = urlValue as? String,
              let url = URL(string: urlString),
              let scheme = url.scheme, scheme == "http" || scheme == "https" else {
            fail("\(provider).\(name) has an invalid \"url\"")
            return
        }
    } else if !providersWithOptionalURL.contains(provider) {
        fail("\(provider).\(name) has a missing or invalid \"url\"")
        return
    }

    let normalizedName = String(name.unicodeScalars.filter(CharacterSet.alphanumerics.contains)).lowercased()
    let identifier = "\(provider).\(normalizedName)"
    if seenIdentifiers.contains(identifier) {
        fail("\(provider).\(name) is a duplicate (same provider + name already defined)")
    }
    seenIdentifiers.insert(identifier)

    if let oldNames = entry["old_names"], !(oldNames is [String]) {
        fail("\(provider).\(name) has \"old_names\" that isn't an array of strings")
    }

    for key in ["category", "subservice"] {
        if let value = entry[key], !(value is Bool) {
            fail("\(provider).\(name) has \"\(key)\" that isn't a boolean")
        }
    }
}

// Foundation's JSONSerialization (used both here and by the app) tolerates trailing commas before
// a closing ] or }, even though they're invalid per the JSON spec. That's harmless for the app, but
// flag it anyway as a warning: it can trip up stricter tools (jq, other language's JSON parsers) and
// is usually just a leftover from editing.
func warnAboutTrailingCommas(in text: String) {
    // swiftlint:disable:next force_try
    let regex = try! NSRegularExpression(pattern: ",\\s*[\\]}]", options: [])
    let range = NSRange(text.startIndex..., in: text)

    regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
        guard let match, let matchRange = Range(match.range, in: text) else { return }

        let line = text[..<matchRange.lowerBound].reduce(1) { $1 == "\n" ? $0 + 1 : $0 }
        print("warning: services.json:\(line): trailing comma before a closing bracket")
    }
}

func lintCategoryKeys(provider: String, entries: [Any]) {
    guard let field = categoryKeyFieldByProvider[provider] else { return }

    var categoryKeys = Set<String>()
    var duplicateCategoryKeys = Set<String>()
    var subServiceKeys = Set<String>()

    for entry in entries {
        guard let entry = entry as? [String: Any], let key = entry[field] as? String else { continue }

        if entry["category"] as? Bool == true {
            if !categoryKeys.insert(key).inserted {
                duplicateCategoryKeys.insert(key)
            }
        } else if entry["subservice"] as? Bool == true {
            subServiceKeys.insert(key)
        }
    }

    for key in duplicateCategoryKeys.sorted() {
        fail("\(provider) has more than one \"category\": true entry with \"\(field)\" == \"\(key)\"")
    }

    for key in subServiceKeys.subtracting(categoryKeys).sorted() {
        fail("\(provider) has a \"subservice\": true entry with \"\(field)\" == \"\(key)\" but no matching \"category\": true entry")
    }
}

func lintRemovedServices(_ value: Any) {
    guard let identifiers = value as? [Any] else {
        fail("\"\(removedServicesKey)\" must be an array")
        return
    }

    for (index, identifier) in identifiers.enumerated() {
        guard let identifier = identifier as? String, !identifier.trimmingCharacters(in: .whitespaces).isEmpty else {
            fail("\(removedServicesKey)[\(index)] must be a non-empty string")
            continue
        }
    }
}

func main() {
    let srcRoot = envVariable(forKey: "SRCROOT")
    let path = "\(srcRoot)/Resources/services.json"

    guard let data = FileManager.default.contents(atPath: path) else {
        print("error: Could not read \(path)")
        exit(1)
    }

    if let text = String(data: data, encoding: .utf8) {
        warnAboutTrailingCommas(in: text)
    }

    let json: Any
    do {
        json = try JSONSerialization.jsonObject(with: data, options: [])
    } catch {
        print("error: services.json is not valid JSON: \(error.localizedDescription)")
        exit(1)
    }

    guard let root = json as? [String: Any] else {
        print("error: services.json's top level must be an object")
        exit(1)
    }

    for (key, value) in root {
        if key == removedServicesKey {
            lintRemovedServices(value)
            continue
        }

        guard knownProviders.contains(key) else {
            fail("Unknown top-level provider key \"\(key)\" (typo? not declared in ServicesStructure.CodingKeys)")
            continue
        }

        guard let entries = value as? [Any] else {
            fail("\"\(key)\" must be an array")
            continue
        }

        var seenIdentifiers = Set<String>()
        for (index, entry) in entries.enumerated() {
            lintEntry(provider: key, entry: entry, index: index, seenIdentifiers: &seenIdentifiers)
        }

        lintCategoryKeys(provider: key, entries: entries)
    }

    if !errors.isEmpty {
        errors.sorted().forEach { print("error: services.json: \($0)") }
        exit(1)
    }

    print("services.json OK.")
}

main()
