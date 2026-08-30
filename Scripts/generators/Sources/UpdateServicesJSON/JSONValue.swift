import Foundation

// Foundation's JSONSerialization/JSONEncoder don't preserve key/array order across runs
// (Dictionary iteration is randomized per process), which would reshuffle services.json on every
// run. Minimal ordered JSON value covering only what services.json actually contains.
indirect enum JSONValue {
    case string(String)
    case bool(Bool)
    case array([JSONValue])
    case object([(String, JSONValue)])

    var objectPairs: [(String, JSONValue)]? {
        if case .object(let pairs) = self { return pairs }
        return nil
    }

    var arrayItems: [JSONValue]? {
        if case .array(let items) = self { return items }
        return nil
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
}
