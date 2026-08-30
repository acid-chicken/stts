import Foundation

// Regenerates Resources/services.json from each ServiceGenerator's live data. Each provider's
// array is fully REPLACED (sorted by name), not merged — a diff should surface real upstream
// removals rather than hide them. handEditedKeys are the exception, preserved by "id" since a
// generator can't rediscover them.
final class ServicesJSONUpdater {
    private let handEditedKeys: Set<String> = ["url", "old_names"]

    private let servicesPath: String

    init(servicesPath: String) {
        self.servicesPath = servicesPath
    }

    func run(generators: [ServiceGenerator]) async {
        guard let originalText = try? String(contentsOfFile: servicesPath, encoding: .utf8) else {
            print("error: could not read \(servicesPath)")
            exit(1)
        }

        guard let rootValue = try? JSONParser.parse(originalText), var pairs = rootValue.objectPairs else {
            print("error: \(servicesPath) is not a valid JSON object")
            exit(1)
        }

        // Fetch every provider concurrently, then apply results in the original generators order
        // (not completion order) so output stays deterministic regardless of network timing.
        var discoveredByIndex = [[DiscoveredEntry]](repeating: [], count: generators.count)
        await withTaskGroup(of: (Int, [DiscoveredEntry]).self) { group in
            for (index, generator) in generators.enumerated() {
                group.addTask { (index, await generator.discover()) }
            }
            for await (index, entries) in group {
                discoveredByIndex[index] = entries
            }
        }

        for (index, generator) in generators.enumerated() {
            let discovered = discoveredByIndex[index]

            guard !discovered.isEmpty else {
                print("warning: no entries discovered for \"\(generator.providerKey)\", leaving it untouched")
                continue
            }

            let existing = pairs.first(where: { $0.0 == generator.providerKey })?.1.arrayItems ?? []
            let updated = buildArray(discovered: discovered, existing: existing)

            if let index = pairs.firstIndex(where: { $0.0 == generator.providerKey }) {
                pairs[index] = (generator.providerKey, .array(updated))
            } else {
                // Insert new provider keys right before "_removed", to match the existing file's convention.
                let insertionIndex = pairs.firstIndex(where: { $0.0 == "_removed" }) ?? pairs.count
                pairs.insert((generator.providerKey, .array(updated)), at: insertionIndex)
            }

            print("Updated \"\(generator.providerKey)\": \(discovered.count) entries discovered.")
        }

        let output = serialize(.object(pairs)) + "\n"

        guard output != originalText else {
            print("services.json unchanged.")
            return
        }

        do {
            try output.write(toFile: servicesPath, atomically: true, encoding: .utf8)
            print("Wrote \(servicesPath)")
        } catch {
            print("error: could not write \(servicesPath): \(error.localizedDescription)")
            exit(1)
        }
    }

    private func buildArray(discovered: [DiscoveredEntry], existing: [JSONValue]) -> [JSONValue] {
        var preservedFieldsByID: [String: [(String, JSONValue)]] = [:]
        for entry in existing {
            guard
                let pairs = entry.objectPairs,
                let id = pairs.first(where: { $0.0 == "id" })?.1.stringValue
            else { continue }

            let preserved = pairs.filter { handEditedKeys.contains($0.0) }
            if !preserved.isEmpty {
                preservedFieldsByID[id] = preserved
            }
        }

        return discovered
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .map { entry in
                var pairs: [(String, JSONValue)] = [("name", .string(entry.name))]
                // Field order matches the rest of the file: name, url, id, ..., old_names.
                if let url = preservedFieldsByID[entry.id]?.first(where: { $0.0 == "url" }) {
                    pairs.append(url)
                }
                pairs.append(("id", .string(entry.id)))
                if let oldNames = preservedFieldsByID[entry.id]?.first(where: { $0.0 == "old_names" }) {
                    pairs.append(oldNames)
                }
                return .object(pairs)
            }
    }
}
