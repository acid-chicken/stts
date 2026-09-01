import Foundation

// Runs after ServicesJSONUpdater writes services.json: requests every "url" actually stored in the
// file (not the computed/commonURL fallbacks some providers use instead — see
// providersWithOptionalURL in Scripts/lint_services_json.swift). A URL that redirects gets
// followed to wherever it actually lands and, once that final destination answers with a plain
// 2xx, services.json is rewritten in place with the new URL — the whole point of catching this is
// that the provider moved its status page, so the fix is mechanical. A URL that 404s/errors/loops
// can't be fixed automatically (there's no destination to switch to), so those are only printed —
// deciding the replacement (or moving the entry to "_removed") is an editorial call, same
// reasoning as the empty-fetch guard in ServicesJSONUpdater.
struct URLHealthChecker {
    private let maxConcurrentRequests = 20
    private let maxRedirectHops = 5

    func run(servicesPath: String) async {
        guard
            let text = try? String(contentsOfFile: servicesPath, encoding: .utf8),
            let root = try? JSONParser.parse(text),
            let pairs = root.objectPairs
        else {
            print("warning: URL health check skipped — could not re-read \(servicesPath)")
            return
        }

        let identifiersByURL = collectURLs(from: pairs)
        guard !identifiersByURL.isEmpty else { return }

        let urlStrings = identifiersByURL.keys.sorted()
        let results = await resolveAll(urlStrings)

        var fixes: [String: String] = [:]
        var unresolved: [(String, String)] = []
        for (urlString, outcome) in results {
            switch outcome {
            case .unchanged:
                break
            case let .resolved(to: newURL):
                fixes[urlString] = newURL.absoluteString
            case let .unresolved(reason):
                unresolved.append((urlString, reason))
            }
        }

        if !fixes.isEmpty {
            write(
                fixes, into: pairs, originalText: text, servicesPath: servicesPath, identifiersByURL: identifiersByURL
            )
        }

        if fixes.isEmpty && unresolved.isEmpty {
            print("URL health check: all \(urlStrings.count) service URLs OK.")
            return
        }

        guard !unresolved.isEmpty else { return }

        print("warning: \(unresolved.count) of \(urlStrings.count) service URL(s) need manual attention:")
        for (urlString, reason) in unresolved.sorted(by: { $0.0 < $1.0 }) {
            let identifiers = identifiersByURL[urlString]?.sorted().joined(separator: ", ") ?? ""
            print("  \(urlString) [\(identifiers)] — \(reason)")
        }
    }

    private func collectURLs(from pairs: [(String, JSONValue)]) -> [String: [String]] {
        var identifiersByURL: [String: [String]] = [:]
        for (provider, value) in pairs {
            guard let entries = value.arrayItems else { continue }
            for entry in entries {
                guard
                    let fields = entry.objectPairs,
                    let urlString = fields.first(where: { $0.0 == "url" })?.1.stringValue,
                    let name = fields.first(where: { $0.0 == "name" })?.1.stringValue
                else { continue }
                identifiersByURL[urlString, default: []].append("\(provider).\(name)")
            }
        }
        return identifiersByURL
    }

    private func write(
        _ fixes: [String: String],
        into pairs: [(String, JSONValue)],
        originalText: String,
        servicesPath: String,
        identifiersByURL: [String: [String]]
    ) {
        let updatedPairs = applyFixes(fixes, to: pairs)
        let output = serialize(.object(updatedPairs)) + "\n"

        guard output != originalText else { return }

        do {
            try output.write(toFile: servicesPath, atomically: true, encoding: .utf8)
            print("Updated \(fixes.count) stale service URL(s) in \(servicesPath):")
            for (old, new) in fixes.sorted(by: { $0.key < $1.key }) {
                let identifiers = identifiersByURL[old]?.sorted().joined(separator: ", ") ?? ""
                print("  \(old) -> \(new) [\(identifiers)]")
            }
        } catch {
            print("error: could not write \(servicesPath): \(error.localizedDescription)")
        }
    }

