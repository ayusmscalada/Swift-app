import Foundation

/// Strategy 9. Rules come from the client's notes and the original app's observed behaviour,
/// written up in Docs/Strategies/Strategy9.md and signed off before implementation.
/// Until then it conforms to `PendingSpecStrategy` and never suggests a bet.
public struct Strategy9: PendingSpecStrategy {
    public static let id = StrategyID.s9
    public var settings: StrategySettings

    public init(settings: StrategySettings) {
        self.settings = settings
    }
}
