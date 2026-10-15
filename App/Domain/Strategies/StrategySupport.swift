import Foundation

/// A strategy setting shown in the Strategy panel and stored in `StrategySettings.parameters`.
public struct StrategyParameter: Hashable, Sendable {
    public let key: String
    public let title: String
    /// Used when the value is empty or invalid. Empty means the rule is off.
    public let defaultValue: String
    public let help: String
    /// When not empty, the value is picked from this list instead of typed.
    public let choices: [String]

    public init(_ key: String, _ title: String, default defaultValue: String, help: String, choices: [String] = []) {
        self.key = key
        self.title = title
        self.defaultValue = defaultValue
        self.help = help
        self.choices = choices
    }
}

extension StrategyParameter {
    static let sideChoices = ["P", "B"]
    static let actionChoices = ["STOP BET", "REBET"]

    // Stop and pause rules from the original's main screen and strategy files (stop_profit,
    // stop_loss, consecutive win and loss counts). Every strategy has them; empty means off.
    public static let stopProfit = StrategyParameter(
        "stopProfit", "Stop profit", default: "",
        help: "Stop betting once the session is up by this amount of money. Empty: off."
    )
    public static let stopLoss = StrategyParameter(
        "stopLoss", "Stop loss", default: "",
        help: "Stop betting once the session is down by this amount of money. Empty: off."
    )

    public static let winAction = StrategyParameter(
        "winAction", "Action", default: "STOP BET",
        help: "STOP BET stops betting. REBET restarts the stake progression and keeps betting.",
        choices: actionChoices
    )
    public static let winLimit = StrategyParameter(
        "winLimit", "After wins in a row", default: "",
        help: "After this many wins in a row, apply the action. Empty: off."
    )
    public static let pauseAfterWins = StrategyParameter(
        "pauseAfterWins", "Pause after wins in a row", default: "",
        help: "After this many wins in a row, skip some hands. Empty: off."
    )
    public static let pauseWinHands = StrategyParameter(
        "pauseWinHands", "Hands to skip", default: "",
        help: "How many hands to skip when pausing after wins."
    )

    public static let lossAction = StrategyParameter(
        "lossAction", "Action", default: "STOP BET",
        help: "STOP BET stops betting. REBET restarts the stake progression and keeps betting.",
        choices: actionChoices
    )
    public static let lossLimit = StrategyParameter(
        "lossLimit", "After losses in a row", default: "",
        help: "After this many losses in a row, apply the action. Empty: off."
    )
    public static let pauseAfterLosses = StrategyParameter(
        "pauseAfterLosses", "Pause after losses in a row", default: "",
        help: "After this many losses in a row, skip some hands. Empty: off."
    )
    public static let pauseHands = StrategyParameter(
        "pauseHands", "Hands to skip", default: "",
        help: "How many hands to skip when pausing after losses."
    )

    public static let moneyRules = [stopProfit, stopLoss]
    public static let winRules = [winAction, winLimit, pauseAfterWins, pauseWinHands]
    public static let lossRules = [lossAction, lossLimit, pauseAfterLosses, pauseHands]
    public static let sessionRules = moneyRules + winRules + lossRules
}

extension StrategySettings {
    /// The trimmed value, or the parameter's default when it is empty.
    public func value(_ parameter: StrategyParameter) -> String {
        let text = parameters[parameter.key]?.trimmingCharacters(in: .whitespaces) ?? ""
        return text.isEmpty ? parameter.defaultValue : text
    }

    /// A number above zero; falls back to the default when the value is not one. Nil when off.
    func positiveDecimal(_ parameter: StrategyParameter) -> Decimal? {
        for text in [value(parameter), parameter.defaultValue] {
            if let number = Decimal(string: text), number > 0 { return number }
        }
        return nil
    }

    func positiveInt(_ parameter: StrategyParameter) -> Int? {
        positiveDecimal(parameter).map { NSDecimalNumber(decimal: $0.rounded(scale: 0)).intValue }
    }

    /// A list such as "1,2,3". The original also writes "2_4_6", so "_" separates too.
    func amounts(_ parameter: StrategyParameter) -> [Decimal] {
        let parse = { (text: String) in
            text.split(whereSeparator: { ",_ ".contains($0) })
                .compactMap { Decimal(string: String($0)) }
                .filter { $0 > 0 }
        }
        let list = parse(value(parameter))
        return list.isEmpty ? parse(parameter.defaultValue) : list
    }

