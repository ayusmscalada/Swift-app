import Foundation

/// Sequence (the original's Sequence.txt): bets a fixed list of sides and stakes. A loss moves
/// to the next side and stake; a win goes back to the first of both.
public struct SequenceStrategy: BaccaratStrategy {
    public static let id = StrategyID.sequence
    public static let isImplemented = true

    static let sides = StrategyParameter(
        "sides", "Bet On", default: "B,P,P,B,B,P,B,P",
        help: "Sides to bet in order, B or P, separated by commas."
    )
    static let amounts = StrategyParameter(
        "amounts", "Amount (units)", default: "1,2,3",
        help: "Stakes in order, separated by commas. After losing the last one it starts again."
    )

    public static let parameters = [sides, amounts] + StrategyParameter.sessionRules

    public var settings: StrategySettings
    private var core: BettingCore

    public init(settings: StrategySettings) {
        self.settings = settings
        core = BettingCore(.sequence(settings.amounts(Self.amounts)))
    }

    public mutating func evaluate(history: GameHistory, roads: RoadmapSnapshot, ledger: BetLedger) -> BetSuggestion {
        core.update(ledger: ledger, settings: settings)
        let sides = settings.sides(Self.sides)
        let position = core.step % sides.count
        return core.bet(sides[position], reason: "Sequence position \(position + 1) of \(sides.count).")
    }

    public mutating func reset() {}
}
