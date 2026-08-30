import Foundation

func serialize(_ value: JSONValue, indent: Int = 0) -> String {
    let pad = String(repeating: "  ", count: indent)
    let childPad = String(repeating: "  ", count: indent + 1)

    switch value {
    case .string(let s):
        return "\"\(escape(s))\""
    case .bool(let b):
        return b ? "true" : "false"
    case .array(let items):
        if items.isEmpty { return "[]" }
        let body = items.map { childPad + serialize($0, indent: indent + 1) }.joined(separator: ",\n")
        return "[\n\(body)\n\(pad)]"
    case .object(let pairs):
        if pairs.isEmpty { return "{}" }
        let body = pairs
            .map { "\(childPad)\"\($0.0)\": \(serialize($0.1, indent: indent + 1))" }
            .joined(separator: ",\n")
        return "{\n\(body)\n\(pad)}"
    }
}

private func escape(_ s: String) -> String {
    var result = ""
    for c in s {
        switch c {
        case "\"": result.append("\\\"")
        case "\\": result.append("\\\\")
        case "\n": result.append("\\n")
        case "\t": result.append("\\t")
        case "\r": result.append("\\r")
        default: result.append(c)
        }
    }
    return result
}
