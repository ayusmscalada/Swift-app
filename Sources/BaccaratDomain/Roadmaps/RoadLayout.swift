import Foundation

public struct GridPosition: Hashable, Sendable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

/// A value placed at a drawn grid position.
public struct PlacedCell<Value> {
    public let position: GridPosition
    public let value: Value
}

extension PlacedCell: Equatable where Value: Equatable {}
extension PlacedCell: Hashable where Value: Hashable {}
extension PlacedCell: Sendable where Value: Sendable {}

/// Turns logical road columns into drawn grid cells.
public enum RoadLayout {
    /// Places each logical column on a grid `rows` high.
    ///
    /// A column runs down from row 0. When it reaches the bottom row, or the cell below is
    /// already taken by an earlier tail, it turns right and stays on that row (the "dragon tail").
    /// Each new column starts one column right of the previous column's start, skipping any
    /// top-row cell that a tail already occupies.
    public static func place<T>(_ columns: [[T]], rows: Int = 6) -> [PlacedCell<T>] {
        var occupied = Set<GridPosition>()
        var placed: [PlacedCell<T>] = []
        var startX = -1

        for column in columns {
            startX += 1
            while occupied.contains(GridPosition(x: startX, y: 0)) { startX += 1 }

            var x = startX
            var y = 0
            var turned = false
            for (index, value) in column.enumerated() {
                if index > 0 {
                    let below = GridPosition(x: x, y: y + 1)
                    if !turned && y + 1 < rows && !occupied.contains(below) {
                        y += 1
                    } else {
                        turned = true
                        x += 1
                    }
                }
                let position = GridPosition(x: x, y: y)
                occupied.insert(position)
                placed.append(PlacedCell(position: position, value: value))
            }
        }
        return placed
    }

    /// Bead Plate: every hand (ties included) fills the grid column by column.
    public static func beadPlate(_ history: GameHistory, rows: Int = 6) -> [PlacedCell<Hand>] {
        history.hands.enumerated().map { index, hand in
            PlacedCell(position: GridPosition(x: index / rows, y: index % rows), value: hand)
        }
    }
}
