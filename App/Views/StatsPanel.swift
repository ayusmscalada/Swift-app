import SwiftUI

struct StatsPanel: View {
    @Environment(GameViewModel.self) private var game

    var body: some View {
        let report = ReportViewModel(session: game.loaded, ledger: game.ledger)
        let shoe = report.currentShoeStatistics
        let summary = report.summary
        let patterns = game.patterns

        GroupBox("Current shoe") {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                ForEach(Outcome.allCases, id: \.self) { outcome in
                    GridRow {
                        Text(outcome.title).foregroundStyle(outcome.color)
                        Text("\(shoe.count(outcome))").monospacedDigit()
                        Text(String(format: "%.1f%%", shoe.percentage(outcome))).monospacedDigit()
                    }
                }
                Divider()
                GridRow {
                    Text("Streak")
                    if let streak = patterns.currentStreak {
                        Text("\(streak.side.title) × \(streak.length)").gridCellColumns(2)
                    } else {
                        Text("—").gridCellColumns(2)
                    }
                }
                GridRow {
                    Text("Chop")
                    Text(patterns.chopLength > 0 ? "\(patterns.chopLength)" : "—").gridCellColumns(2)
                }
                if !patterns.flags.isEmpty {
                    GridRow {
                        Text("Pattern")
                        Text(patterns.flags.map(\.rawValue).sorted().joined(separator: ", "))
                            .foregroundStyle(.orange)
                            .gridCellColumns(2)
                    }
                }
                Divider()
                GridRow {
                    Text("Bets")
                    Text("\(summary.betsPlaced)  (W \(summary.wins) · L \(summary.losses) · P \(summary.pushes))")
                        .gridCellColumns(2)
                }
                GridRow {
                    Text("Wagered")
                    Text(summary.totalWagered.money).monospacedDigit().gridCellColumns(2)
                }
                GridRow {
                    Text("Peak")
                    Text(summary.peakBalance.money).monospacedDigit().gridCellColumns(2)
                }
                GridRow {
                    Text("Max drawdown")
                    Text(summary.maxDrawdown.money).monospacedDigit().gridCellColumns(2)
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
