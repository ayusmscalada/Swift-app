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
                        Text(Self.sessionTitle(game.session))
                    }
                    GridRow {
                        Text("Shoe").foregroundStyle(.secondary)
                        Text("\(game.currentShoeNumber) · \(game.currentHistory.count) hands").monospacedDigit()
                    }
                    GridRow {
                        Text("Time").foregroundStyle(.secondary)
                        Text(Self.clock(game.sessionDuration)).monospacedDigit()
                    }
                    GridRow {
                        Text("Inactive").foregroundStyle(.secondary)
                        Text("\(game.inactiveCount) hands without a bet").monospacedDigit()
                    }
                }
                .lineLimit(1)

                if let cards = game.lastCards, !cards.isEmpty {
                    Divider()
                    HStack(alignment: .top, spacing: 8) {
                        cardColumn("PLAYER", cards.player, total: cards.playerTotal, color: Outcome.player.color)
                        cardColumn("BANKER", cards.banker, total: cards.bankerTotal, color: Outcome.banker.color)
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

    /// The last hand's cards for one side, one card per line as in the original.
    private func cardColumn(_ title: String, _ ranks: [CardRank], total: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption.weight(.bold)).foregroundStyle(color)
            ForEach(Array(ranks.enumerated()), id: \.offset) { _, rank in
                Text(rank.rawValue).font(.title3.weight(.semibold)).monospacedDigit()
            }
            Text("= \(total)").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.appBackground.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
    }

    /// "2 · Monday table": the session number, as in the original, then its name.
    static func sessionTitle(_ session: SessionRecord?) -> String {
        guard let session else { return "—" }
        return session.id.map { "\($0) · \(session.name)" } ?? session.name
    }

    /// "00:09:15"
    static func clock(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        return String(format: "%02d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
    }
}