    /// A list of Banker / Player sides such as "B,P,P". Ties are not accepted.
    func sides(_ parameter: StrategyParameter) -> [Outcome] {
        let parse = { (text: String) in
            text.split(whereSeparator: { ",_ ".contains($0) })
                .compactMap { Outcome(token: String($0)) }
                .filter { !$0.isTie }
        }
        let list = parse(value(parameter))
        return list.isEmpty ? parse(parameter.defaultValue) : list
    }

    func side(_ parameter: StrategyParameter) -> Outcome {
        sides(parameter).first ?? .player
    }
}

extension Outcome {
    /// Banker for Player and Player for Banker. A tie has no opposite.
    var opposite: Outcome? {
        switch self {
        case .banker: return .player
        case .player: return .banker
        case .tie: return nil
        }
    }

    var betSide: BetSuggestion.Side {
        BetSuggestion.Side(rawValue: rawValue) ?? .none
    }
}

extension GameHistory {
    /// Banker and Player results in order. Ties are left out, as on the Big Road.
    var decisions: [Outcome] { outcomes.filter { !$0.isTie } }

    /// The 1st, 3rd, 5th, … decision of the shoe.
    var oddDecisions: [Outcome] {
        decisions.enumerated().filter { $0.offset % 2 == 0 }.map(\.element)
    }
}

/// How a placed bet ended. Read from the ledger, so the payout settings decide whether a tie
/// is a push or a loss.
enum BetResult {
    case win, loss, push

    init(net: Decimal) {
        self = net > 0 ? .win : net < 0 ? .loss : .push
    }
}

/// How the stake moves after each bet, in units of the base unit. A push changes nothing.
enum StakeProgression {
    /// The same stake every bet.
    case flat(Decimal)
    /// Martingale: multiply the stake after a loss, back to the start after a win.
    case multiply(start: Decimal, factor: Decimal)
    /// Oscar's Grind: same stake after a loss, one unit more after a win but never more than
    /// needed to finish the cycle one unit up. A new cycle starts once it is.
    case grind(unit: Decimal)
    /// Next amount after a loss, first amount after a win. After losing the last amount it
    /// starts again from the first, as the original's bet logs show.
    case sequence([Decimal])
    /// IHG bet method: 1 unit after a loss. After a win, the run's loss rounded up plus one
    /// unit, so the next win closes the run ahead. A run closes once it is ahead, and after
    /// any bet of `limit` units or more, win or lose.
    case runRecovery(limit: Decimal)

    var start: Decimal {
        switch self {
        case let .flat(units): return units
        case let .multiply(start, _): return start
        case let .grind(unit): return unit
        case let .sequence(amounts): return amounts.first ?? 1
        case .runRecovery: return 1
        }
    }
}

/// What every strategy shares: it reads bet results from the ledger, moves the stake and
/// applies the stop and pause rules. A strategy only chooses the side.
///
/// The progression carries over to a new shoe; side rules look only at the current shoe.
struct BettingCore {
    let progression: StakeProgression
    /// Stake for the next bet, in units.
    private(set) var units: Decimal
    /// Losses since the progression last went back to its start.
    private(set) var step = 0
    /// Grind and run recovery: result of the current cycle or run, in units.
    private(set) var runProfit: Decimal = 0
    private var seenEntries = 0
    private var winsInARow = 0
    private var lossesInARow = 0
    private var handsToPause = 0
    private var pauseReason = ""
    private var stopReason: String?

    init(_ progression: StakeProgression) {
        self.progression = progression
        units = progression.start
    }

    /// Takes in the hands recorded since the last call. Call it first in `evaluate`.
    mutating func update(ledger: BetLedger, settings: StrategySettings) {
        for entry in ledger.entries.dropFirst(seenEntries) {
            guard entry.isBet else {
                if handsToPause > 0 { handsToPause -= 1 }
                continue
            }
            let result = BetResult(net: entry.net)
            advance(after: result, net: entry.net, stake: entry.suggestion.units, baseUnit: settings.baseUnit)
            applyStreakRules(after: result, settings: settings)
        }
        seenEntries = ledger.entries.count

        let profit = ledger.balance - ledger.startingBankroll
        if stopReason == nil, let target = settings.positiveDecimal(.stopProfit), profit >= target {
            stopReason = "Stop profit reached (\(target))."
        }
        if stopReason == nil, let limit = settings.positiveDecimal(.stopLoss), -profit >= limit {
            stopReason = "Stop loss reached (\(limit))."
        }
    }

