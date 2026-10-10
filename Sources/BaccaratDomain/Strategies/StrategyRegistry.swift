import Foundation

public enum StrategyRegistry {
    /// V1 strategies in priority order.
    public static let all: [StrategyID] = [.s9, .s1, .s2, .s3, .s4, .s5, .s6]

    public static func strategyType(for id: StrategyID) -> any BaccaratStrategy.Type {
        switch id {
        case .s1: return Strategy1.self
        case .s2: return Strategy2.self
        case .s3: return Strategy3.self
        case .s4: return Strategy4.self
        case .s5: return Strategy5.self
        case .s6: return Strategy6.self
        case .s9: return Strategy9.self
        }
    }

    public static func make(_ id: StrategyID, settings: StrategySettings) -> any BaccaratStrategy {
        strategyType(for: id).init(settings: settings)
    }

    public static func isImplemented(_ id: StrategyID) -> Bool {
        strategyType(for: id).isImplemented
    }
}
