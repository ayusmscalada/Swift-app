import Foundation

/// Martingale (the original's Martingale.txt): the first bet is on Player, then every bet
/// follows the last winner. The stake doubles after a loss and goes back to the start after a win.
public struct MartingaleStrategy: BaccaratStrategy {
    public static let id = StrategyID.martingale
    public static let isImplemented = true

    static let firstSide = StrategyParameter(
        "firstSide", "First bet on", default: "P",
        help: "B or P: the side to bet before the shoe has a winner.",
        choices: StrategyParameter.sideChoices
    )
    static let startUnits = StrategyParameter(
        "startUnits", "Starting stake (units)", default: "1",
        help: "Stake of the first bet and after every win."
    )
    static let multiplier = StrategyParameter(
        "multiplier", "Multiply after a loss", default: "2",
        help: "The stake is multiplied by this after each loss."
    )

    public static let parameters = [firstSide, startUnits, multiplier] + StrategyParameter.sessionRules

    public var settings: StrategySettings
    private var core: BettingCore

    public init(settings: StrategySettings) {
        self.settings = settings
        core = BettingCore(.multiply(
            start: settings.positiveDecimal(Self.startUnits) ?? 1,
            factor: settings.positiveDecimal(Self.multiplier) ?? 2
        ))
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
