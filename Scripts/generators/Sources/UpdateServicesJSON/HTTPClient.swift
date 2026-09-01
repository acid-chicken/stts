import Foundation

enum HTTPClient {
    // Some sites (confirmed: mulesoft.com) bot-block requests carrying URLSession's default
    // CFNetwork User-Agent with a 403, while serving a real browser's UA fine — set one so this
    // tool reads the same page a person would.
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 "
        + "(KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    private static func makeRequest(_ url: URL, timeout: TimeInterval) -> URLRequest {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    static func get(_ url: URL, timeout: TimeInterval = 15) async -> Data? {
        try? await URLSession.shared.data(for: makeRequest(url, timeout: timeout)).0
    }

    // Like `get`, but also requires a successful (2xx) HTTP status. Some servers return a
    // non-empty body (an error page, an S3 AccessDenied XML blob, a redirected SPA shell) on a
    // 3xx/4xx response, which would otherwise look like valid content to a caller that only
    // checks for non-empty data.
    static func getSuccessful(_ url: URL, timeout: TimeInterval = 15) async -> Data? {
        guard
            let (data, response) = try? await URLSession.shared.data(for: makeRequest(url, timeout: timeout)),
            let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode)
        else { return nil }
        return data
    }

    // A delegate that refuses to follow HTTP redirects, so the caller sees the redirect itself
    // (status code + Location) instead of transparently ending up on whatever page it points to.
    private final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            willPerformHTTPRedirection response: HTTPURLResponse,
            newRequest request: URLRequest,
            completionHandler: @escaping (URLRequest?) -> Void
        ) {
            completionHandler(nil)
        }
    }

    // Checks whether `url` itself (not wherever it might redirect to) is a live, direct 2xx
    // response — used to catch a status page that has moved (redirect) or gone away (404/error)
    // since it was last recorded in services.json.
    static func checkStatus(_ url: URL, timeout: TimeInterval = 15) async -> URLCheckOutcome {
        let session = URLSession(configuration: .ephemeral, delegate: NoRedirectDelegate(), delegateQueue: nil)
        do {
            let (_, response) = try await session.data(for: makeRequest(url, timeout: timeout))
            guard let httpResponse = response as? HTTPURLResponse else {
                return .networkError("non-HTTP response")
            }
            switch httpResponse.statusCode {
            case 200..<300:
                return .ok
            case 300..<400:
                guard
                    let location = httpResponse.value(forHTTPHeaderField: "Location"),
                    let redirectURL = URL(string: location, relativeTo: url)
                else {
                    return .networkError("redirect with a missing/invalid Location header")
                }
                return .redirected(to: redirectURL)
            default:
                return .httpError(httpResponse.statusCode)
            }
        } catch {
            return .networkError(error.localizedDescription)
        }
    }
}

enum URLCheckOutcome {
    case ok
    case redirected(to: URL)
    case httpError(Int)
    case networkError(String)
}
