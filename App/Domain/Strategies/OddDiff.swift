import Foundation

/// ODD Diff (the original's ODD Diff.txt). Counts Banker and Player among the odd-numbered
/// results of the shoe (1st, 3rd, 5th, …, ties not counted) and bets the side that leads.
/// No bet while they are level. Stakes follow a list: next after a loss, first after a win.
public struct OddDiffStrategy: BaccaratStrategy {
    public static let id = StrategyID.oddDiff
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
        let banker = odd.filter { $0 == .banker }.count
        let player = odd.count - banker
        guard banker != player else {
            return core.wait("Banker and Player are level on odd-numbered results (\(banker)–\(player)).")
        }
        let side: Outcome = banker > player ? .banker : .player
        return core.bet(side, reason: "Leads on odd-numbered results, Banker \(banker)–\(player) Player.")
    }

    public mutating func reset() {}
}
