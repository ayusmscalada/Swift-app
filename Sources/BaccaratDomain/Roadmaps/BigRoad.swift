import Foundation

/// One Banker or Player cell of the Big Road, at its *logical* position.
/// Logical columns never turn (no dragon tail); `RoadLayout` handles drawing.
public struct BigRoadEntry: Hashable, Sendable {
    public let outcome: Outcome
    /// Index of the hand in the shoe's history.
    public let handIndex: Int
    /// Logical column, 0-based.
    public let column: Int
    /// Logical row, 0-based. May exceed the drawn grid height on long streaks.
    public let row: Int
    /// Ties dealt after this hand and before the next Banker/Player result.
    public internal(set) var tiesAfter: Int
    public let bankerPair: Bool
    public let playerPair: Bool
}

/// Big Road built from standard casino rules (see Docs: "Roadmap rules").
/// Ties do not create cells: they are counted on the previous Banker/Player cell.
/// Ties before the first Banker/Player result are kept in `leadingTies` and shown on the first cell.
public struct BigRoad: Hashable, Sendable {
    public private(set) var columns: [[BigRoadEntry]] = []
    public private(set) var leadingTies = 0

    public init(history: GameHistory) {
        for (index, hand) in history.hands.enumerated() {
            append(hand, at: index)
        }
    }

    private mutating func append(_ hand: Hand, at index: Int) {
        guard hand.outcome != .tie else {
            if let c = columns.indices.last {
                columns[c][columns[c].count - 1].tiesAfter += 1
            } else {
                leadingTies += 1
            }
            return
        }

        if let c = columns.indices.last, columns[c][0].outcome == hand.outcome {
            columns[c].append(entry(for: hand, index: index, column: c, row: columns[c].count))
        } else {
            columns.append([entry(for: hand, index: index, column: columns.count, row: 0)])
        }
    }

    private func entry(for hand: Hand, index: Int, column: Int, row: Int) -> BigRoadEntry {
        BigRoadEntry(
            outcome: hand.outcome,
            handIndex: index,
            column: column,
            row: row,
            tiesAfter: 0,
            bankerPair: hand.bankerPair,
            playerPair: hand.playerPair
        )
    }

    /// Length of every logical column, in order.
    public var columnLengths: [Int] { columns.map(\.count) }

    /// All cells in the order they were added.
    public var entries: [BigRoadEntry] { columns.flatMap { $0 } }
}
