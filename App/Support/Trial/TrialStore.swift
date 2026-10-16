import Foundation
import Security

/// When the trial started (in Google time) and whether it has expired.
struct TrialRecord: Codable, Equatable {
    var firstLaunch: Date
    var expired: Bool
}

/// Keeps the trial record in the Keychain and, as a second copy, in the app's settings.
/// Reading takes the earliest start and any expiry from either copy, so deleting one of them
/// does not restart the trial.
enum TrialStore {
    private static let service = (Bundle.main.bundleIdentifier ?? "BaccaratAssistant") + ".trial"
    private static let account = "trial-record"
    private static let defaultsKey = "trialRecord"

    static func load() -> TrialRecord? {
        let copies = [keychainData(), UserDefaults.standard.data(forKey: defaultsKey)]
            .compactMap { $0 }
            .compactMap { try? JSONDecoder().decode(TrialRecord.self, from: $0) }
        guard let firstLaunch = copies.map(\.firstLaunch).min() else { return nil }
        return TrialRecord(firstLaunch: firstLaunch, expired: copies.contains { $0.expired })
    }

    static func save(_ record: TrialRecord) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    private static func keychainData() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }
}
