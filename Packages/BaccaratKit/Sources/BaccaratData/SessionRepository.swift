import Foundation
import GRDB
import BaccaratDomain

public struct SessionRepository {
    private let database: AppDatabase

    public init(_ database: AppDatabase) {
        self.database = database
    }

    // MARK: Sessions

    public func allSessions() throws -> [SessionRecord] {
        try database.writer.read { db in
            try SessionRecord.order(Column("updated_at").desc).fetchAll(db)
        }
    }

    /// Creates a session with its first, empty shoe.
    @discardableResult
    public func createSession(name: String, strategy: StrategyID, bankroll: Decimal) throws -> SessionRecord {
        try database.writer.write { db in
            try insertSession(db, name: name, strategy: strategy, bankroll: bankroll)
        }
    }

    /// Creates a session from a plain result sequence, all in one shoe.
    @discardableResult
    public func importSession(
        name: String,
        outcomes: [Outcome],
        strategy: StrategyID,
        bankroll: Decimal
    ) throws -> SessionRecord {
        try database.writer.write { db in
            let session = try insertSession(db, name: name, strategy: strategy, bankroll: bankroll)
            let shoe = try ShoeRecord.filter(Column("session_id") == session.id).fetchOne(db)
            guard let shoeID = shoe?.id else { return session }
            let now = Timestamp.now()
            for (index, outcome) in outcomes.enumerated() {
                var hand = HandRecord(
                    id: nil, shoeID: shoeID, seq: index + 1, result: outcome.rawValue,
                    bankerPair: false, playerPair: false, enteredAt: now
                )
                try hand.insert(db)
            }
            return session
        }
    }

    public func load(_ sessionID: Int64) throws -> LoadedSession? {
        try database.writer.read { db in
            guard let session = try SessionRecord.fetchOne(db, key: sessionID) else { return nil }
            let shoes = try ShoeRecord
                .filter(Column("session_id") == sessionID)
                .order(Column("seq"))
                .fetchAll(db)
            let loaded = try shoes.map { shoe in
                LoadedShoe(
                    shoe: shoe,
                    hands: try HandRecord
                        .filter(Column("shoe_id") == shoe.id)
                        .order(Column("seq"))
                        .fetchAll(db)
                )
            }
            return LoadedSession(session: session, shoes: loaded)
        }
    }

    public func rename(_ sessionID: Int64, to name: String) throws {
        try database.writer.write { db in
            try db.execute(
                sql: "UPDATE session SET name = ?, updated_at = ? WHERE id = ?",
                arguments: [name, Timestamp.now(), sessionID]
            )
        }
    }

    public func setStrategy(_ strategy: StrategyID, for sessionID: Int64) throws {
        try database.writer.write { db in
            try db.execute(
                sql: "UPDATE session SET strategy_id = ?, updated_at = ? WHERE id = ?",
                arguments: [strategy.rawValue, Timestamp.now(), sessionID]
            )
        }
    }

    public func setBankroll(_ bankroll: Decimal, for sessionID: Int64) throws {
        try database.writer.write { db in
            try db.execute(
                sql: "UPDATE session SET start_bankroll = ?, updated_at = ? WHERE id = ?",
                arguments: ["\(bankroll)", Timestamp.now(), sessionID]
            )
        }
    }

    public func deleteSession(_ sessionID: Int64) throws {
        _ = try database.writer.write { db in
            try SessionRecord.deleteOne(db, key: sessionID)
        }
    }

    /// Copies a session's shoes and hands. Bets are not copied; they are rebuilt on load.
    @discardableResult
    public func duplicateSession(_ sessionID: Int64, name: String) throws -> SessionRecord? {
        guard let source = try load(sessionID) else { return nil }
        return try database.writer.write { db in
            let now = Timestamp.now()
            var copy = source.session
            copy.id = nil
            copy.name = name
            copy.createdAt = now
            copy.updatedAt = now
            try copy.insert(db)
            guard let copyID = copy.id else { return copy }

            for loadedShoe in source.shoes {
                var shoe = loadedShoe.shoe
                shoe.id = nil
                shoe.sessionID = copyID
                try shoe.insert(db)
                guard let shoeID = shoe.id else { continue }
                for var hand in loadedShoe.hands {
                    hand.id = nil
                    hand.shoeID = shoeID
                    try hand.insert(db)
                }
            }
            return copy
        }
    }

    // MARK: Shoes and hands

    @discardableResult
    public func startNewShoe(in sessionID: Int64) throws -> ShoeRecord {
        try database.writer.write { db in
            let maxSeq = try Int.fetchOne(
                db, sql: "SELECT MAX(seq) FROM shoe WHERE session_id = ?", arguments: [sessionID]
            ) ?? 0
            var shoe = ShoeRecord(id: nil, sessionID: sessionID, seq: maxSeq + 1, startedAt: Timestamp.now())
            try shoe.insert(db)
            try touch(db, sessionID: sessionID)
            return shoe
        }
    }

    public func deleteShoe(_ shoeID: Int64) throws {
        try database.writer.write { db in
            let sessionID = try Int64.fetchOne(db, sql: "SELECT session_id FROM shoe WHERE id = ?", arguments: [shoeID])
            _ = try ShoeRecord.deleteOne(db, key: shoeID)
            if let sessionID { try touch(db, sessionID: sessionID) }
        }
    }

