import Foundation

/// A card rank. Suits do not matter in Baccarat.
public enum CardRank: String, Codable, CaseIterable, Hashable, Sendable {
    case ace = "A", two = "2", three = "3", four = "4", five = "5", six = "6", seven = "7"
    case eight = "8", nine = "9", ten = "10", jack = "J", queen = "Q", king = "K"

    /// Baccarat value: Ace 1, 2–9 face value, 10 and pictures 0.
    public var points: Int {
        switch self {
        case .ace: return 1
        case .ten, .jack, .queen, .king: return 0
        default: return Int(rawValue) ?? 0
        }
    }
}

/// The cards of one hand, as shown in the original's Player / Banker columns.
public struct HandCards: Codable, Hashable, Sendable {
    public var player: [CardRank]
    public var banker: [CardRank]

    public init(player: [CardRank] = [], banker: [CardRank] = []) {
        self.player = player
        self.banker = banker
    }

    public var isEmpty: Bool { player.isEmpty && banker.isEmpty }
    public var playerTotal: Int { player.reduce(0) { $0 + $1.points } % 10 }
    public var bankerTotal: Int { banker.reduce(0) { $0 + $1.points } % 10 }

    /// The winner once both sides have at least two cards. Drawing rules are not checked.
    public var outcome: Outcome? {
        guard player.count >= 2, banker.count >= 2 else { return nil }
        if playerTotal == bankerTotal { return .tie }
        return playerTotal > bankerTotal ? .player : .banker
    }

    /// A pair is the first two cards of a side having the same rank.
    public var playerPair: Bool { player.count >= 2 && player[0] == player[1] }
    public var bankerPair: Bool { banker.count >= 2 && banker[0] == banker[1] }

    /// Stored as "Q,4,3|5,5,K" (Player | Banker).
    public var encoded: String {
        player.map(\.rawValue).joined(separator: ",") + "|" + banker.map(\.rawValue).joined(separator: ",")
    }

    public init?(encoded: String) {
        let sides = encoded.split(separator: "|", omittingEmptySubsequences: false)
        guard sides.count == 2 else { return nil }
        let parse = { (text: Substring) in text.split(separator: ",").compactMap { CardRank(rawValue: String($0)) } }
        self.init(player: parse(sides[0]), banker: parse(sides[1]))
    }
}
