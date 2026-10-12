import Foundation

/// All roads for one shoe at one moment.
public struct RoadmapSnapshot: Hashable, Sendable {
    public let history: GameHistory
    public let bigRoad: BigRoad
    public let bigEyeBoy: DerivedRoad
    public let smallRoad: DerivedRoad
    public let cockroachPig: DerivedRoad

    public func derived(_ kind: DerivedRoadKind) -> DerivedRoad {
        switch kind {
        case .bigEyeBoy: return bigEyeBoy
        case .smallRoad: return smallRoad
        case .cockroachPig: return cockroachPig
        }
    }
}

public enum RoadmapEngine {
    public static func snapshot(for history: GameHistory) -> RoadmapSnapshot {
        let bigRoad = BigRoad(history: history)
        return RoadmapSnapshot(
            history: history,
            bigRoad: bigRoad,
            bigEyeBoy: DerivedRoad(kind: .bigEyeBoy, bigRoad: bigRoad),
            smallRoad: DerivedRoad(kind: .smallRoad, bigRoad: bigRoad),
            cockroachPig: DerivedRoad(kind: .cockroachPig, bigRoad: bigRoad)
        )
    }

    /// "Ask" prediction: the mark each derived road would add if `next` were the next result.
    /// A road missing from the result would add no mark. Ties never add marks.
    public static func ask(_ next: Outcome, after history: GameHistory) -> [DerivedRoadKind: RoadColor] {
        guard next != .tie else { return [:] }
        let before = snapshot(for: history)
        let after = snapshot(for: history.appending(Hand(next)))
        var result: [DerivedRoadKind: RoadColor] = [:]
        for kind in DerivedRoadKind.allCases {
            let newMarks = after.derived(kind).marks
            if newMarks.count > before.derived(kind).marks.count, let mark = newMarks.last {
                result[kind] = mark
            }
        }
        return result
    }
}

/// Compact text form of the roads, used by the reference-session tests.
/// Big Road: "BB|PPP|B" (ties left out). Derived roads: "rr|b|rb".
public enum RoadEncoding {
    public static func encode(_ bigRoad: BigRoad) -> String {
        bigRoad.columns.map { $0.map(\.outcome.rawValue).joined() }.joined(separator: "|")
    }

    public static func encode(_ road: DerivedRoad) -> String {
        road.columns.map { $0.map(\.rawValue).joined() }.joined(separator: "|")
    }
}
