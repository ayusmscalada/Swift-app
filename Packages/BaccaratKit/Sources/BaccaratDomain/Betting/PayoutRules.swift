import Foundation

/// Payout and rounding rules. Defaults are standard commission Baccarat; every value is a
/// setting because the original app may use other rules (confirm from its outputs).
public struct PayoutRules: Codable, Hashable, Sendable {
    /// Net win per unit staked on Banker (0.95 = 5% commission).
    public var bankerWin: Decimal
    public var playerWin: Decimal
    public var tieWin: Decimal
    /// Whether a tie returns Banker and Player stakes (push) instead of losing them.
    public var tieRefundsMainBets: Bool
    /// Decimal places kept on each hand's stake and net.
    public var roundingScale: Int

    public init(
        bankerWin: Decimal = Decimal(sign: .plus, exponent: -2, significand: 95),
        playerWin: Decimal = 1,
        tieWin: Decimal = 8,
        tieRefundsMainBets: Bool = true,
        roundingScale: Int = 2
    ) {
        self.bankerWin = bankerWin
        self.playerWin = playerWin
        self.tieWin = tieWin
        self.tieRefundsMainBets = tieRefundsMainBets
        self.roundingScale = roundingScale
    }

    public static let standard = PayoutRules()

    // Decimals are encoded as strings so values like 0.95 never pass through Double.
    private enum CodingKeys: String, CodingKey {
        case bankerWin, playerWin, tieWin, tieRefundsMainBets, roundingScale
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bankerWin = try container.decodeDecimalString(forKey: .bankerWin)
        playerWin = try container.decodeDecimalString(forKey: .playerWin)
        tieWin = try container.decodeDecimalString(forKey: .tieWin)
        tieRefundsMainBets = try container.decode(Bool.self, forKey: .tieRefundsMainBets)
        roundingScale = try container.decode(Int.self, forKey: .roundingScale)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(bankerWin)", forKey: .bankerWin)
        try container.encode("\(playerWin)", forKey: .playerWin)
        try container.encode("\(tieWin)", forKey: .tieWin)
        try container.encode(tieRefundsMainBets, forKey: .tieRefundsMainBets)
        try container.encode(roundingScale, forKey: .roundingScale)
    }

    /// Net result of a bet: positive for a win, negative for a loss, 0 for a push or no bet.
    public func net(side: BetSuggestion.Side, stake: Decimal, outcome: Outcome) -> Decimal {
        guard side != .none, stake > 0 else { return 0 }
        let raw: Decimal
        switch (side, outcome) {
        case (.banker, .banker): raw = stake * bankerWin
        case (.player, .player): raw = stake * playerWin
        case (.tie, .tie): raw = stake * tieWin
        case (.banker, .tie), (.player, .tie): raw = tieRefundsMainBets ? 0 : -stake
        default: raw = -stake
        }
        return raw.rounded(scale: roundingScale)
    }
}

extension KeyedDecodingContainer {
    /// Reads a Decimal written as a string (or, for older data, as a number).
    func decodeDecimalString(forKey key: Key) throws -> Decimal {
        if let text = try? decode(String.self, forKey: key) {
            guard let value = Decimal(string: text) else {
                throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Not a number: \(text)")
            }
            return value
        }
        return try decode(Decimal.self, forKey: key)
    }
}

extension Decimal {
    /// Rounds half away from zero (`.plain`) to `scale` decimal places.
    public func rounded(scale: Int, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, mode)
        return result
    }
}
