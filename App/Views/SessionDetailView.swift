import SwiftUI
import AppKit

/// The main working screen, arranged like the original's main screen but cleaner:
/// strategy settings on the left, entry, bet history and roads in the middle, and session,
/// next bet, balance and statistics on the right.
///
/// The screen scrolls vertically. On medium windows the right column joins the middle one,
/// and on narrow windows everything is one column, so nothing is cut off at any size.
struct SessionDetailView: View {
    @Environment(GameViewModel.self) private var game
    @Environment(TrialGuard.self) private var trial
    @FocusState private var isFocused: Bool

    /// True while a text field is being edited: AppKit then makes its field editor (an `NSText`)
    /// the first responder, and SwiftUI still passes the key press up to this view.
    private static var isEditingText: Bool {
        NSApp.keyWindow?.firstResponder is NSText
    }

    /// From this width: three columns.
    private static let wideLayoutWidth: CGFloat = 1180
    /// From this width: two columns (strategy, then everything else).
    private static let mediumLayoutWidth: CGFloat = 780
    private static let strategyColumnWidth: CGFloat = 320
    private static let infoColumnWidth: CGFloat = 270

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ScrollView(.vertical) {
                Group {
                    if width >= Self.wideLayoutWidth {
                        HStack(alignment: .top, spacing: 12) {
                            StrategyPanel().frame(width: Self.strategyColumnWidth)
                            playColumn(stackRoads: false)
                            infoColumn.frame(width: Self.infoColumnWidth)
                        }
                    } else if width >= Self.mediumLayoutWidth {
                        HStack(alignment: .top, spacing: 12) {
                            StrategyPanel().frame(width: Self.strategyColumnWidth)
                            VStack(spacing: 12) {
                                SessionInfoPanel()
                                playColumn(stackRoads: true)
                                StatsPanel()
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            SessionInfoPanel()
                            playColumn(stackRoads: true)
                            StrategyPanel()
                            StatsPanel()
                        }
                    }
                }
                .padding(12)
            }
        }
        // The original's navy background; controls use their dark look on it.
        .background(Color.appBackground)
        .environment(\.colorScheme, .dark)
        // B / P / T enter results while no text field has focus; a focused field keeps its keys.
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onKeyPress(characters: CharacterSet(charactersIn: "bptBPT")) { press in
            // Typing into a text field (strategy settings, bankroll, …) must not enter a result.
            guard !trial.isFrozen, !Self.isEditingText, let outcome = Outcome(token: press.characters) else { return .ignored }
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

    /// Result entry, bet history and roads.
    private func playColumn(stackRoads: Bool) -> some View {
        VStack(spacing: 12) {
            GameInputView()
                .frame(maxWidth: .infinity, alignment: .leading)
            HistoryTableView()
                .frame(height: 360)
            RoadmapBoard(isStacked: stackRoads)
        }
        .frame(maxWidth: .infinity)
    }

    private var infoColumn: some View {
        VStack(spacing: 12) {
            SessionInfoPanel()
            StatsPanel()
        }
    }
}
