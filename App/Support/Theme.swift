import SwiftUI

extension Outcome {
    var title: String {
        switch self {
        case .banker: return "Banker"
        case .player: return "Player"
        case .tie: return "Tie"
        }
    }

    var color: Color {
        switch self {
        case .banker: return .red
        case .player: return .blue
        case .tie: return .green
        }
    }
}

extension BetSuggestion.Side {
    var title: String {
        switch self {
        case .banker: return "Banker"
        case .player: return "Player"
        case .tie: return "Tie"
        case .none: return "No bet"
        }
    }

    var color: Color {
        switch self {
        case .banker: return .red
        case .player: return .blue
        case .tie: return .green
        case .none: return .secondary
        }
    }
}

extension RoadColor {
    var color: Color { self == .red ? .red : .blue }
}

extension Decimal {
    /// Up to two decimals, grouped thousands.
    var money: String {
        formatted(.number.precision(.fractionLength(0...2)))
    }

    var signedMoney: String {
        self > 0 ? "+" + money : money
    }
}

extension Color {
    /// The original's navy window background.
    static let appBackground = Color(red: 0.102, green: 0.165, blue: 0.322)
    /// Slightly lighter navy for panels and the bet table.
    static let appPanel = Color(red: 0.137, green: 0.212, blue: 0.392)
}
