import XCTest
import GRDB
@testable import BaccaratData
import BaccaratDomain

final class SessionRepositoryTests: XCTestCase {
    private var database: AppDatabase!
    private var sessions: SessionRepository!

    override func setUpWithError() throws {
        database = try AppDatabase.inMemory()
        sessions = SessionRepository(database)
    }

    private func makeSession(_ sequence: String = "") throws -> (Int64, Int64) {
        let session = try sessions.createSession(name: "Test", strategy: .s9, bankroll: 1000)
        let sessionID = try XCTUnwrap(session.id)
        let shoeID = try XCTUnwrap(try sessions.load(sessionID)?.shoes.first?.shoe.id)
        for outcome in GameHistory(sequence).outcomes {
            try sessions.appendHand(Hand(outcome), toShoe: shoeID)
        }
        return (sessionID, shoeID)
    }

    func testCreateStartsWithOneEmptyShoe() throws {
        let (sessionID, _) = try makeSession()
        let loaded = try XCTUnwrap(try sessions.load(sessionID))
        XCTAssertEqual(loaded.shoes.count, 1)
        XCTAssertTrue(loaded.shoes[0].hands.isEmpty)
        XCTAssertEqual(loaded.session.bankroll, 1000)
        XCTAssertEqual(loaded.session.strategy, .s9)
    }

    func testAppendAndReloadKeepsOrderAndPairs() throws {
        let (sessionID, shoeID) = try makeSession("BPT")
        try sessions.appendHand(Hand(.banker, bankerPair: true), toShoe: shoeID)
        let shoe = try XCTUnwrap(try sessions.load(sessionID)?.shoes.first)
        XCTAssertEqual(shoe.history.outcomes, [.banker, .player, .tie, .banker])
        XCTAssertEqual(shoe.hands.map(\.seq), [1, 2, 3, 4])
        XCTAssertTrue(shoe.hands[3].bankerPair)
    }

    func testRemoveLastHand() throws {
        let (sessionID, shoeID) = try makeSession("BPT")
        try sessions.removeLastHand(ofShoe: shoeID)
        XCTAssertEqual(try sessions.load(sessionID)?.shoes.first?.history.outcomes, [.banker, .player])
    }

    func testDeleteMiddleHandResequences() throws {
        let (sessionID, _) = try makeSession("BPTB")
        let hands = try XCTUnwrap(try sessions.load(sessionID)?.shoes.first?.hands)
        try sessions.deleteHand(try XCTUnwrap(hands[1].id))
        let after = try XCTUnwrap(try sessions.load(sessionID)?.shoes.first)
        XCTAssertEqual(after.history.outcomes, [.banker, .tie, .banker])
        XCTAssertEqual(after.hands.map(\.seq), [1, 2, 3])
    }

    func testUpdateHand() throws {
        let (sessionID, _) = try makeSession("BB")
        let handID = try XCTUnwrap(try sessions.load(sessionID)?.shoes.first?.hands.last?.id)
        try sessions.updateHand(handID, to: Hand(.player, playerPair: true))
        let shoe = try XCTUnwrap(try sessions.load(sessionID)?.shoes.first)
        XCTAssertEqual(shoe.history.outcomes, [.banker, .player])
        XCTAssertTrue(shoe.hands[1].playerPair)
    }

    func testNewShoeAndDeleteShoe() throws {
        let (sessionID, _) = try makeSession("BP")
        let shoe = try sessions.startNewShoe(in: sessionID)
        XCTAssertEqual(shoe.seq, 2)
        XCTAssertEqual(try sessions.load(sessionID)?.shoes.count, 2)
        try sessions.deleteShoe(try XCTUnwrap(shoe.id))
        XCTAssertEqual(try sessions.load(sessionID)?.shoes.count, 1)
    }

    func testDuplicateCopiesShoesAndHands() throws {
        let (sessionID, _) = try makeSession("BPPB")
        let copy = try XCTUnwrap(try sessions.duplicateSession(sessionID, name: "Copy"))
        let loaded = try XCTUnwrap(try sessions.load(try XCTUnwrap(copy.id)))
        XCTAssertEqual(loaded.session.name, "Copy")
        XCTAssertEqual(loaded.shoes.first?.history.outcomes, [.banker, .player, .player, .banker])
    }

