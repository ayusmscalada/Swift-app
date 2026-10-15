import Foundation

public struct SessionInput: Sendable {
    public var shoes: [GameHistory]
    public var strategyID: StrategyID
    public var settings: StrategySettings
    public var startingBankroll: Decimal
    public var payouts: PayoutRules

    public init(
        shoes: [GameHistory],
        strategyID: StrategyID,
        settings: StrategySettings,
        startingBankroll: Decimal,
        payouts: PayoutRules = .standard
    ) {
        self.shoes = shoes
        self.strategyID = strategyID
        self.settings = settings
        self.startingBankroll = startingBankroll
        self.payouts = payouts
    }
}

public struct SessionResult: Hashable, Sendable {
    public let ledger: BetLedger
    /// The suggestion made before each hand, per shoe.
    public let suggestions: [[BetSuggestion]]
    /// The suggestion for the hand about to be dealt.
    public let nextSuggestion: BetSuggestion
    /// Roads of the current (last) shoe.
    public let roads: RoadmapSnapshot
    /// Hands in a row without a bet at the end of the session (the original's Inactive Count).
    public let inactiveCount: Int
}

/// Replays a whole session from its results. Nothing derived is stored: roads, strategy state,
/// ledger and statistics are always rebuilt from the hands, so undo and edit are exact.
public enum SessionEngine {
    public static func run(
        _ input: SessionInput,
        makeStrategy: ((StrategySettings) -> any BaccaratStrategy)? = nil
    ) -> SessionResult {
        var strategy = makeStrategy?(input.settings)
            ?? StrategyRegistry.make(input.strategyID, settings: input.settings)
        var ledger = BetLedger(startingBankroll: input.startingBankroll)
        var suggestions: [[BetSuggestion]] = []
        let shoes = input.shoes.isEmpty ? [GameHistory()] : input.shoes
        var roads = RoadmapEngine.snapshot(for: GameHistory())
        var next = BetSuggestion.noBet()

        var inactive = 0

        for (shoeIndex, shoe) in shoes.enumerated() {
            // Confirm against the original whether progressions carry across shoes.
            strategy.reset()
            var prefix = GameHistory()
            var shoeSuggestions: [BetSuggestion] = []

            for (handIndex, hand) in shoe.hands.enumerated() {
                // The strategy sees every hand, so its state stays in step even while betting is stopped.
                let proposed = strategy.evaluate(
                    history: prefix,
                    roads: RoadmapEngine.snapshot(for: prefix),
                    ledger: ledger
                )
                let suggestion = hand.betOff
                    ? BetSuggestion.noBet("Auto bet stopped.")
                    : withDummyBet(proposed, inactive: inactive, settings: strategy.settings)
                let stake = suggestion.side == .none
                    ? Decimal(0)
                    : (suggestion.units * strategy.settings.baseUnit).rounded(scale: input.payouts.roundingScale)
                ledger.record(
                    shoeIndex: shoeIndex,
                    handIndex: handIndex,
                    outcome: hand.outcome,
                    suggestion: suggestion,
                    stake: stake,
                    net: input.payouts.net(side: suggestion.side, stake: stake, outcome: hand.outcome)
                )
                inactive = (hand.betOff || stake > 0) ? 0 : inactive + 1
                shoeSuggestions.append(suggestion)
                prefix.hands.append(hand)
            }

            suggestions.append(shoeSuggestions)
            roads = RoadmapEngine.snapshot(for: prefix)
            if shoeIndex == shoes.count - 1 {
                let proposed = strategy.evaluate(history: prefix, roads: roads, ledger: ledger)
                next = withDummyBet(proposed, inactive: inactive, settings: strategy.settings)
            }
        }

        return SessionResult(
            ledger: ledger, suggestions: suggestions, nextSuggestion: next, roads: roads, inactiveCount: inactive
        )
    }

    /// The original's dummy bet: after `inactiveCount` hands in a row without a bet, put
    /// `dummyAmount` on Player so the game does not pause. Off when Inactive Count is empty.
    static func withDummyBet(_ suggestion: BetSuggestion, inactive: Int, settings: StrategySettings) -> BetSuggestion {
        guard suggestion.side == .none,
              let limit = settings.positiveInt(.inactiveCount), inactive >= limit,
              let amount = settings.positiveDecimal(.dummyAmount), settings.baseUnit > 0
        else { return suggestion }
        return BetSuggestion(
            side: .player,
            units: amount / settings.baseUnit,
            reason: "Dummy bet after \(inactive) hands without a bet.",
            isDummy: true
        )
    }
}
