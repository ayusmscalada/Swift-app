import Foundation

/// Odd Even (the original's Odd Even.txt). Results are numbered 1, 2, 3, … in the shoe, ties
/// not counted. Odd-numbered results are bet on one side and even-numbered on the other.
/// Stakes follow a list: next stake after a loss, first stake after a win.
public struct OddEvenStrategy: BaccaratStrategy {
    public static let id = StrategyID.oddEven
    public static let isImplemented = true

    static let oddSide = StrategyParameter(
        "oddSide", "Odd results on", default: "B",
        help: "B or P: the side for odd-numbered results. Even-numbered results get the other side.",
        choices: StrategyParameter.sideChoices
    )
    static let amounts = StrategyParameter(
        "amounts", "Stakes (units)", default: "1,2,3,6,12,24",
        help: "Stakes in order, separated by commas. After losing the last one it starts again."
    )

    public static let parameters = [oddSide, amounts] + StrategyParameter.sessionRules

    public var settings: StrategySettings
    private var core: BettingCore

    public init(settings: StrategySettings) {
        self.settings = settings
        core = BettingCore(.sequence(settings.amounts(Self.amounts)))
    }

    public mutating func evaluate(history: GameHistory, roads: RoadmapSnapshot, ledger: BetLedger) -> BetSuggestion {
        core.update(ledger: ledger, settings: settings)
        let number = history.decisions.count + 1
        let oddSide = settings.side(Self.oddSide)
        let isOdd = number % 2 == 1
        let side = isOdd ? oddSide : (oddSide.opposite ?? .player)
        return core.bet(side, reason: "Result \(number) is \(isOdd ? "odd" : "even").")
    }

    public mutating func reset() {}
}
