import SwiftUI

/// Hands of the current shoe with the bet placed on each one, in the original's columns.
/// Drawn by hand instead of with `Table`, so the header and the striped rows keep clear,
/// contrasting colours on the navy background.
/// Click a row to select it; right-click it to change its result or delete it, and everything
/// after it is recalculated.
struct HistoryTableView: View {
    @Environment(GameViewModel.self) private var game
    @State private var selectedID: Int64?

    private struct Column {
        let title: String
        /// Nil: takes the remaining width.
        let width: CGFloat?
        var alignment: Alignment = .leading
    }

    private static let columns = [
        Column(title: "No.", width: 40, alignment: .trailing),
        Column(title: "Bet On", width: 64),
        Column(title: "Amount", width: 70, alignment: .trailing),
        Column(title: "Winner", width: 92),
        Column(title: "Status", width: 54),
        Column(title: "Rule", width: nil),
        Column(title: "Count", width: 48, alignment: .trailing),
        Column(title: "Balance", width: 84, alignment: .trailing),
    ]

    var body: some View {
        let rows = Array(game.currentShoeRows.reversed())

        VStack(spacing: 0) {
            header
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        rowView(row, striped: index % 2 == 1)
                    }
                }
            }
            .overlay {
                if rows.isEmpty {
                    Text("No hands yet").foregroundStyle(.secondary)
                }
            }
        }
        .background(Color.tableRow)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.tableBorder))
        .frame(minHeight: 160)
    }

    private var header: some View {
        HStack(spacing: 0) {
            ForEach(Self.columns, id: \.title) { column in
                cell(column) {
                    Text(column.title)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.tableHeaderText)
                }
            }
        }
        .frame(height: 28)
        .background(Color.tableHeader)
        .overlay(alignment: .bottom) { Color.tableBorder.frame(height: 1) }
    }

    private func rowView(_ row: HistoryRow, striped: Bool) -> some View {
        let entry = row.entry
        let side = entry.suggestion.side
        let status = Self.status(entry)
        let reason = entry.suggestion.reason
        let values: [AnyView] = [
            AnyView(Text("\(row.number)").monospacedDigit()),
            AnyView(Text(side == .none ? "—" : side.title).foregroundStyle(side.color)),
            AnyView(Text(entry.isBet ? entry.stake.money : "—").monospacedDigit()),
            AnyView(Text(row.hand.outcome.title + pairSuffix(row.hand)).foregroundStyle(row.hand.outcome.color)),
            AnyView(Text(status.text).fontWeight(.semibold).foregroundStyle(status.color)),
            AnyView(Text(reason.isEmpty ? "—" : reason).foregroundStyle(.white.opacity(0.75)).help(reason)),
            AnyView(Text(entry.isBet ? "\(row.count)" : "—").monospacedDigit()
                .foregroundStyle(row.count < 0 ? Color.red : Color.white)),
            AnyView(Text(entry.balance.money).monospacedDigit()),
        ]

        return HStack(spacing: 0) {
            ForEach(Array(Self.columns.enumerated()), id: \.offset) { index, column in
                cell(column) { values[index] }
            }
        }
        .lineLimit(1)
        .foregroundStyle(.white)
        .frame(height: 26)
        .background(selectedID == row.id ? Color.tableSelection : (striped ? Color.tableRowAlt : Color.tableRow))
        .contentShape(Rectangle())
        .onTapGesture { selectedID = row.id }
        .contextMenu {
            ForEach(Outcome.allCases, id: \.self) { outcome in
                Button("Change to \(outcome.title)") { game.edit(handID: row.id, to: outcome) }
            }
            Divider()
            Button("Delete Hand", role: .destructive) { game.deleteHand(row.id) }
        }
    }

    @ViewBuilder
    private func cell<Content: View>(_ column: Column, @ViewBuilder content: () -> Content) -> some View {
        let view = content()
            .padding(.horizontal, 6)
        if let width = column.width {
            view.frame(width: width, alignment: column.alignment)
        } else {
            view.frame(maxWidth: .infinity, alignment: column.alignment)
        }
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
