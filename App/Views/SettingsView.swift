import SwiftUI
import BaccaratDomain

/// App-wide settings. More options are added as they are found in the original's
/// configuration files and settings screens, with the same defaults.
struct SettingsView: View {
    @Environment(GameViewModel.self) private var game
    @State private var rules = PayoutRules.standard
    @State private var rows = 6

    var body: some View {
        TabView {
            Form {
                TextField("Banker win per unit", value: $rules.bankerWin, format: .number)
                TextField("Player win per unit", value: $rules.playerWin, format: .number)
                TextField("Tie win per unit", value: $rules.tieWin, format: .number)
                Toggle("Tie returns Banker and Player stakes", isOn: $rules.tieRefundsMainBets)
                Stepper("Round to \(rules.roundingScale) decimal places", value: $rules.roundingScale, in: 0...4)
                HStack {
                    Button("Restore Standard") { rules = .standard }
                    Spacer()
                    Button("Save") { game.savePayouts(rules) }
                        .keyboardShortcut(.defaultAction)
                        .disabled(rules == game.payouts)
                }
            }
            .tabItem { Label("Payouts", systemImage: "dollarsign.circle") }

            Form {
                Stepper("Big Road rows: \(rows)", value: $rows, in: 3...12)
                    .onChange(of: rows) { _, newValue in game.setBigRoadRows(newValue) }
            }
            .tabItem { Label("Display", systemImage: "square.grid.3x3") }
        }
        .padding(20)
        .frame(width: 460)
        .onAppear {
            rules = game.payouts
            rows = game.bigRoadRows
        }
    }
}
