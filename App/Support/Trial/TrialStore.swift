import Foundation

/// When the trial started (in Google time) and whether it has expired.
struct TrialRecord: Codable, Equatable {
    var firstLaunch: Date
    var expired: Bool
}

/// Keeps the trial record in a hidden file with an obscure name, not in the Keychain or in
/// the visible settings. The contents are lightly scrambled so the file is not obviously the
/// trial record.
enum TrialStore {
    /// A hidden, inconspicuous name inside Application Support (the app's container when sandboxed).
    private static let fileName = ".com.apple.cache.9f2a7c"
    private static let key: [UInt8] = [0x5A, 0xC3, 0x19, 0x7E, 0x42, 0xB8, 0x6D, 0xF1]

    private static var url: URL? {
        let base = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        return base?.appendingPathComponent(fileName)
    }

    static func load() -> TrialRecord? {
        guard let url, let scrambled = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TrialRecord.self, from: unscramble(scrambled))
    }

    static func save(_ record: TrialRecord) {
        guard let url, let data = try? JSONEncoder().encode(record) else { return }
        try? scramble(data).write(to: url, options: .atomic)
    }

    // XOR with a repeating key: enough to stop the file reading as plain JSON.
    private static func scramble(_ data: Data) -> Data {
        Data(data.enumerated().map { $0.element ^ key[$0.offset % key.count] })
    }

    private static func unscramble(_ data: Data) -> Data { scramble(data) }
}
