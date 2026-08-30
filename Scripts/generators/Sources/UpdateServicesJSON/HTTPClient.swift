import Foundation

enum HTTPClient {
    static func get(_ url: URL, timeout: TimeInterval = 15) async -> Data? {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        return try? await URLSession.shared.data(for: request).0
    }
}
