import SwiftUI

/// Session, next suggestion, balance and profit: the original's right-hand column.
struct SessionInfoPanel: View {
    @Environment(GameViewModel.self) private var game

    var body: some View {
        let suggestion = game.nextSuggestion
        let profit = game.ledger.summary.netResult

        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                    GridRow {
                        Text("Session").foregroundStyle(.secondary)
                        Text(game.session?.name ?? "—").lineLimit(1)
                    }
                    GridRow {
                        Text("Shoe").foregroundStyle(.secondary)
                        Text("\(game.currentShoeNumber) · \(game.currentHistory.count) hands").monospacedDigit()
                    }
                    GridRow {
                        Text("Time").foregroundStyle(.secondary)
                        Text(Self.clock(game.sessionDuration)).monospacedDigit()
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT HAND").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Text(suggestion.side == .none ? "No bet" : "\(suggestion.side.title) · \(game.nextStake.money)")
                        .font(.title.weight(.bold))
                        .foregroundStyle(suggestion.side.color)
                    if suggestion.side != .none {
                        Text("\(suggestion.units.money) units" + (suggestion.step.map { " · step \($0)" } ?? ""))
                            .foregroundStyle(.secondary)
                    }
                    if !suggestion.reason.isEmpty {
                        Text(suggestion.reason)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 2) {
                    Text("BALANCE").font(.caption.weight(.semibold)).foregroundStyle(.green)
                    Text(game.ledger.balance.money)
                        .font(.largeTitle.weight(.bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                HStack {
                    Text("PROFIT").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Spacer()
                    Text(profit.signedMoney)
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(profit < 0 ? .red : profit > 0 ? .green : .primary)
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text("Session").font(.headline)
        }
    }

    /// "00:09:15"
    static func clock(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        return String(format: "%02d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
    }
}
