import Foundation

/// When the trial started (in Google time) and whether it has expired.
struct TrialRecord: Codable, Equatable {
    var firstLaunch: Date
    var expired: Bool
}

/// Keeps the trial record in the app's settings (UserDefaults).
enum TrialStore {
    private static let defaultsKey = "trialRecord"

    static func load() -> TrialRecord? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(TrialRecord.self, from: data)
    }

    static func save(_ record: TrialRecord) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
