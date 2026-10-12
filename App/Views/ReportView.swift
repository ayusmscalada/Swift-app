import SwiftUI

/// Session report plus a table of all saved sessions. Export writes the hand-by-hand CSV.
/// Report layout and export formats are to be matched to the original during analysis.
struct ReportView: View {
    @Environment(GameViewModel.self) private var game
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var allSessions: [SessionSummaryRow] = []

    var body: some View {
        let report = ReportViewModel(session: game.loaded, ledger: game.ledger)
        let stats = report.statistics
        let summary = report.summary

        VStack(alignment: .leading, spacing: 16) {
            Text(game.session?.name ?? "Report").font(.title2.weight(.semibold))

            HStack(alignment: .top, spacing: 32) {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                    GridRow { Text("Hands").bold(); Text("\(stats.total)") }
                    ForEach(Outcome.allCases, id: \.self) { outcome in
                        GridRow {
                            Text(outcome.title).foregroundStyle(outcome.color)
                            Text("\(stats.count(outcome))  (\(String(format: "%.1f%%", stats.percentage(outcome))))")
                        }
                    }
                    GridRow { Text("Banker pairs"); Text("\(stats.bankerPairs)") }
                    GridRow { Text("Player pairs"); Text("\(stats.playerPairs)") }
                    GridRow { Text("Longest Banker run"); Text("\(stats.longestBankerStreak)") }
                    GridRow { Text("Longest Player run"); Text("\(stats.longestPlayerStreak)") }
                }

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                    GridRow { Text("Strategy").bold(); Text(game.strategyID.title) }
                    GridRow { Text("Starting bankroll"); Text(game.bankroll.money) }
                    GridRow { Text("Bets placed"); Text("\(summary.betsPlaced)") }
                    GridRow { Text("Wins / losses / pushes"); Text("\(summary.wins) / \(summary.losses) / \(summary.pushes)") }
                    GridRow { Text("Total wagered"); Text(summary.totalWagered.money) }
                    GridRow { Text("Net P/L"); Text(summary.netResult.signedMoney) }
                    GridRow { Text("Peak balance"); Text(summary.peakBalance.money) }
                    GridRow { Text("Max drawdown"); Text(summary.maxDrawdown.money) }
                }
            }
            .monospacedDigit()

            Text("All sessions").font(.headline)
            Table(allSessions) {
                TableColumn("Session", value: \.name)
                TableColumn("Strategy") { Text($0.strategy.title) }
                TableColumn("Hands") { Text("\($0.hands)").monospacedDigit() }
                TableColumn("Bets") { Text("\($0.summary.betsPlaced)").monospacedDigit() }
                TableColumn("Net P/L") { row in
                    Text(row.summary.netResult.signedMoney)
                        .monospacedDigit()
                        .foregroundStyle(row.summary.netResult < 0 ? .red : .primary)
                }
            }
            .frame(minHeight: 160)

            HStack {
                Button("Export CSV…") { isExporting = true }
                    .disabled(game.session == nil)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 720, minHeight: 560)
        .onAppear { allSessions = game.allSessionSummaries() }
        .fileExporter(
            isPresented: $isExporting,
            document: game.csvDocument,
            contentType: .commaSeparatedText,
            defaultFilename: game.csvFileName
        ) { result in
            if case .failure(let error) = result { game.errorMessage = error.localizedDescription }
        }
    }
}
