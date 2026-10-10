import Foundation

/// What a strategy suggests for the next hand.
public struct BetSuggestion: Hashable, Sendable {
    public enum Side: String, Codable, CaseIterable, Hashable, Sendable {
        case banker = "B"
        case player = "P"
        case tie = "T"
        case none = "-"
    }

    public let side: Side
    /// Stake in units; 0 when `side == .none`.
    public let units: Decimal
    /// Position in the strategy's progression, if it has one.
    public let step: Int?
    /// Shown in the UI when the original app shows a reason.
    public let reason: String

    public init(side: Side, units: Decimal, step: Int? = nil, reason: String = "") {
        self.side = side
        self.units = side == .none ? 0 : units
        self.step = step
        self.reason = reason
    }

    public static func noBet(_ reason: String = "") -> BetSuggestion {
        BetSuggestion(side: .none, units: 0, step: nil, reason: reason)
    }
}
