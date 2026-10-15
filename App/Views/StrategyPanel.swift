import SwiftUI
import AppKit

/// Strategy settings in the original's order: strategy and bet, win condition, loss condition,
/// stop rules, consecutive wins and losses, dummy bet, and Start / Stop Auto Bet.
/// Win and loss conditions show what the strategy does; only its settings can be changed.
struct StrategyPanel: View {
    @Environment(GameViewModel.self) private var game

    var body: some View {
        let id = game.strategyID
        let rules = StrategyRules.of(id)
        let parameters = StrategyRegistry.parameters(for: id)
        let own = parameters.filter { !StrategyParameter.sessionRules.contains($0) }
        let hasBetOnSetting = own.contains { Self.betOnKeys.contains($0.key) }
        let betParameters = own.filter { !rules.lossParameterKeys.contains($0.key) }
        let lossParameters = own.filter { rules.lossParameterKeys.contains($0.key) }

        VStack(alignment: .leading, spacing: 10) {
            section("Strategy", color: .orange) {
                HStack {
                    Picker("Strategy", selection: Binding(get: { game.strategyID }, set: { game.setStrategy($0) })) {
                        ForEach(StrategyRegistry.all, id: \.self) { id in
                            Text(StrategyRegistry.isImplemented(id) ? id.title : "\(id.title) (pending)")
                                .tag(id)
                        }
                    }
                    // Settings save on their own; Update also saves the field being typed in.
                    Button("Update") { NSApp.keyWindow?.makeFirstResponder(nil) }
                        .help("Save the setting you are typing in now.")
                }
                ForEach(rulesIn([.ruleSequence], of: parameters), id: \.key) { ParameterField(parameter: $0) }
                if !hasBetOnSetting {
                    LabeledContent("Bet On", value: rules.betOn)
                }
                ForEach(betParameters, id: \.key) { ParameterField(parameter: $0) }
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
            }

            section("Win condition", color: .cyan) {
                LabeledContent("Bet On", value: rules.win.betOn)
                LabeledContent("Amount", value: rules.win.amount)
            }

            section("Loss condition", color: .cyan) {
                LabeledContent("Bet On", value: rules.loss.betOn)
                LabeledContent("Amount", value: rules.loss.amount)
                ForEach(lossParameters, id: \.key) { ParameterField(parameter: $0) }
            }

            section("Stop rules", color: .orange) {
                ForEach(rulesIn(StrategyParameter.moneyRules, of: parameters), id: \.key) { ParameterField(parameter: $0) }
            }

            section("Consecutive wins", color: .green) {
                ForEach(rulesIn(StrategyParameter.winRules, of: parameters), id: \.key) { ParameterField(parameter: $0) }
            }

            section("Consecutive losses", color: .red) {
                ForEach(rulesIn(StrategyParameter.lossRules, of: parameters), id: \.key) { ParameterField(parameter: $0) }
            }

            section("Dummy bet", color: .secondary) {
                Text("To prevent the game from pausing when inactive, place a dummy bet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(rulesIn(StrategyParameter.dummyRules, of: parameters), id: \.key) { ParameterField(parameter: $0) }
            }

            Button(action: game.toggleAutoBet) {
                Text(game.autoBetRunning ? "STOP AUTO BET" : "START AUTO BET")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .tint(game.autoBetRunning ? .red : .green)
            .help(game.autoBetRunning
                  ? "Stop betting: new results are recorded without a bet."
                  : "Start betting again from the next hand.")
        }
    }

    /// Settings that choose the side, shown as the strategy's Bet On.
    private static let betOnKeys: Set<String> = ["firstSide", "sides", "oddSide"]

    private func rulesIn(_ group: [StrategyParameter], of parameters: [StrategyParameter]) -> [StrategyParameter] {
        group.filter { parameters.contains($0) }
    }

    private func section<Content: View>(
        _ title: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GroupBox {
            Form { content() }
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(color)
        }
    }
}

/// One strategy setting: a menu when it has fixed choices, otherwise a text field that saves on
/// Return or when it loses focus, not on every keystroke.
private struct ParameterField: View {
    @Environment(GameViewModel.self) private var game
    let parameter: StrategyParameter
    @State private var text = ""
    @FocusState private var isFocused: Bool

    private var stored: String { game.strategySettings.parameters[parameter.key] ?? "" }

    var body: some View {
        if parameter.choices.isEmpty {
            textField
        } else {
            Picker(parameter.title, selection: Binding(
                get: { parameter.choices.contains(stored) ? stored : parameter.defaultValue },
                set: { game.setParameter(parameter.key, to: $0) }
            )) {
                ForEach(parameter.choices, id: \.self) { Text($0).tag($0) }
            }
            .help(parameter.help)
        }
    }

    private var textField: some View {
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
