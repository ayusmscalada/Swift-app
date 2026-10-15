import Foundation
import GRDB

// Money is stored as TEXT holding a Decimal, and dates as ISO-8601 TEXT, so values
// round-trip exactly. Typed accessors convert at the edge.

public struct SessionRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Hashable {
    public static let databaseTableName = "session"

    public var id: Int64?
    public var name: String
    public var createdAt: String
    public var updatedAt: String
    public var strategyID: String
    public var startBankroll: String
    public var notes: String?
    public var legacyExtra: String?

    enum CodingKeys: String, CodingKey {
        case id, name, notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case strategyID = "strategy_id"
        case startBankroll = "start_bankroll"
        case legacyExtra = "legacy_extra"
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    public var strategy: StrategyID { StrategyID(rawValue: strategyID) ?? .martingale }
    public var bankroll: Decimal { Decimal(string: startBankroll) ?? 0 }
}

public struct ShoeRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Hashable {
    public static let databaseTableName = "shoe"

    public var id: Int64?
    public var sessionID: Int64
    public var seq: Int
    public var startedAt: String

    enum CodingKeys: String, CodingKey {
        case id, seq
        case sessionID = "session_id"
        case startedAt = "started_at"
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

public struct HandRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Hashable {
    public static let databaseTableName = "hand"

    public var id: Int64?
    public var shoeID: Int64
    public var seq: Int
    public var result: String
    public var bankerPair: Bool
    public var playerPair: Bool
    public var enteredAt: String
    /// "Q,4,3|5,5,K" (Player | Banker), or nil when no cards were entered.
    public var cards: String?
    public var betOff: Bool

    enum CodingKeys: String, CodingKey {
        case id, seq, result, cards
        case shoeID = "shoe_id"
        case bankerPair = "banker_pair"
        case playerPair = "player_pair"
        case enteredAt = "entered_at"
        case betOff = "bet_off"
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    public var hand: Hand {
        Hand(
            Outcome(rawValue: result) ?? .tie,
            bankerPair: bankerPair,
            playerPair: playerPair,
            cards: cards.flatMap(HandCards.init(encoded:)),
            betOff: betOff
        )
    }
}

/// What the app suggested for a hand, and what it paid, at the time it was saved.
public struct BetRecord: Codable, FetchableRecord, PersistableRecord, Hashable {
    public static let databaseTableName = "bet"

    public var handID: Int64
    public var strategyID: String
    public var side: String
    public var units: String
    public var stake: String
    public var net: String
    public var balance: String
    public var step: Int?

    enum CodingKeys: String, CodingKey {
        case side, units, stake, net, balance, step
        case handID = "hand_id"
        case strategyID = "strategy_id"
    }
}

struct StrategySettingsRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "strategy_settings"

    var strategyID: String
    var json: String

    enum CodingKeys: String, CodingKey {
        case json
        case strategyID = "strategy_id"
    }
}

struct AppSettingRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "app_setting"

    var key: String
    var value: String
}

/// A session with its shoes and hands, as loaded for display and replay.
public struct LoadedSession: Hashable {
    public var session: SessionRecord
    public var shoes: [LoadedShoe]

    public var histories: [GameHistory] { shoes.map(\.history) }
}

public struct LoadedShoe: Hashable {
    public var shoe: ShoeRecord
    public var hands: [HandRecord]

    public var history: GameHistory { GameHistory(hands: hands.map(\.hand)) }
}

enum Timestamp {
    static func now() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