    func testDeleteSessionCascades() throws {
        let (sessionID, _) = try makeSession("BP")
        try sessions.deleteSession(sessionID)
        XCTAssertNil(try sessions.load(sessionID))
        let handCount = try database.writer.read { try Int.fetchOne($0, sql: "SELECT COUNT(*) FROM hand") }
        XCTAssertEqual(handCount, 0)
    }

    func testReplaceBetsWritesOneRowPerHand() throws {
        let (sessionID, _) = try makeSession("BPT")
        let loaded = try XCTUnwrap(try sessions.load(sessionID))
        let result = SessionEngine.run(SessionInput(
            shoes: loaded.histories,
            strategyID: .s9,
            settings: StrategySettings(),
            startingBankroll: 1000
        ))
        try sessions.replaceBets(for: loaded, result: result, strategy: .s9)
        try sessions.replaceBets(for: loaded, result: result, strategy: .s9)
        let bets = try sessions.bets(forSession: sessionID)
        XCTAssertEqual(bets.count, 3)
        XCTAssertEqual(bets.map(\.balance), ["1000", "1000", "1000"])
    }

    func testImportSession() throws {
        let session = try sessions.importSession(name: "Imported", outcomes: [.banker, .tie, .player], strategy: .s1, bankroll: 200)
        let loaded = try XCTUnwrap(try sessions.load(try XCTUnwrap(session.id)))
        XCTAssertEqual(loaded.shoes.first?.history.outcomes, [.banker, .tie, .player])
        XCTAssertEqual(loaded.session.strategy, .s1)
    }
}

final class SettingsRepositoryTests: XCTestCase {
    func testStrategySettingsRoundTrip() throws {
        let settings = SettingsRepository(try AppDatabase.inMemory())
        XCTAssertEqual(try settings.strategySettings(for: .s9), StrategySettings())
        let custom = StrategySettings(baseUnit: 25, parameters: ["cycle": "3"])
        try settings.save(custom, for: .s9)
        XCTAssertEqual(try settings.strategySettings(for: .s9), custom)
    }

    func testPayoutRulesRoundTrip() throws {
        let settings = SettingsRepository(try AppDatabase.inMemory())
        XCTAssertEqual(try settings.payoutRules(), .standard)
        var rules = PayoutRules.standard
        rules.bankerWin = 1
        rules.tieRefundsMainBets = false
        try settings.save(rules)
        XCTAssertEqual(try settings.payoutRules(), rules)
    }
}

final class LegacyImporterTests: XCTestCase {
    func testParseResultSequence() {
        XCTAssertEqual(
            LegacyImporter.parseResultSequence("Banker, Player, T\nBBP; x 12"),
            [.banker, .player, .tie, .banker, .banker, .player]
        )
    }

    func testDetectsSQLiteAndListsTables() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("legacy-\(UUID().uuidString).db")
        defer { try? FileManager.default.removeItem(at: url) }
        let queue = try DatabaseQueue(path: url.path)
        try queue.write { db in
            try db.execute(sql: "CREATE TABLE games (id INTEGER PRIMARY KEY, result TEXT)")
            try db.execute(sql: "INSERT INTO games (result) VALUES ('B'), ('P')")
        }
        try queue.close()

        let report = try LegacyImporter.inspect(url)
        XCTAssertEqual(report.format, .sqlite)
        XCTAssertEqual(report.details, ["games (2 rows): id, result"])
    }

    func testDetectsIniAndXml() {
        XCTAssertEqual(LegacyImporter.detectFormat(Data("[General]\nUnit=10\n".utf8)), .ini)
        XCTAssertEqual(LegacyImporter.detectFormat(Data("<?xml version=\"1.0\"?><a/>".utf8)), .xml)
        XCTAssertEqual(LegacyImporter.detectFormat(Data([0x00, 0x01, 0x02])), .binary)
    }
}

final class CSVExporterTests: XCTestCase {
    func testEscaping() {
        XCTAssertEqual(CSVExporter.escape("plain"), "plain")
        XCTAssertEqual(CSVExporter.escape("a,b"), "\"a,b\"")
        XCTAssertEqual(CSVExporter.escape("say \"hi\""), "\"say \"\"hi\"\"\"")
    }
}
