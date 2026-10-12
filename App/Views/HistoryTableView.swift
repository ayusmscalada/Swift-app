import SwiftUI

/// Hands of the current shoe with the suggestion made before each one.
/// Right-click a row to change its result or delete it; everything after it is recalculated.
struct HistoryTableView: View {
    @Environment(GameViewModel.self) private var game
    @State private var selection = Set<Int64>()

    var body: some View {
        Table(Array(game.currentShoeRows.reversed()), selection: $selection) {
            TableColumn("#") { row in
                Text("\(row.number)").monospacedDigit()
            }
            .width(36)

            TableColumn("Result") { row in
                Text(row.hand.outcome.title + pairSuffix(row.hand))
                    .foregroundStyle(row.hand.outcome.color)
            }
            .width(min: 70, ideal: 90)

            TableColumn("Suggested") { row in
                let suggestion = row.entry.suggestion
                Text(suggestion.side == .none ? "—" : "\(suggestion.side.title) × \(suggestion.units.money)")
                    .foregroundStyle(suggestion.side.color)
            }

            TableColumn("Stake") { row in
                Text(row.entry.stake.money).monospacedDigit()
            }

            TableColumn("Net") { row in
                Text(row.entry.isBet ? row.entry.net.signedMoney : "—")
                    .monospacedDigit()
                    .foregroundStyle(row.entry.net < 0 ? .red : .primary)
            }

            TableColumn("Balance") { row in
                Text(row.entry.balance.money).monospacedDigit()
            }
        }
        .contextMenu(forSelectionType: Int64.self) { ids in
            if let id = ids.first {
                ForEach(Outcome.allCases, id: \.self) { outcome in
                    Button("Change to \(outcome.title)") { game.edit(handID: id, to: outcome) }
                }
                Divider()
                Button("Delete Hand", role: .destructive) { game.deleteHand(id) }
            }
        }
        .frame(minHeight: 160)
    }

    private func pairSuffix(_ hand: Hand) -> String {
        switch (hand.bankerPair, hand.playerPair) {
        case (true, true): return " · BP PP"
        case (true, false): return " · BP"
        case (false, true): return " · PP"
        default: return ""
        }
    }
}
