import Foundation

public struct OutcomeStatistics: Hashable, Sendable {
    public var banker = 0
    public var player = 0
    public var tie = 0
    public var bankerPairs = 0
    public var playerPairs = 0
    public var longestBankerStreak = 0
    public var longestPlayerStreak = 0

    public var total: Int { banker + player + tie }

    public func count(_ outcome: Outcome) -> Int {
        switch outcome {
        case .banker: return banker
        case .player: return player
        case .tie: return tie
        }
    }

    /// Share of all hands, 0–100.
    public func percentage(_ outcome: Outcome) -> Double {
        total == 0 ? 0 : Double(count(outcome)) / Double(total) * 100
    }
}

public enum StatsService {
    /// Counts and streaks over one or more shoes. Streaks never run across shoes.
    public static func statistics(for shoes: [GameHistory]) -> OutcomeStatistics {
        var stats = OutcomeStatistics()
        for shoe in shoes {
            for hand in shoe.hands {
                switch hand.outcome {
                case .banker: stats.banker += 1
                case .player: stats.player += 1
                case .tie: stats.tie += 1
                }
                if hand.bankerPair { stats.bankerPairs += 1 }
                if hand.playerPair { stats.playerPairs += 1 }
            }
            for column in BigRoad(history: shoe).columns {
                if column[0].outcome == .banker {
                    stats.longestBankerStreak = max(stats.longestBankerStreak, column.count)
                } else {
                    stats.longestPlayerStreak = max(stats.longestPlayerStreak, column.count)
                }
            }
        }
        return stats
    }
}
