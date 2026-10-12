import XCTest
@testable import BaccaratDomain

/// Replays every JSON file in Tests/BaccaratDomainTests/Reference and compares it hand by hand.
/// Format: see Reference/README.md. A field set to "..." or left out is not checked.
final class ReferenceSessionTests: XCTestCase {
    struct ReferenceSession: Decodable {
        struct Settings: Decodable {
            let strategy: String
            let baseUnit: String
            let bankroll: String
        }

        struct Suggestion: Decodable {
            let side: String
            let units: String
        }

        struct HandRow: Decodable {
            let result: String
            let suggestion: Suggestion?
            let net: String?
            let balance: String?
        }

        struct Roads: Decodable {
            let bigRoad: String?
            let bigEyeBoy: String?
            let smallRoad: String?
            let cockroachPig: String?
        }

        let name: String
        let source: String?
        let settings: Settings
        let hands: [HandRow]
        let roads: Roads?
    }

    func testReferenceSessions() throws {
        let folder = try XCTUnwrap(Bundle.module.url(forResource: "Reference", withExtension: nil))
        let files = try FileManager.default
            .contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        try XCTSkipIf(files.isEmpty, "No reference sessions recorded yet.")

        for file in files {
            let session = try JSONDecoder().decode(ReferenceSession.self, from: Data(contentsOf: file))
            try check(session, file: file.lastPathComponent)
        }
    }

    private func check(_ reference: ReferenceSession, file: String) throws {
        let history = GameHistory(hands: try reference.hands.map { row in
            Hand(try XCTUnwrap(Outcome(token: row.result), "\(file): bad result \(row.result)"))
        })

        if let roads = reference.roads {
            let snapshot = RoadmapEngine.snapshot(for: history)
            expect(roads.bigRoad, RoadEncoding.encode(snapshot.bigRoad), "\(file) Big Road")
            expect(roads.bigEyeBoy, RoadEncoding.encode(snapshot.bigEyeBoy), "\(file) Big Eye Boy")
            expect(roads.smallRoad, RoadEncoding.encode(snapshot.smallRoad), "\(file) Small Road")
            expect(roads.cockroachPig, RoadEncoding.encode(snapshot.cockroachPig), "\(file) Cockroach Pig")
        }

        guard let strategy = StrategyID(rawValue: reference.settings.strategy),
              StrategyRegistry.isImplemented(strategy),
              reference.hands.contains(where: { $0.suggestion != nil })
        else { return }

        let result = SessionEngine.run(SessionInput(
            shoes: [history],
            strategyID: strategy,
            settings: StrategySettings(baseUnit: try decimal(reference.settings.baseUnit)),
            startingBankroll: try decimal(reference.settings.bankroll)
        ))

        for (index, (row, entry)) in zip(reference.hands, result.ledger.entries).enumerated() {
            let label = "\(file) hand \(index + 1)"
            if let suggestion = row.suggestion {
                XCTAssertEqual(entry.suggestion.side.rawValue, suggestion.side, "\(label) side")
                XCTAssertEqual(entry.suggestion.units, try decimal(suggestion.units), "\(label) units")
            }
            if let net = row.net { XCTAssertEqual(entry.net, try decimal(net), "\(label) net") }
            if let balance = row.balance { XCTAssertEqual(entry.balance, try decimal(balance), "\(label) balance") }
        }
    }

    private func expect(_ expected: String?, _ actual: String, _ label: String) {
        guard let expected, expected != "..." else { return }
        XCTAssertEqual(actual, expected, label)
    }

    private func decimal(_ text: String) throws -> Decimal {
        try XCTUnwrap(Decimal(string: text), "Not a number: \(text)")
    }
}
