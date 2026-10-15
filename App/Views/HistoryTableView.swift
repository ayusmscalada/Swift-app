import SwiftUI

/// Hands of the current shoe with the bet placed on each one, in the original's columns.
/// Right-click a row to change its result or delete it; everything after it is recalculated.
struct HistoryTableView: View {
    @Environment(GameViewModel.self) private var game
    @State private var selection = Set<Int64>()

    var body: some View {
        Table(Array(game.currentShoeRows.reversed()), selection: $selection) {
            TableColumn("No.") { row in
                Text("\(row.number)").monospacedDigit()
            }
            .width(36)

            TableColumn("Bet On") { row in
                let side = row.entry.suggestion.side
                Text(side == .none ? "—" : side.title)
                    .foregroundStyle(side.color)
            }
            .width(min: 56, ideal: 64)

            TableColumn("Amount") { row in
                Text(row.entry.isBet ? row.entry.stake.money : "—").monospacedDigit()
            }
            .width(min: 50, ideal: 64)

            TableColumn("Winner") { row in
                Text(row.hand.outcome.title + pairSuffix(row.hand))
                    .foregroundStyle(row.hand.outcome.color)
            }
            .width(min: 60, ideal: 80)

            TableColumn("Status") { row in
                let status = Self.status(row.entry)
                Text(status.text).foregroundStyle(status.color)
            }
            .width(min: 44, ideal: 52)

            TableColumn("Rule") { row in
                let reason = row.entry.suggestion.reason
                Text(reason.isEmpty ? "—" : reason)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                    .help(reason)
            }
            .width(min: 60, ideal: 140)

            TableColumn("Count") { row in
                Text(row.entry.isBet ? "\(row.count)" : "—")
                    .monospacedDigit()
                    .foregroundStyle(row.count < 0 ? .red : .primary)
            }
            .width(min: 40, ideal: 44)

            TableColumn("Balance") { row in
                Text(row.entry.balance.money).monospacedDigit()
            }
            .width(min: 60, ideal: 80)
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
        .scrollContentBackground(.hidden)
        .background(Color.appPanel, in: RoundedRectangle(cornerRadius: 6))
        .frame(minHeight: 160)
    }

    /// WIN, LOSS or TIE, as in the original's Status column.
    private static func status(_ entry: LedgerEntry) -> (text: String, color: Color) {
        guard entry.isBet else { return ("—", .secondary) }
        if entry.net > 0 { return ("WIN", .green) }
        if entry.net < 0 { return ("LOSS", .red) }
        return ("TIE", .secondary)
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
