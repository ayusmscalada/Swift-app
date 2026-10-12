import Foundation
import GRDB

public struct SettingsRepository {
    private let database: AppDatabase

    public init(_ database: AppDatabase) {
        self.database = database
    }

    // MARK: Strategy settings

    public func strategySettings(for id: StrategyID) throws -> StrategySettings {
        let record = try database.writer.read { db in
            try StrategySettingsRecord.fetchOne(db, key: id.rawValue)
        }
        guard let record else { return StrategySettings() }
        return try JSONDecoder().decode(StrategySettings.self, from: Data(record.json.utf8))
    }

    public func save(_ settings: StrategySettings, for id: StrategyID) throws {
        let json = String(decoding: try JSONEncoder().encode(settings), as: UTF8.self)
        try database.writer.write { db in
            try StrategySettingsRecord(strategyID: id.rawValue, json: json).save(db)
        }
    }

    // MARK: App settings

    public func payoutRules() throws -> PayoutRules {
        try decoded(PayoutRules.self, forKey: Keys.payoutRules) ?? .standard
    }

    public func save(_ rules: PayoutRules) throws {
        try setEncoded(rules, forKey: Keys.payoutRules)
    }

    public func bigRoadRows() throws -> Int {
        try value(forKey: Keys.bigRoadRows).flatMap(Int.init) ?? 6
    }

    public func setBigRoadRows(_ rows: Int) throws {
        try setValue(String(rows), forKey: Keys.bigRoadRows)
    }

    public func value(forKey key: String) throws -> String? {
        try database.writer.read { db in
            try AppSettingRecord.fetchOne(db, key: key)?.value
        }
    }

    public func setValue(_ value: String, forKey key: String) throws {
        try database.writer.write { db in
            try AppSettingRecord(key: key, value: value).save(db)
        }
    }

    private func decoded<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let json = try value(forKey: key) else { return nil }
        return try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    private func setEncoded<T: Encodable>(_ value: T, forKey key: String) throws {
        try setValue(String(decoding: try JSONEncoder().encode(value), as: UTF8.self), forKey: key)
    }

    private enum Keys {
        static let payoutRules = "payout_rules"
        static let bigRoadRows = "big_road_rows"
    }
}
