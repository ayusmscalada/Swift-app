import Foundation

public enum RoadColor: String, Codable, Hashable, Sendable {
    case red = "r"
    case blue = "b"
}

/// The three derived roads. The raw value is how many columns back each one compares.
public enum DerivedRoadKind: Int, CaseIterable, Hashable, Sendable {
    case bigEyeBoy = 1
    case smallRoad = 2
    case cockroachPig = 3

    public var offset: Int { rawValue }

    public var title: String {
        switch self {
        case .bigEyeBoy: return "Big Eye Boy"
        case .smallRoad: return "Small Road"
        case .cockroachPig: return "Cockroach Pig"
        }
    }
}

/// Big Eye Boy, Small Road or Cockroach Pig, derived from the Big Road's logical columns.
public struct DerivedRoad: Hashable, Sendable {
    public let kind: DerivedRoadKind
    /// One mark per qualifying Big Road entry, in order.
    public let marks: [RoadColor]

    public init(kind: DerivedRoadKind, bigRoad: BigRoad) {
        self.kind = kind
        let lengths = bigRoad.columnLengths
        marks = bigRoad.entries.compactMap { entry in
            DerivedRoad.mark(k: kind.offset, columns: lengths, col: entry.column, row: entry.row)
        }
    }

    /// Marks grouped like the Big Road: the same colour goes down, a change starts a new column.
    public var columns: [[RoadColor]] { groupRuns(marks) }

    /// The mark added for the Big Road entry at logical column `c`, row `r` (both 0-based),
    /// or nil before the road's starting point.
    ///
    /// `columns` holds the logical Big Road column lengths. Only columns before `c` are read,
    /// and those are complete by the time column `c` receives entries.
    public static func mark(k: Int, columns: [Int], col c: Int, row r: Int) -> RoadColor? {
        // Start rule: column k+1 row 2, or column k+2 row 1 (1-based), whichever comes first.
        guard c > k || (c == k && r >= 1) else { return nil }
        if r == 0 {
            // New column: compare the two columns before it.
            return columns[c - 1] == columns[c - 1 - k] ? .red : .blue
        }
        let reference = columns[c - k]
        if reference > r { return .red }     // comparison column has a cell at this row
        if reference == r { return .blue }   // it ends exactly one row above
        return .red                          // it ended earlier
    }
}

/// Splits a sequence into runs of equal consecutive values.
func groupRuns<T: Equatable>(_ items: [T]) -> [[T]] {
    var runs: [[T]] = []
    for item in items {
        if let last = runs.indices.last, runs[last][0] == item {
            runs[last].append(item)
        } else {
            runs.append([item])
        }
    }
    return runs
}
