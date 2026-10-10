import Foundation

/// Strategy 4. Rules come from the client's notes and the original app's observed behaviour,
/// written up in Docs/Strategies/Strategy4.md and signed off before implementation.
/// Until then it conforms to `PendingSpecStrategy` and never suggests a bet.
public struct Strategy4: PendingSpecStrategy {
    public static let id = StrategyID.s4
    public var settings: StrategySettings

    public init(settings: StrategySettings) {
        self.settings = settings
    }
}
