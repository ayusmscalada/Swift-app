import XCTest
@testable import BaccaratDomain

/// Test-only strategy: always one unit on Banker. Counts calls so the replay order can be checked.
private struct AlwaysBanker: BaccaratStrategy {
    static let id = StrategyID.s1
    static let isImplemented = true
    var settings: StrategySettings
    var evaluations = 0

    init(settings: StrategySettings) {
        self.settings = settings
    }

    mutating func evaluate(history: GameHistory, roads: RoadmapSnapshot, ledger: BetLedger) -> BetSuggestion {
        evaluations += 1
        return BetSuggestion(side: .banker, units: 1, reason: "test after \(history.count) hands")
    }

    mutating func reset() {}
}

final class SessionEngineTests: XCTestCase {
    private func run(_ shoes: [GameHistory]) -> SessionResult {
        SessionEngine.run(
            SessionInput(
                shoes: shoes,
                strategyID: .s1,
                settings: StrategySettings(baseUnit: 10),
                startingBankroll: 1000
            ),
            makeStrategy: { AlwaysBanker(settings: $0) }
        )
    }

    func testReplayProducesLedgerAndNextSuggestion() {
        let result = run([GameHistory("BPT")])
        let expectedNets: [Decimal] = [Decimal(string: "9.5")!, -10, 0]
        XCTAssertEqual(result.ledger.entries.map(\.net), expectedNets)
        XCTAssertEqual(result.ledger.balance, Decimal(string: "999.5")!)
        XCTAssertEqual(result.nextSuggestion.side, .banker)
        XCTAssertEqual(result.nextSuggestion.reason, "test after 3 hands")
    }

    func testSuggestionIsMadeBeforeEachHand() {
        let result = run([GameHistory("BP")])
        XCTAssertEqual(result.suggestions[0].map(\.reason), ["test after 0 hands", "test after 1 hands"])
    }

    func testLedgerRunsAcrossShoesAndRoadsShowTheLastShoe() {
        let result = run([GameHistory("BB"), GameHistory("P")])
        XCTAssertEqual(result.ledger.entries.count, 3)
        XCTAssertEqual(result.ledger.entries.last?.shoeIndex, 1)
        XCTAssertEqual(result.ledger.entries.last?.handIndex, 0)
        XCTAssertEqual(RoadEncoding.encode(result.roads.bigRoad), "P")
    }

    func testPendingStrategiesNeverBet() {
        for id in StrategyRegistry.all where !StrategyRegistry.isImplemented(id) {
            let result = SessionEngine.run(SessionInput(
                shoes: [GameHistory("BPBPT")],
                strategyID: id,
                settings: StrategySettings(),
                startingBankroll: 500
            ))
            XCTAssertEqual(result.ledger.summary.betsPlaced, 0, id.title)
            XCTAssertEqual(result.ledger.balance, 500, id.title)
        }
    }

    func testEmptySessionHasNoEntries() {
        let result = run([])
        XCTAssertTrue(result.ledger.entries.isEmpty)
        XCTAssertEqual(result.suggestions, [[]])
    }
}
