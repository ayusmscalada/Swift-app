import Foundation

/// Grinding (the original's Grinding.txt), played as Oscar's Grind: each cycle aims to finish
/// one unit up. The stake stays the same after a loss and grows by one unit after a win, but
/// never beyond what the cycle still needs. Bets follow the last winner, as in Martingale.
public struct GrindingStrategy: BaccaratStrategy {
    public static let id = StrategyID.grinding
    public static let isImplemented = true

    static let firstSide = StrategyParameter(
        "firstSide", "Bet On", default: "P",
        help: "B or P: the side to bet before the shoe has a winner.",
        choices: StrategyParameter.sideChoices
    )
    static let unit = StrategyParameter(
        "unit", "Amount (units)", default: "1",
        help: "Starting stake, the step added after a win and the profit target of each cycle."
    )

    public static let parameters = [firstSide, unit] + StrategyParameter.sessionRules

    public var settings: StrategySettings
    private var core: BettingCore

    public init(settings: StrategySettings) {
        self.settings = settings
        core = BettingCore(.grind(unit: settings.positiveDecimal(Self.unit) ?? 1))
    }

    public mutating func evaluate(history: GameHistory, roads: RoadmapSnapshot, ledger: BetLedger) -> BetSuggestion {
        core.update(ledger: ledger, settings: settings)
        if let winner = history.decisions.last {
            return core.bet(winner, reason: "Follow the last winner.")
        }
        return core.bet(settings.side(Self.firstSide), reason: "First bet of the shoe.")
    }

    public mutating func reset() {}
}
