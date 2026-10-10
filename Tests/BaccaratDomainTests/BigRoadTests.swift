import XCTest
@testable import BaccaratDomain

final class BigRoadTests: XCTestCase {
    func testSameResultGoesDownAndChangeStartsNewColumn() {
        let road = BigRoad(history: GameHistory("BBPPPB"))
        XCTAssertEqual(road.columnLengths, [2, 3, 1])
        XCTAssertEqual(RoadEncoding.encode(road), "BB|PPP|B")
    }

    func testTiesAreCountedOnThePreviousCell() {
        let road = BigRoad(history: GameHistory("BBPTTPB"))
        XCTAssertEqual(road.columnLengths, [2, 2, 1])
        XCTAssertEqual(road.columns[1][0].tiesAfter, 2)
        XCTAssertEqual(road.columns[1][1].tiesAfter, 0)
    }

    func testLeadingTiesAreHeldBack() {
        let road = BigRoad(history: GameHistory("TTBP"))
        XCTAssertEqual(road.leadingTies, 2)
        XCTAssertEqual(road.columnLengths, [1, 1])
    }

    func testDragonTailTurnsRightAfterTheBottomRow() {
        let cells = RoadLayout.place(BigRoad(history: GameHistory("BBBBBBBB")).columns, rows: 6)
        let expected = (0..<6).map { GridPosition(x: 0, y: $0) }
            + [GridPosition(x: 1, y: 5), GridPosition(x: 2, y: 5)]
        XCTAssertEqual(cells.map(\.position), expected)
    }

    func testNextColumnStartsRightOfThePreviousStart() {
        let cells = RoadLayout.place(BigRoad(history: GameHistory("BBBBBBBP")).columns)
        XCTAssertEqual(cells.last?.position, GridPosition(x: 1, y: 0))
    }

    func testColumnBlockedByEarlierTailTurnsEarly() {
        // Seven Bankers leave a tail at (1, 5); the Player column below it turns at row 4.
        let cells = RoadLayout.place(BigRoad(history: GameHistory("BBBBBBBPPPPPP")).columns)
        XCTAssertEqual(cells.last?.position, GridPosition(x: 2, y: 4))
    }

    func testBeadPlateFillsColumnByColumnIncludingTies() {
        let cells = RoadLayout.beadPlate(GameHistory("BPTBPTB"))
        XCTAssertEqual(cells.count, 7)
        XCTAssertEqual(cells[5].position, GridPosition(x: 0, y: 5))
        XCTAssertEqual(cells[6].position, GridPosition(x: 1, y: 0))
    }
}
