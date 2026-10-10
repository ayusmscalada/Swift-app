import Foundation

/// Strategy 2. Rules come from the client's notes and the original app's observed behaviour,
/// written up in Docs/Strategies/Strategy2.md and signed off before implementation.
/// Until then it conforms to `PendingSpecStrategy` and never suggests a bet.
public struct Strategy2: PendingSpecStrategy {
    public static let id = StrategyID.s2
    public var settings: StrategySettings

    public init(settings: StrategySettings) {
        self.settings = settings
    }
}
