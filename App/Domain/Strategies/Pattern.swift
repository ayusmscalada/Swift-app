import Foundation

/// PATTERN (the original's PATTERN.txt), the IHG system ("Izak's Holy Grail").
/// Checked hand by hand against the reference sheet of 500 shoes (Docs/Strategies/Strategies.md).
///
/// Side, from the last two results (ties skipped, history continues across shoes):
/// - repeat (B B) → Streak: bet the same as the last result;
/// - alternate (B P) → Chop: bet the opposite of the last result;
/// - once the last four form X X Y Y → 2-2: follow it (opposite after a pair, same after a
///   change) until one 2-2 bet loses, then back to Streak / Chop.
///
/// Stake: `StakeProgression.runRecovery`. A win between two losses is a single win; two wins in
/// a row reset the count. At `maxSingleWins` single wins, bets become virtual (tracked, not
/// placed) while a run is in progress, until two wins in a row.
public struct PatternStrategy: BaccaratStrategy {
    public static let id = StrategyID.pattern
    public static let isImplemented = true

    static let firstSide = StrategyParameter(
        "firstSide", "Bet On", default: "P",
        help: "B or P: the side for the very first bet of the session.",
        choices: StrategyParameter.sideChoices
    )
    static let maxBet = StrategyParameter(
        "maxBet", "Run ends at bet (units)", default: "45",
        help: "After a bet of this many units or more, win or lose, the run ends and the stake goes back to 1."
    )
    static let maxSingleWins = StrategyParameter(
        "maxSingleWins", "Single wins before pause", default: "7",
        help: "At this many single wins, bets become virtual until two wins in a row."
    )

    public static let parameters = [firstSide, maxBet, maxSingleWins] + StrategyParameter.sessionRules

    private enum Selection: String {
        case first = "First bet"
        case follow = "Follow"
        case streak = "Streak"
        case chop = "Chop"
        case twoTwo = "2-2"
    }

    public var settings: StrategySettings
    private var core: BettingCore

    private var seenHands = 0
    /// The last four Banker / Player results of the session.
    private var recent: [Outcome] = []
    private var followingTwoTwo = false
    /// Side picked for the hand just played (placed or virtual) and whether it came from the 2-2.
    private var lastPick: (side: Outcome, twoTwo: Bool)?
    private var previousResult: BetResult?
    private var resultBeforeThat: BetResult?
    private var singleWins = 0

    public init(settings: StrategySettings) {
        self.settings = settings
        core = BettingCore(.runRecovery(limit: settings.positiveDecimal(Self.maxBet) ?? 45))
    }

    public mutating func evaluate(history: GameHistory, roads: RoadmapSnapshot, ledger: BetLedger) -> BetSuggestion {
        core.update(ledger: ledger, settings: settings)
        // The ledger holds every hand of the session, so patterns carry over to a new shoe.
        for entry in ledger.entries.dropFirst(seenHands) where !entry.outcome.isTie {
            record(entry.outcome)
        }
        seenHands = ledger.entries.count

        let (side, selection) = pick()
        lastPick = (side, selection == .twoTwo)

        let limit = settings.positiveInt(Self.maxSingleWins) ?? 7
        if singleWins >= limit, core.runProfit != 0 {
            return core.wait("Virtual bet on \(side.rawValue) (\(selection.rawValue)): \(singleWins) single wins, waiting for two wins in a row.")
        }
        return core.bet(side, reason: "\(selection.rawValue): bet \(side.rawValue).")
    }

    public mutating func reset() {}

    private func pick() -> (Outcome, Selection) {
        guard let last = recent.last else { return (settings.side(Self.firstSide), .first) }
        guard recent.count >= 2 else { return (last, .follow) }
        let repeated = recent[recent.count - 2] == last
        let opposite = last.opposite ?? last
        if followingTwoTwo {
            return (repeated ? opposite : last, .twoTwo)
        }
        return repeated ? (last, .streak) : (opposite, .chop)
    }

    private mutating func record(_ outcome: Outcome) {
        if let lastPick {
            let result: BetResult = lastPick.side == outcome ? .win : .loss
            if result == .win, previousResult == .win {
                singleWins = 0
            } else if result == .loss, previousResult == .win, resultBeforeThat != .win {
                singleWins += 1
            }
            resultBeforeThat = previousResult
            previousResult = result
            if lastPick.twoTwo, result == .loss {
                followingTwoTwo = false
            }
        }

        recent = Array((recent + [outcome]).suffix(4))
        if !followingTwoTwo, recent.count == 4,
           recent[0] == recent[1], recent[2] == recent[3], recent[1] != recent[2] {
            followingTwoTwo = true
        }
    }
}