    @discardableResult
    public func appendHand(_ hand: Hand, toShoe shoeID: Int64) throws -> HandRecord {
        try database.writer.write { db in
            let maxSeq = try Int.fetchOne(
                db, sql: "SELECT MAX(seq) FROM hand WHERE shoe_id = ?", arguments: [shoeID]
            ) ?? 0
            var record = HandRecord(
                id: nil, shoeID: shoeID, seq: maxSeq + 1, result: hand.outcome.rawValue,
                bankerPair: hand.bankerPair, playerPair: hand.playerPair, enteredAt: Timestamp.now()
            )
            try record.insert(db)
            try touch(db, shoeID: shoeID)
            return record
        }
    }

    public func removeLastHand(ofShoe shoeID: Int64) throws {
        try database.writer.write { db in
            try db.execute(
                sql: "DELETE FROM hand WHERE id = (SELECT id FROM hand WHERE shoe_id = ? ORDER BY seq DESC LIMIT 1)",
                arguments: [shoeID]
            )
            try touch(db, shoeID: shoeID)
        }
    }

    public func updateHand(_ handID: Int64, to hand: Hand) throws {
        try database.writer.write { db in
            try db.execute(
                sql: "UPDATE hand SET result = ?, banker_pair = ?, player_pair = ? WHERE id = ?",
                arguments: [hand.outcome.rawValue, hand.bankerPair, hand.playerPair, handID]
            )
            if let shoeID = try Int64.fetchOne(db, sql: "SELECT shoe_id FROM hand WHERE id = ?", arguments: [handID]) {
                try touch(db, shoeID: shoeID)
            }
        }
    }

    /// Deletes a hand and closes the gap in hand numbers.
    public func deleteHand(_ handID: Int64) throws {
        try database.writer.write { db in
            guard let hand = try HandRecord.fetchOne(db, key: handID) else { return }
            _ = try HandRecord.deleteOne(db, key: handID)
            // Two steps so the UNIQUE(shoe_id, seq) constraint never sees a duplicate mid-update.
            try db.execute(
                sql: "UPDATE hand SET seq = -seq WHERE shoe_id = ? AND seq > ?",
                arguments: [hand.shoeID, hand.seq]
            )
            try db.execute(
                sql: "UPDATE hand SET seq = -seq - 1 WHERE shoe_id = ? AND seq < 0",
                arguments: [hand.shoeID]
            )
            try touch(db, shoeID: hand.shoeID)
        }
    }

    // MARK: Bets

    /// Rewrites the saved bet rows of a session from a replay result.
    public func replaceBets(for session: LoadedSession, result: SessionResult, strategy: StrategyID) throws {
        guard let sessionID = session.session.id else { return }
        try database.writer.write { db in
            try db.execute(
                sql: """
                    DELETE FROM bet WHERE hand_id IN (
                        SELECT hand.id FROM hand JOIN shoe ON shoe.id = hand.shoe_id WHERE shoe.session_id = ?
                    )
                    """,
                arguments: [sessionID]
            )
            for entry in result.ledger.entries {
                guard session.shoes.indices.contains(entry.shoeIndex),
                      session.shoes[entry.shoeIndex].hands.indices.contains(entry.handIndex),
                      let handID = session.shoes[entry.shoeIndex].hands[entry.handIndex].id
                else { continue }
                try BetRecord(
                    handID: handID,
                    strategyID: strategy.rawValue,
                    side: entry.suggestion.side.rawValue,
                    units: "\(entry.suggestion.units)",
                    stake: "\(entry.stake)",
                    net: "\(entry.net)",
                    balance: "\(entry.balance)",
                    step: entry.suggestion.step
                ).insert(db)
            }
        }
    }

    public func bets(forSession sessionID: Int64) throws -> [BetRecord] {
        try database.writer.read { db in
            try BetRecord.fetchAll(
                db,
                sql: """
                    SELECT bet.* FROM bet
                    JOIN hand ON hand.id = bet.hand_id
                    JOIN shoe ON shoe.id = hand.shoe_id
                    WHERE shoe.session_id = ?
                    ORDER BY shoe.seq, hand.seq
                    """,
                arguments: [sessionID]
            )
        }
    }

    // MARK: Helpers

    private func insertSession(_ db: Database, name: String, strategy: StrategyID, bankroll: Decimal) throws -> SessionRecord {
        let now = Timestamp.now()
        var session = SessionRecord(
            id: nil, name: name, createdAt: now, updatedAt: now,
            strategyID: strategy.rawValue, startBankroll: "\(bankroll)", notes: nil, legacyExtra: nil
        )
        try session.insert(db)
        if let sessionID = session.id {
            var shoe = ShoeRecord(id: nil, sessionID: sessionID, seq: 1, startedAt: now)
            try shoe.insert(db)
        }
        return session
    }

    private func touch(_ db: Database, sessionID: Int64) throws {
        try db.execute(sql: "UPDATE session SET updated_at = ? WHERE id = ?", arguments: [Timestamp.now(), sessionID])
    }

    private func touch(_ db: Database, shoeID: Int64) throws {
        try db.execute(
            sql: "UPDATE session SET updated_at = ? WHERE id = (SELECT session_id FROM shoe WHERE id = ?)",
            arguments: [Timestamp.now(), shoeID]
        )
    }
}
