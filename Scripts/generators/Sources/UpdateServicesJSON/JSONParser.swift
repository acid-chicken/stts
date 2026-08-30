import Foundation

enum JSONParseError: Error {
    case unexpectedCharacter(Character, at: Int)
    case unexpectedEnd
}

struct JSONParser {
    private let characters: [Character]
    private var index = 0

    init(_ text: String) {
        characters = Array(text)
    }

    static func parse(_ text: String) throws -> JSONValue {
        var parser = JSONParser(text)
        parser.skipWhitespace()
        let value = try parser.parseValue()
        return value
    }

    private var current: Character? { index < characters.count ? characters[index] : nil }

    private mutating func advance() { index += 1 }

    private mutating func skipWhitespace() {
        while let c = current, c == " " || c == "\n" || c == "\t" || c == "\r" {
            advance()
        }
    }

    private mutating func expect(_ char: Character) throws {
        guard current == char else {
            throw JSONParseError.unexpectedCharacter(current ?? "\0", at: index)
        }
        advance()
    }

    private mutating func parseValue() throws -> JSONValue {
        skipWhitespace()
        guard let c = current else { throw JSONParseError.unexpectedEnd }

        switch c {
        case "{": return try parseObject()
        case "[": return try parseArray()
        case "\"": return .string(try parseString())
        case "t":
            try consumeLiteral("true")
            return .bool(true)
        case "f":
            try consumeLiteral("false")
            return .bool(false)
        default:
            throw JSONParseError.unexpectedCharacter(c, at: index)
        }
    }

    private mutating func consumeLiteral(_ literal: String) throws {
        for expected in literal {
            try expect(expected)
        }
    }

    private mutating func parseObject() throws -> JSONValue {
        try expect("{")
        skipWhitespace()

        var pairs: [(String, JSONValue)] = []

        if current == "}" {
            advance()
            return .object(pairs)
        }

        while true {
            skipWhitespace()
            let key = try parseString()
            skipWhitespace()
            try expect(":")
            let value = try parseValue()
            pairs.append((key, value))

            skipWhitespace()
            if current == "," {
                advance()
                skipWhitespace()
                // Tolerate a trailing comma before the closing brace, matching lint_services_json.swift's leniency.
                if current == "}" { break }
                continue
            }
            break
        }

        skipWhitespace()
        try expect("}")
        return .object(pairs)
    }

    private mutating func parseArray() throws -> JSONValue {
        try expect("[")
        skipWhitespace()

        var items: [JSONValue] = []

        if current == "]" {
            advance()
            return .array(items)
        }

        while true {
            let value = try parseValue()
            items.append(value)

            skipWhitespace()
            if current == "," {
                advance()
                skipWhitespace()
                // Tolerate a trailing comma before the closing bracket.
                if current == "]" { break }
                continue
            }
            break
        }

        skipWhitespace()
        try expect("]")
        return .array(items)
    }

    private mutating func parseString() throws -> String {
        try expect("\"")

        var result = ""
        while let c = current, c != "\"" {
            if c == "\\" {
                advance()
                guard let escaped = current else { throw JSONParseError.unexpectedEnd }
                switch escaped {
                case "\"": result.append("\"")
                case "\\": result.append("\\")
                case "/": result.append("/")
                case "n": result.append("\n")
                case "t": result.append("\t")
                case "r": result.append("\r")
                default: result.append(escaped)
                }
                advance()
            } else {
                result.append(c)
                advance()
            }
        }

        try expect("\"")
        return result
    }
}
