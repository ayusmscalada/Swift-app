import Foundation

/// The current time from time.google.com over NTP (UDP port 123).
enum GoogleTime {
    private static let host = "time.google.com"
    private static let port: UInt16 = 123
    /// NTP counts seconds from 1900; Unix time counts from 1970.
    private static let ntpToUnix: TimeInterval = 2_208_988_800

    /// Throws when there is no internet connection or the server does not answer in time.
    static func now() throws -> Date {
        var hints = addrinfo(
            ai_flags: 0, ai_family: AF_UNSPEC, ai_socktype: SOCK_DGRAM, ai_protocol: IPPROTO_UDP,
            ai_addrlen: 0, ai_canonname: nil, ai_addr: nil, ai_next: nil
        )
        var info: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, String(port), &hints, &info) == 0, let first = info else {
            throw URLError(.cannotFindHost)
        }
        defer { freeaddrinfo(info) }

        let fd = socket(first.pointee.ai_family, SOCK_DGRAM, IPPROTO_UDP)
        guard fd >= 0 else { throw URLError(.cannotConnectToHost) }
        defer { close(fd) }

        var timeout = timeval(tv_sec: 5, tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

        guard connect(fd, first.pointee.ai_addr, first.pointee.ai_addrlen) == 0 else {
            throw URLError(.cannotConnectToHost)
        }

        // 48-byte NTP request: leap 0, version 3, mode 3 (client).
        var packet = [UInt8](repeating: 0, count: 48)
        packet[0] = 0x1B
        let sent = packet.withUnsafeBytes { send(fd, $0.baseAddress, 48, 0) }
        guard sent == 48 else { throw URLError(.networkConnectionLost) }

        var response = [UInt8](repeating: 0, count: 48)
        let received = response.withUnsafeMutableBytes { recv(fd, $0.baseAddress, 48, 0) }
        guard received == 48 else { throw URLError(.timedOut) }

        // Transmit timestamp: seconds since 1900 in bytes 40–43, big-endian.
        let seconds = (UInt32(response[40]) << 24) | (UInt32(response[41]) << 16)
            | (UInt32(response[42]) << 8) | UInt32(response[43])
        guard seconds > 0 else { throw URLError(.badServerResponse) }
        return Date(timeIntervalSince1970: TimeInterval(seconds) - ntpToUnix)
    }

    /// Seconds on a clock that only moves forward and that changing the Mac's date does not
    /// affect (it keeps counting while the Mac sleeps). Used to carry time between checks.
    static func monotonicSeconds() -> TimeInterval {
        TimeInterval(clock_gettime_nsec_np(CLOCK_MONOTONIC)) / 1_000_000_000
    }
}
