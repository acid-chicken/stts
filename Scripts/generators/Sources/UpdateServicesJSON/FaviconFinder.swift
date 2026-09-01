import Foundation

// Locates a favicon for a status page without any hardcoded per-provider knowledge: scrapes the
// page's <link rel="icon"|"shortcut icon"|"apple-touch-icon"> tags, falling back to the
// conventional /favicon.ico path (verified, never handed back unconfirmed).
enum FaviconFinder {
    // swiftlint:disable:next force_try
    private static let linkTagRegex = try! NSRegularExpression(
        pattern: "<link\\b[^>]*>",
        options: [.caseInsensitive, .dotMatchesLineSeparators]
    )
    // swiftlint:disable:next force_try
    private static let relRegex = try! NSRegularExpression(
        pattern: "rel\\s*=\\s*[\"']([^\"']*icon[^\"']*)[\"']",
        options: [.caseInsensitive]
    )
    // swiftlint:disable:next force_try
    private static let hrefRegex = try! NSRegularExpression(
        pattern: "href\\s*=\\s*[\"']([^\"']+)[\"']",
        options: [.caseInsensitive]
    )

    // Returns the resolved favicon URL together with its already-fetched bytes, so a caller never
    // needs a second round-trip and every candidate (including one scraped from a <link> tag) is
    // confirmed to actually resolve before being handed back — never an unverified guess.
    // `provider` selects a known API shortcut when one exists (see `findViaStatusHubAPI`) before
    // falling back to generic HTML scraping.
    static func find(for pageURL: URL, provider: String) async -> (url: URL, data: Data)? {
        if provider == "statushub", let found = await findViaStatusHubAPI(for: pageURL) {
            return found
        }

        if let pageData = await HTTPClient.getSuccessful(pageURL),
           let html = String(data: pageData, encoding: .utf8),
           let href = bestLinkTagHref(in: html),
           let resolved = URL(string: href, relativeTo: pageURL)?.absoluteURL,
           let data = await HTTPClient.getSuccessful(resolved), !data.isEmpty {
            return (resolved, data)
        }

        guard let scheme = pageURL.scheme, let host = pageURL.host,
              let fallback = URL(string: "\(scheme)://\(host)/favicon.ico")
        else { return nil }

        if let data = await HTTPClient.getSuccessful(fallback), !data.isEmpty {
            return (fallback, data)
        }

        return nil
    }

    // StatusHub-hosted pages are client-rendered single-page apps: the server response is just a
    // loading shell with no favicon reference anywhere, and the browser only sees one because the
    // app fetches its account config client-side after boot. That same config endpoint is public
    // and returns the favicon URL directly as JSON.
    private static func findViaStatusHubAPI(for pageURL: URL) async -> (url: URL, data: Data)? {
        guard
            let configURL = URL(string: "api/config", relativeTo: pageURL),
            let configData = await HTTPClient.getSuccessful(configURL),
            let json = try? JSONSerialization.jsonObject(with: configData) as? [String: Any],
            let faviconURLString = json["favicon_url"] as? String,
            let faviconURL = URL(string: faviconURLString)
        else { return nil }

        guard let data = await HTTPClient.getSuccessful(faviconURL), !data.isEmpty else { return nil }
        return (faviconURL, data)
    }

    // Prefers a plain "icon"/"shortcut icon" link over "apple-touch-icon", matching whichever
    // appears first within each category. Skips data: URIs — we need a fetchable URL.
    private static func bestLinkTagHref(in html: String) -> String? {
        var appleTouchIconHref: String?

        let range = NSRange(location: 0, length: html.utf16.count)
        for match in linkTagRegex.matches(in: html, options: [], range: range) {
            guard let tagRange = Range(match.range, in: html) else { continue }
            let tag = String(html[tagRange])

            guard let rel = firstCapture(of: relRegex, in: tag)?.lowercased(),
                  let rawHref = firstCapture(of: hrefRegex, in: tag)
            else { continue }

            // Markup routinely HTML-escapes "&" as "&amp;" inside an href's query string (e.g.
            // Next.js's `/_next/image?url=...&amp;w=96`) — undecoded, that "&amp;w=96" becomes a
            // literal "amp;w" query key server-side, which some endpoints reject outright.
            let href = decodeHTMLEntities(rawHref)
            guard !href.hasPrefix("data:") else { continue }

            if rel.contains("apple-touch-icon") {
                if appleTouchIconHref == nil { appleTouchIconHref = href }
            } else {
                return href
            }
        }

        return appleTouchIconHref
    }

    private static func firstCapture(of regex: NSRegularExpression, in text: String) -> String? {
        let range = NSRange(location: 0, length: text.utf16.count)
        guard let match = regex.firstMatch(in: text, options: [], range: range), match.numberOfRanges == 2,
              let captureRange = Range(match.range(at: 1), in: text)
        else { return nil }
        return String(text[captureRange])
    }

    private static let namedHTMLEntities = [
        "&amp;": "&", "&quot;": "\"", "&#39;": "'", "&apos;": "'", "&lt;": "<", "&gt;": ">"
    ]

    private static func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        for (entity, replacement) in namedHTMLEntities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        return result
    }
}
