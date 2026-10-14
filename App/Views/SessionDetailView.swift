import SwiftUI
import AppKit

/// The main working screen: input and strategy on top, roads in the middle, history and stats below.
/// Layout is provisional until it is matched to the original's screenshots.
///
/// The screen scrolls vertically, and side-by-side panels stack when the window is narrow,
/// so nothing is cut off at any window size.
struct SessionDetailView: View {
    @Environment(GameViewModel.self) private var game
    @FocusState private var isFocused: Bool

    /// True while a text field is being edited: AppKit then makes its field editor (an `NSText`)
    /// the first responder, and SwiftUI still passes the key press up to this view.
    private static var isEditingText: Bool {
        NSApp.keyWindow?.firstResponder is NSText
    }

    /// Below this width, side-by-side panels are stacked.
    private static let wideLayoutWidth: CGFloat = 1000
    /// Below this width, the Strategy panel also stacks its settings above the suggestion.
    private static let narrowLayoutWidth: CGFloat = 640

    var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width >= Self.wideLayoutWidth
            let isNarrow = proxy.size.width < Self.narrowLayoutWidth
            let row = isWide
                ? AnyLayout(HStackLayout(alignment: .top, spacing: 12))
                : AnyLayout(VStackLayout(alignment: .leading, spacing: 12))

            ScrollView(.vertical) {
                VStack(spacing: 12) {
                    row {
                        GameInputView()
                        StrategyPanel(isStacked: isNarrow)
                    }
                    RoadmapBoard(isStacked: isNarrow)
                    row {
                        HistoryTableView()
                            .frame(height: 320)
                        StatsPanel()
                            .frame(minWidth: isWide ? 280 : nil, maxWidth: isWide ? 280 : .infinity)
                    }
                }
                .padding(12)
            }
        }
        // B / P / T enter results while no text field has focus; a focused field keeps its keys.
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onKeyPress(characters: CharacterSet(charactersIn: "bptBPT")) { press in
            // Typing into a text field (strategy settings, bankroll, …) must not enter a result.
            guard !Self.isEditingText, let outcome = Outcome(token: press.characters) else { return .ignored }
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
