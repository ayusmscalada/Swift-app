import XCTest
@testable import BaccaratDomain

final class PayoutRulesTests: XCTestCase {
    private let rules = PayoutRules.standard

    func testBankerWinPaysCommission() {
        XCTAssertEqual(rules.net(side: .banker, stake: 100, outcome: .banker), 95)
    }

    func testPlayerWinPaysEvenMoney() {
        XCTAssertEqual(rules.net(side: .player, stake: 100, outcome: .player), 100)
    }

    func testLosingBetLosesStake() {
        XCTAssertEqual(rules.net(side: .banker, stake: 100, outcome: .player), -100)
        XCTAssertEqual(rules.net(side: .tie, stake: 10, outcome: .banker), -10)
    }

    func testTieRefundsMainBetsByDefault() {
        XCTAssertEqual(rules.net(side: .banker, stake: 100, outcome: .tie), 0)
        var strict = rules
        strict.tieRefundsMainBets = false
        XCTAssertEqual(strict.net(side: .player, stake: 100, outcome: .tie), -100)
    }

    func testTieBetPaysEightToOne() {
        XCTAssertEqual(rules.net(side: .tie, stake: 10, outcome: .tie), 80)
    }

    func testRounding() {
        XCTAssertEqual(rules.net(side: .banker, stake: 15, outcome: .banker), Decimal(string: "14.25")!)
        var whole = rules
        whole.roundingScale = 0
        XCTAssertEqual(whole.net(side: .banker, stake: 15, outcome: .banker), 14)
    }

    func testNoBetIsZero() {
        XCTAssertEqual(rules.net(side: .none, stake: 100, outcome: .banker), 0)
    }
}

final class BetLedgerTests: XCTestCase {
    func testBalancesAndSummary() {
        var ledger = BetLedger(startingBankroll: 1000)
        let bet = BetSuggestion(side: .banker, units: 1)
        for (index, net) in [Decimal(-10), 20, -50, 5].enumerated() {
            ledger.record(shoeIndex: 0, handIndex: index, outcome: .banker, suggestion: bet, stake: 10, net: net)
        }
        ledger.record(shoeIndex: 0, handIndex: 4, outcome: .tie, suggestion: .noBet(), stake: 0, net: 0)

        XCTAssertEqual(ledger.entries.map(\.balance), [990, 1010, 960, 965, 965])
        let summary = ledger.summary
        XCTAssertEqual(summary.betsPlaced, 4)
        XCTAssertEqual(summary.wins, 2)
        XCTAssertEqual(summary.losses, 2)
        XCTAssertEqual(summary.pushes, 0)
        XCTAssertEqual(summary.totalWagered, 40)
        XCTAssertEqual(summary.netResult, -35)
        XCTAssertEqual(summary.peakBalance, 1010)
        XCTAssertEqual(summary.maxDrawdown, 50)
    }
}

final class StatsServiceTests: XCTestCase {
    func testCountsAndStreaksPerShoe() {
        let stats = StatsService.statistics(for: [GameHistory("BBBPT"), GameHistory("PPB")])
        XCTAssertEqual(stats.banker, 4)
        XCTAssertEqual(stats.player, 3)
        XCTAssertEqual(stats.tie, 1)
        XCTAssertEqual(stats.longestBankerStreak, 3)
        XCTAssertEqual(stats.longestPlayerStreak, 2)
        XCTAssertEqual(stats.percentage(.tie), 12.5, accuracy: 0.001)
    }
}

final class PatternAnalyzerTests: XCTestCase {
    func testStreak() {
        let summary = PatternAnalyzer().analyze(GameHistory("BPPPP"))
        XCTAssertEqual(summary.currentStreak, Streak(side: .player, length: 4))
        XCTAssertEqual(summary.chopLength, 0)
        XCTAssertEqual(summary.flags, [.streak])
    }

    func testChopIncludesTheResultBeforeTheSingles() {
        XCTAssertEqual(PatternAnalyzer().analyze(GameHistory("BBBPBP")).chopLength, 4)
        XCTAssertEqual(PatternAnalyzer().analyze(GameHistory("BPBPB")).chopLength, 5)
        XCTAssertEqual(PatternAnalyzer().analyze(GameHistory("BPBPB")).flags, [.chop])
    }

    func testEmptyHistory() {
        let summary = PatternAnalyzer().analyze(GameHistory())
        XCTAssertNil(summary.currentStreak)
        XCTAssertTrue(summary.flags.isEmpty)
    }
}