    private func applyFixes(_ fixes: [String: String], to pairs: [(String, JSONValue)]) -> [(String, JSONValue)] {
        pairs.map { provider, value in
            guard let entries = value.arrayItems else { return (provider, value) }
            return (provider, .array(entries.map { applyFixes(fixes, to: $0) }))
        }
    }

    private func applyFixes(_ fixes: [String: String], to entry: JSONValue) -> JSONValue {
        guard let fields = entry.objectPairs else { return entry }
        let updatedFields = fields.map { key, value -> (String, JSONValue) in
            guard key == "url", let urlString = value.stringValue, let replacement = fixes[urlString] else {
                return (key, value)
            }
            return (key, .string(replacement))
        }
        return .object(updatedFields)
    }

    private func resolveAll(_ urlStrings: [String]) async -> [(String, ResolvedURLOutcome)] {
        var results: [(String, ResolvedURLOutcome)] = []

        var index = 0
        while index < urlStrings.count {
            let batch = urlStrings[index..<min(index + maxConcurrentRequests, urlStrings.count)]
            results.append(contentsOf: await resolveBatch(batch))
            index += maxConcurrentRequests
        }

        return results
    }

    private func resolveBatch(_ batch: ArraySlice<String>) async -> [(String, ResolvedURLOutcome)] {
        await withTaskGroup(of: (String, ResolvedURLOutcome).self) { group in
            for urlString in batch {
                group.addTask { (urlString, await Self.resolve(urlString, maxHops: maxRedirectHops)) }
            }

            var results: [(String, ResolvedURLOutcome)] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }

    // Follows redirects itself (rather than letting URLSession do it silently) up to maxHops, so a
    // stored URL that now redirects gets updated to wherever it actually ends up landing — not
    // just the first hop, which can itself be another redirect.
    private static func resolve(_ urlString: String, maxHops: Int) async -> ResolvedURLOutcome {
        guard let start = URL(string: urlString) else {
            return .unresolved("not a valid URL")
        }

        var current = start
        var seen: Set<URL> = []

        for _ in 0..<maxHops {
            guard seen.insert(current).inserted else {
                return .unresolved("redirect loop")
            }

            // A transient timeout/DNS blip under this checker's own concurrent load looks
            // identical to a genuinely dead host, so retry once before giving up on this hop.
            var outcome = await HTTPClient.checkStatus(current)
            if case .networkError = outcome {
                outcome = await HTTPClient.checkStatus(current)
            }

            switch outcome {
            case .ok:
                return current == start ? .unchanged : .resolved(to: current)
            case let .redirected(to):
                current = normalize(to)
            case let .httpError(code):
                return .unresolved("returned HTTP \(code)")
            case let .networkError(message):
                return .unresolved("request failed (\(message))")
            }
        }

        return .unresolved("too many redirects")
    }

    // A server's Location header occasionally spells out the scheme's default port
    // (e.g. "https://example.com:443/") or an explicit directory index file
    // (e.g. "https://example.com/index.html") — both functionally identical to the plain form, but
    // not worth writing into services.json verbatim when neither appears elsewhere in the file.
    private static func normalize(_ url: URL) -> URL {
        stripTrailingIndexFile(from: stripRedundantDefaultPort(from: url))
    }

    private static func stripRedundantDefaultPort(from url: URL) -> URL {
        guard
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let port = components.port,
            (components.scheme == "https" && port == 443) || (components.scheme == "http" && port == 80)
        else { return url }

        components.port = nil
        return components.url ?? url
    }

    private static func stripTrailingIndexFile(from url: URL) -> URL {
        let indexFilenames: Set<String> = ["index.html", "index.htm"]

        guard
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let lastComponent = components.path.split(separator: "/").last.map(String.init),
            indexFilenames.contains(lastComponent)
        else { return url }

        components.path = String(components.path.dropLast(lastComponent.count))
        return components.url ?? url
    }
}

private enum ResolvedURLOutcome {
    case unchanged
    case resolved(to: URL)
    case unresolved(String)
}
