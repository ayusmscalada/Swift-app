import Foundation

/// The current time according to Google, read from the `Date` header of Google's HTTPS server.
/// HTTPS means the answer cannot be faked on the network, and the Mac's own clock is never used.
enum GoogleTime {
    private static let url = URL(string: "https://www.google.com/generate_204")!

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        return URLSession(configuration: configuration)
    }()

    /// HTTP dates look like "Fri, 16 Oct 2026 09:41:07 GMT".
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter
    }()

    /// Throws when there is no internet connection or Google does not answer.
    static func now() async throws -> Date {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              let header = http.value(forHTTPHeaderField: "Date"),
              let date = formatter.date(from: header)
        else { throw URLError(.badServerResponse) }
        return date
    }

    /// Seconds on a clock that only moves forward and that changing the Mac's date does not
    /// affect (it keeps counting while the Mac sleeps). Used between two Google checks.
    static func monotonicSeconds() -> TimeInterval {
        TimeInterval(clock_gettime_nsec_np(CLOCK_MONOTONIC)) / 1_000_000_000
    }
}
