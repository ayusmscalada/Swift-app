import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @Environment(GameViewModel.self) private var game

    var body: some View {
        @Bindable var game = game

        NavigationSplitView {
            SessionListView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 240)
        } detail: {
            if game.session != nil {
                SessionDetailView()
            } else {
                ContentUnavailableView {
                    Label("No Session", systemImage: "rectangle.stack")
                } description: {
                    Text("Create a session to start entering results.")
                } actions: {
                    Button("New Session") { game.newSession() }
                }
            }
        }
        .fileImporter(
            isPresented: $game.isImportingSequence,
            allowedContentTypes: [.plainText, .commaSeparatedText, .text]
        ) { result in
            if case .success(let url) = result { game.importSequence(from: url) }
        }
        .sheet(isPresented: $game.isShowingReport) {
            ReportView()
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { game.errorMessage != nil },
                set: { if !$0 { game.errorMessage = nil } }
            )
        ) {
            Button("OK") { game.errorMessage = nil }
        } message: {
            Text(game.errorMessage ?? "")
        }
    }
}
