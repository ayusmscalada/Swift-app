import XCTest
@testable import BaccaratDomain

/// Expected marks below were worked out by hand from the rules in the spec
/// ("Roadmap rules"). Big Road for BBPBBBPP is BB | P | BBB | PP.
final class DerivedRoadTests: XCTestCase {
    private let snapshot = RoadmapEngine.snapshot(for: GameHistory("BBPBBBPP"))

    func testBigEyeBoy() {
        XCTAssertEqual(snapshot.bigEyeBoy.marks, [.blue, .blue, .red, .blue, .red])
        XCTAssertEqual(RoadEncoding.encode(snapshot.bigEyeBoy), "bb|r|b|r")
    }

    func testSmallRoad() {
        XCTAssertEqual(snapshot.smallRoad.marks, [.red, .blue, .blue, .blue])
        XCTAssertEqual(RoadEncoding.encode(snapshot.smallRoad), "r|bbb")
    }

    func testCockroachPig() {
        XCTAssertEqual(snapshot.cockroachPig.marks, [.red])
    }

    func testTiesAddNoMarks() {
        let withTies = RoadmapEngine.snapshot(for: GameHistory("TBBTPBBTBPP"))
        XCTAssertEqual(withTies.bigEyeBoy.marks, snapshot.bigEyeBoy.marks)
        XCTAssertEqual(withTies.smallRoad.marks, snapshot.smallRoad.marks)
        XCTAssertEqual(withTies.cockroachPig.marks, snapshot.cockroachPig.marks)
    }

    func testStartRule() {
        // Big Eye Boy (k = 1): nothing before column 2 row 2, or column 3 row 1 (1-based).
        XCTAssertNil(DerivedRoad.mark(k: 1, columns: [2, 1], col: 1, row: 0))
        XCTAssertNotNil(DerivedRoad.mark(k: 1, columns: [2, 2], col: 1, row: 1))
        XCTAssertNotNil(DerivedRoad.mark(k: 1, columns: [2, 1, 1], col: 2, row: 0))
    }

    func testAskPredictions() {
        let history = GameHistory("BBPBBBPP")
        XCTAssertEqual(RoadmapEngine.ask(.player, after: history), [
            .bigEyeBoy: .red, .smallRoad: .red, .cockroachPig: .blue,
        ])
        XCTAssertEqual(RoadmapEngine.ask(.banker, after: history), [
            .bigEyeBoy: .blue, .smallRoad: .blue, .cockroachPig: .red,
        ])
        XCTAssertEqual(RoadmapEngine.ask(.tie, after: history), [:])
    }
}
