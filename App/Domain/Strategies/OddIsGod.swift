import Foundation

/// ODD is God (the original's ODD is God.txt). Follows the most recent odd-numbered result of
/// the shoe (1st, 3rd, 5th, …, ties not counted). Stakes follow a list: next after a loss,
/// first after a win.
public struct OddIsGodStrategy: BaccaratStrategy {
    public static let id = StrategyID.oddIsGod
    public static let isImplemented = true

    static let amounts = StrategyParameter(
        "amounts", "Amount (units)", default: "1,2,3",
        help: "Stakes in order, separated by commas. After losing the last one it starts again."
    )

    public static let parameters = [amounts] + StrategyParameter.sessionRules

    public var settings: StrategySettings
    private var core: BettingCore

    public init(settings: StrategySettings) {
        self.settings = settings
        core = BettingCore(.sequence(settings.amounts(Self.amounts)))
    }

    public mutating func evaluate(history: GameHistory, roads: RoadmapSnapshot, ledger: BetLedger) -> BetSuggestion {
        core.update(ledger: ledger, settings: settings)
        let odd = history.oddDecisions
        guard let last = odd.last else {
            return core.wait("Waiting for the first result of the shoe.")
        }
        return core.bet(last, reason: "Follow result \(odd.count * 2 - 1), the last odd-numbered one.")
    }

    public mutating func reset() {}
}
