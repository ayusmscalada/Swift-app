import SwiftUI

/// Strategy choice, money settings and the suggestion for the next hand.
struct StrategyPanel: View {
    @Environment(GameViewModel.self) private var game
    /// Settings above the suggestion instead of beside it, for narrow windows.
    var isStacked = false

    var body: some View {
        let layout = isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))

        GroupBox("Strategy") {
            layout {
                Form {
                    Picker("Strategy", selection: Binding(get: { game.strategyID }, set: { game.setStrategy($0) })) {
                        ForEach(StrategyRegistry.all, id: \.self) { id in
                            Text(StrategyRegistry.isImplemented(id) ? id.title : "\(id.title) (pending)")
                                .tag(id)
                        }
                    }
                    TextField(
                        "Base unit",
                        value: Binding(get: { game.strategySettings.baseUnit }, set: { game.setBaseUnit($0) }),
                        format: .number
                    )
                    TextField(
                        "Starting bankroll",
                        value: Binding(get: { game.bankroll }, set: { game.setBankroll($0) }),
                        format: .number
                    )

                    let parameters = StrategyRegistry.parameters(for: game.strategyID)
                    ForEach(parameters.filter { !StrategyParameter.sessionRules.contains($0) }, id: \.key) {
                        ParameterField(parameter: $0)
                    }
                    let stopRules = parameters.filter { StrategyParameter.sessionRules.contains($0) }
                    if !stopRules.isEmpty {
                        DisclosureGroup("Stop and pause") {
                            ForEach(stopRules, id: \.key) { ParameterField(parameter: $0) }
                        }
                    }
                }
                .frame(maxWidth: isStacked ? .infinity : 280)

                suggestionCard
            }
            .padding(4)
        }
    }

    private var suggestionCard: some View {
        let suggestion = game.nextSuggestion
        return VStack(alignment: .leading, spacing: 6) {
            Text("Next hand")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(suggestion.side == .none ? "No bet" : "\(suggestion.side.title) · \(game.nextStake.money)")
                .font(.title2.weight(.semibold))
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
            Divider()
            HStack {
                Text("Balance")
                Spacer()
                Text(game.ledger.balance.money).monospacedDigit()
            }
            HStack {
                Text("Session P/L")
                Spacer()
                Text(game.ledger.summary.netResult.signedMoney)
                    .monospacedDigit()
                    .foregroundStyle(game.ledger.summary.netResult < 0 ? .red : .primary)
            }
        }
        .frame(minWidth: 220, maxWidth: .infinity, alignment: .leading)
    }
}

/// One strategy setting. Saved on Return or when the field loses focus, not on every keystroke.
private struct ParameterField: View {
    @Environment(GameViewModel.self) private var game
    let parameter: StrategyParameter
    @State private var text = ""
    @FocusState private var isFocused: Bool

    private var stored: String { game.strategySettings.parameters[parameter.key] ?? "" }

    var body: some View {
        TextField(
            parameter.title,
            text: $text,
            prompt: Text(parameter.defaultValue.isEmpty ? "Off" : parameter.defaultValue)
        )
        .focused($isFocused)
        .help(parameter.help)
        .onSubmit(save)
        .onAppear { text = stored }
        .onChange(of: isFocused) { _, focused in
            if !focused { save() }
        }
        .onChange(of: stored) { _, value in
            if !isFocused { text = value }
        }
    }

    private func save() {
        game.setParameter(parameter.key, to: text)
    }
}
