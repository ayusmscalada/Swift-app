import Foundation

/// One hand in the ledger: what was suggested and what it paid.
public struct LedgerEntry: Hashable, Sendable {
    public let shoeIndex: Int
    public let handIndex: Int
    public let outcome: Outcome
    public let suggestion: BetSuggestion
    public let stake: Decimal
    public let net: Decimal
    public let balance: Decimal

    public var isBet: Bool { suggestion.side != .none && stake > 0 }
}

public struct LedgerSummary: Hashable, Sendable {
    public var betsPlaced = 0
    public var wins = 0
    public var losses = 0
    public var pushes = 0
    public var totalWagered: Decimal = 0
    public var netResult: Decimal = 0
    public var peakBalance: Decimal = 0
    /// Largest fall from a peak balance.
    public var maxDrawdown: Decimal = 0
}

/// Per-hand money record. Statistics and reports read only from here, so they cannot drift.
public struct BetLedger: Hashable, Sendable {
    public let startingBankroll: Decimal
    public private(set) var entries: [LedgerEntry] = []

    public init(startingBankroll: Decimal) {
        self.startingBankroll = startingBankroll
    }

    public var balance: Decimal { entries.last?.balance ?? startingBankroll }

    public mutating func record(
        shoeIndex: Int,
        handIndex: Int,
        outcome: Outcome,
        suggestion: BetSuggestion,
        stake: Decimal,
        net: Decimal
    ) {
        entries.append(LedgerEntry(
            shoeIndex: shoeIndex,
            handIndex: handIndex,
            outcome: outcome,
            suggestion: suggestion,
            stake: stake,
            net: net,
            balance: balance + net
        ))
    }

    public var summary: LedgerSummary {
        var summary = LedgerSummary()
        summary.peakBalance = startingBankroll
        for entry in entries {
            if entry.isBet {
                summary.betsPlaced += 1
                summary.totalWagered += entry.stake
                if entry.net > 0 {
                    summary.wins += 1
                } else if entry.net < 0 {
                    summary.losses += 1
                } else {
                    summary.pushes += 1
                }
            }
            summary.peakBalance = max(summary.peakBalance, entry.balance)
            summary.maxDrawdown = max(summary.maxDrawdown, summary.peakBalance - entry.balance)
        }
        summary.netResult = balance - startingBankroll
        return summary
    }
}
