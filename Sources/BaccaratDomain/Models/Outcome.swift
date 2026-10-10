import Foundation

/// The result of one Baccarat hand.
public enum Outcome: String, Codable, CaseIterable, Hashable, Sendable {
    case banker = "B"
    case player = "P"
    case tie = "T"

    public var isTie: Bool { self == .tie }

    /// Parses "B" / "P" / "T" or the full words, ignoring case and surrounding whitespace.
    public init?(token: String) {
        switch token.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "B", "BANKER": self = .banker
        case "P", "PLAYER": self = .player
        case "T", "TIE": self = .tie
        default: return nil
        }
    }
}

/// One entered hand: its outcome plus the optional pair flags.
public struct Hand: Codable, Hashable, Sendable {
    public var outcome: Outcome
    public var bankerPair: Bool
    public var playerPair: Bool

    public init(_ outcome: Outcome, bankerPair: Bool = false, playerPair: Bool = false) {
        self.outcome = outcome
        self.bankerPair = bankerPair
        self.playerPair = playerPair
    }
}

/// The hands of one shoe, in the order they were dealt.
public struct GameHistory: Hashable, Sendable {
    public var hands: [Hand]

    public init(hands: [Hand] = []) {
        self.hands = hands
    }

    /// Builds a history from a compact string such as "BBPTP". Other characters are ignored.
    public init(_ sequence: String) {
        hands = sequence.compactMap { Outcome(rawValue: String($0).uppercased()) }.map { Hand($0) }
    }

    public var count: Int { hands.count }
    public var isEmpty: Bool { hands.isEmpty }
    public var outcomes: [Outcome] { hands.map(\.outcome) }

    public func appending(_ hand: Hand) -> GameHistory {
        GameHistory(hands: hands + [hand])
    }
}
