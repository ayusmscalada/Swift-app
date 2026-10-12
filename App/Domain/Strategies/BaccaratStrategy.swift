import Foundation

public enum StrategyID: String, Codable, CaseIterable, Hashable, Sendable {
    case martingale, grinding, sequence, pattern
    case oddEven = "odd_even"
    case oddDiff = "odd_diff"
    case oddLooser = "odd_looser"
    case oddIsGod = "odd_is_god"

    /// The name the original app uses.
    public var title: String {
        switch self {
        case .martingale: return "Martingale"
        case .grinding: return "Grinding"
        case .sequence: return "Sequence"
        case .pattern: return "PATTERN"
        case .oddEven: return "Odd Even"
        case .oddDiff: return "ODD Diff"
        case .oddLooser: return "ODD Looser"
        case .oddIsGod: return "ODD is God"
        }
    }
}

/// User-set parameters for one strategy. `parameters` holds strategy-specific values
/// (named in each strategy's spec) so the database schema does not change per strategy.
public struct StrategySettings: Codable, Hashable, Sendable {
    public var baseUnit: Decimal
    public var parameters: [String: String]

    public init(baseUnit: Decimal = 10, parameters: [String: String] = [:]) {
        self.baseUnit = baseUnit
        self.parameters = parameters
    }

    private enum CodingKeys: String, CodingKey {
        case baseUnit, parameters
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseUnit = try container.decodeDecimalString(forKey: .baseUnit)
        parameters = try container.decodeIfPresent([String: String].self, forKey: .parameters) ?? [:]
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(baseUnit)", forKey: .baseUnit)
        try container.encode(parameters, forKey: .parameters)
    }
}

/// Every strategy is its own type behind this protocol.
///
/// Strategies must be deterministic: the same history and settings always give the same
/// suggestion. `SessionEngine` calls `evaluate` once per hand, in order, so a strategy may
/// keep progression state in its own properties; `reset` clears it.
public protocol BaccaratStrategy {
    static var id: StrategyID { get }
    /// False until the strategy's rule spec is signed off and implemented.
    static var isImplemented: Bool { get }
    /// Settings shown in the Strategy panel, stored in `StrategySettings.parameters`.
    static var parameters: [StrategyParameter] { get }

    var settings: StrategySettings { get set }

    init(settings: StrategySettings)

    /// Called before every hand with the shoe so far; returns the suggestion for the next hand.
    mutating func evaluate(history: GameHistory, roads: RoadmapSnapshot, ledger: BetLedger) -> BetSuggestion

    /// Called at the start of each shoe.
    mutating func reset()
}

/// Default behaviour for a strategy whose rules are not yet specified: it never bets,
/// so the app can never show an invented rule. Remove this conformance when implementing.
public protocol PendingSpecStrategy: BaccaratStrategy {}

extension BaccaratStrategy {
    public static var parameters: [StrategyParameter] { [] }
}

extension PendingSpecStrategy {
    public static var isImplemented: Bool { false }

    public mutating func evaluate(history: GameHistory, roads: RoadmapSnapshot, ledger: BetLedger) -> BetSuggestion {
        .noBet("\(Self.id.title) rules are pending sign-off (see Docs/Strategies).")
    }

    public mutating func reset() {}
}
