import Foundation

public struct Streak: Hashable, Sendable {
    public let side: Outcome
    public let length: Int
}

public enum PatternFlag: String, CaseIterable, Hashable, Sendable {
    case streak = "Streak"
    case chop = "Chop"
}

public struct PatternSummary: Hashable, Sendable {
    /// The run the shoe is currently on (ties ignored), or nil before the first Banker/Player.
    public let currentStreak: Streak?
    /// Number of alternating results at the end of the shoe, e.g. B P B P = 4. Zero during a streak.
    public let chopLength: Int
    public let flags: Set<PatternFlag>
}

/// Detects streaks and chops.
///
/// The thresholds are placeholders until the original app's pattern rules are confirmed
/// during analysis. Named patterns the original detects get added here as they are specified.
public struct PatternAnalyzer: Sendable {
    public var streakThreshold: Int
    public var chopThreshold: Int

    public init(streakThreshold: Int = 4, chopThreshold: Int = 4) {
        self.streakThreshold = streakThreshold
        self.chopThreshold = chopThreshold
    }

    public func analyze(_ history: GameHistory) -> PatternSummary {
        let road = BigRoad(history: history)
        let lengths = road.columnLengths
        guard let lastColumn = road.columns.last else {
            return PatternSummary(currentStreak: nil, chopLength: 0, flags: [])
        }

        let streak = Streak(side: lastColumn[0].outcome, length: lastColumn.count)

        var chop = 0
        if lastColumn.count == 1 {
            let singles = lengths.reversed().prefix { $0 == 1 }.count
            // The alternation also includes the last result of the column before the singles.
            chop = singles + (singles < lengths.count ? 1 : 0)
        }

        var flags: Set<PatternFlag> = []
        if streak.length >= streakThreshold { flags.insert(.streak) }
        if chop >= chopThreshold { flags.insert(.chop) }

        return PatternSummary(currentStreak: streak, chopLength: chop, flags: flags)
    }
}