    /// The bet for the next hand, unless betting is stopped or paused.
    func bet(_ side: Outcome, reason: String) -> BetSuggestion {
        if let blockedReason { return .noBet(blockedReason) }
        let showsStep: Bool
        switch progression {
        case .flat, .runRecovery: showsStep = false
        case .multiply, .grind, .sequence: showsStep = true
        }
        return BetSuggestion(side: side.betSide, units: units, step: showsStep ? step + 1 : nil, reason: reason)
    }

    /// No bet this hand, because the strategy is waiting for its trigger.
    func wait(_ reason: String) -> BetSuggestion {
        .noBet(blockedReason ?? reason)
    }

    private var blockedReason: String? {
        if let stopReason { return stopReason }
        if handsToPause > 0 {
            return "\(pauseReason): \(handsToPause) more hand\(handsToPause == 1 ? "" : "s")."
        }
        return nil
    }

    private mutating func advance(after result: BetResult, net: Decimal, stake: Decimal, baseUnit: Decimal) {
        guard result != .push else { return }
        switch progression {
        case .flat:
            break
        case let .multiply(_, factor):
            if result == .win {
                restart()
            } else {
                units *= factor
                step += 1
            }
        case let .grind(unit):
            runProfit += baseUnit > 0 ? net / baseUnit : 0
            if runProfit >= unit {
                restart()
            } else if result == .win {
                let needed = ((unit - runProfit) / unit).rounded(scale: 0, mode: .up) * unit
                units = max(unit, min(units + unit, needed))
            } else {
                step += 1
            }
        case let .sequence(amounts):
            if result == .win {
                restart()
            } else {
                step += 1
                units = amounts[step % amounts.count]
            }
        case let .runRecovery(limit):
            runProfit += baseUnit > 0 ? net / baseUnit : 0
            if runProfit > 0 || stake >= limit {
                restart()
            } else if result == .win {
                units = (-runProfit).rounded(scale: 0, mode: .up) + 1
            } else {
                units = 1
            }
        }
    }

    private enum StreakRuleOutcome {
        case nothing, rebet, stop(Int), pause(Int)
    }

    /// The win or loss rule that applies after `count` results in a row.
    private func streakRule(
        count: Int,
        limit: StrategyParameter,
        action: StrategyParameter,
        pauseAfter: StrategyParameter,
        pauseHands: StrategyParameter,
        settings: StrategySettings
    ) -> StreakRuleOutcome {
        if let limit = settings.positiveInt(limit), count >= limit {
            return settings.value(action).uppercased() == "REBET" ? .rebet : .stop(limit)
        }
        if let after = settings.positiveInt(pauseAfter), count == after, let hands = settings.positiveInt(pauseHands) {
            return .pause(hands)
        }
        return .nothing
    }

    private mutating func applyStreakRules(after result: BetResult, settings: StrategySettings) {
        switch result {
        case .push:
            return
        case .win:
            winsInARow += 1
            lossesInARow = 0
            let rule = streakRule(
                count: winsInARow, limit: .winLimit, action: .winAction,
                pauseAfter: .pauseAfterWins, pauseHands: .pauseWinHands, settings: settings
            )
            switch rule {
            case .nothing: break
            case .rebet: restart(); winsInARow = 0
            case let .stop(limit): if stopReason == nil { stopReason = "Stopped after \(limit) wins in a row." }
            case let .pause(hands): handsToPause = hands; pauseReason = "Paused after \(winsInARow) wins in a row"
            }
        case .loss:
            lossesInARow += 1
            winsInARow = 0
            let rule = streakRule(
                count: lossesInARow, limit: .lossLimit, action: .lossAction,
                pauseAfter: .pauseAfterLosses, pauseHands: .pauseHands, settings: settings
            )
            switch rule {
            case .nothing: break
            case .rebet: restart(); lossesInARow = 0
            case let .stop(limit): if stopReason == nil { stopReason = "Stopped after \(limit) losses in a row." }
            case let .pause(hands): handsToPause = hands; pauseReason = "Paused after \(lossesInARow) losses in a row"
            }
        }
    }

    /// Back to the first stake, as after a win.
    private mutating func restart() {
        units = progression.start
        step = 0
        runProfit = 0
    }
}
