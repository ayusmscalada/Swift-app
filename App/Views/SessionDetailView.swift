import SwiftUI

/// The main working screen: input and strategy on top, roads in the middle, history and stats below.
/// Layout is provisional until it is matched to the original's screenshots.
struct SessionDetailView: View {
    @Environment(GameViewModel.self) private var game
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                GameInputView()
                StrategyPanel()
            }
            RoadmapBoard()
            HStack(alignment: .top, spacing: 12) {
                HistoryTableView()
                StatsPanel()
                    .frame(width: 280)
            }
        }
        .padding(12)
        // B / P / T enter results while no text field has focus; a focused field keeps its keys.
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onKeyPress(characters: CharacterSet(charactersIn: "bptBPT")) { press in
            guard let outcome = Outcome(token: press.characters) else { return .ignored }
            game.enter(outcome)
            return .handled
        }
        .navigationTitle(game.session?.name ?? "")
        .navigationSubtitle("Shoe \(game.currentShoeNumber) · Hand \(game.currentHistory.count)")
        .toolbar {
            ToolbarItemGroup {
                Button { game.isShowingReport = true } label: {
                    Label("Report", systemImage: "chart.bar.doc.horizontal")
                }
            }
        }
    }
}
