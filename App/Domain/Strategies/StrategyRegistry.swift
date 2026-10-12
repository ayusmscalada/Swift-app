import Foundation

public enum StrategyRegistry {
    /// Strategies in the order the picker shows them.
    public static let all: [StrategyID] = StrategyID.allCases

    public static func strategyType(for id: StrategyID) -> any BaccaratStrategy.Type {
        switch id {
        case .martingale: return MartingaleStrategy.self
        case .grinding: return GrindingStrategy.self
        case .sequence: return SequenceStrategy.self
        case .pattern: return PatternStrategy.self
        case .oddEven: return OddEvenStrategy.self
        case .oddDiff: return OddDiffStrategy.self
        case .oddLooser: return OddLooserStrategy.self
        case .oddIsGod: return OddIsGodStrategy.self
        }
    }

    public static func make(_ id: StrategyID, settings: StrategySettings) -> any BaccaratStrategy {
        strategyType(for: id).init(settings: settings)
    }

    public static func isImplemented(_ id: StrategyID) -> Bool {
        strategyType(for: id).isImplemented
    }

    public static func parameters(for id: StrategyID) -> [StrategyParameter] {
        strategyType(for: id).parameters
    }
}
