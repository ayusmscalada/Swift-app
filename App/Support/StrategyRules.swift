import Foundation

/// How each strategy's rules read in the original's terms (Bet On, Win condition, Loss condition).
/// Display only: the rules themselves live in the strategy types.
struct StrategyRules {
    struct Condition {
        let betOn: String
        let amount: String
    }

    let betOn: String
    let win: Condition
    let loss: Condition
    /// Settings shown under Loss condition instead of Bet.
    let lossParameterKeys: Set<String>

    static func of(_ id: StrategyID) -> StrategyRules {
        switch id {
        case .martingale:
            return StrategyRules(
                betOn: "Last winner",
                win: Condition(betOn: "Winner", amount: "Reset Amount"),
                loss: Condition(betOn: "Winner", amount: "Multiply Amount"),
                lossParameterKeys: ["multiplier"]
            )
        case .grinding:
            return StrategyRules(
                betOn: "Last winner",
                win: Condition(betOn: "Winner", amount: "Grinding (+1 unit, until 1 unit up)"),
                loss: Condition(betOn: "Winner", amount: "Same Amount"),
                lossParameterKeys: []
            )
        case .sequence:
            return StrategyRules(
                betOn: "Sides list",
                win: Condition(betOn: "Reset Sequence", amount: "Reset Sequence"),
                loss: Condition(betOn: "Next Sequence", amount: "Next Sequence"),
                lossParameterKeys: []
            )
        case .pattern:
            return StrategyRules(
                betOn: "Streak · Chop · 2-2",
                win: Condition(betOn: "Pattern", amount: "Run loss rounded up + 1"),
                loss: Condition(betOn: "Pattern", amount: "1 unit"),
                lossParameterKeys: []
            )
        case .oddEven:
            return StrategyRules(
                betOn: "Odd Even",
                win: Condition(betOn: "Odd Even", amount: "Reset Sequence"),
                loss: Condition(betOn: "Odd Even", amount: "Next Sequence"),
                lossParameterKeys: []
            )
        case .oddDiff:
            return StrategyRules(
                betOn: "ODD Diff (leading side)",
                win: Condition(betOn: "ODD Diff", amount: "Reset Sequence"),
                loss: Condition(betOn: "ODD Diff", amount: "Next Sequence"),
                lossParameterKeys: []
            )
        case .oddLooser:
            return StrategyRules(
                betOn: "ODD Looser (trailing side)",
                win: Condition(betOn: "ODD Looser", amount: "Reset Sequence"),
                loss: Condition(betOn: "ODD Looser", amount: "Next Sequence"),
                lossParameterKeys: []
            )
        case .oddIsGod:
            return StrategyRules(
                betOn: "ODD is God (last odd result)",
                win: Condition(betOn: "ODD is God", amount: "Reset Sequence"),
                loss: Condition(betOn: "ODD is God", amount: "Next Sequence"),
                lossParameterKeys: []
            )
        }
    }
}
