import SwiftUI
import UniformTypeIdentifiers

struct SessionListView: View {
    @Environment(GameViewModel.self) private var game
    @State private var renamingID: Int64?
    @State private var renameText = ""

    var body: some View {
        @Bindable var game = game

        List(selection: Binding(get: { game.selectedSessionID }, set: { game.select($0) })) {
            ForEach(game.sessions) { session in
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.name)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(session.strategy.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .help(session.name)
                .tag(session.id)
                .contextMenu {
                    if let id = session.id {
                        Button("Rename…") {
                            renameText = session.name
                            renamingID = id
                        }
                        Button("Duplicate") { game.duplicate(id) }
                        Divider()
                        Button("Delete", role: .destructive) { game.delete(id) }
                    }
                }
            }
        }
        // Sidebar style keeps the first row below the toolbar; the list scrolls when it is full.
        .listStyle(.sidebar)
        .contentMargins(.top, 8, for: .scrollContent)
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItem {
                Button { game.newSession() } label: {
                    Label("New Session", systemImage: "plus")
                }
            }
        }
        .alert("Rename Session", isPresented: Binding(get: { renamingID != nil }, set: { if !$0 { renamingID = nil } })) {
            TextField("Name", text: $renameText)
            Button("Rename") {
                if let id = renamingID { game.rename(id, to: renameText) }
                renamingID = nil
            }
            Button("Cancel", role: .cancel) { renamingID = nil }
        }
        .fileImporter(
            isPresented: $game.isInspectingLegacyFiles,
            allowedContentTypes: [.data],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result { game.inspectLegacyFiles(urls) }
        }
        .sheet(isPresented: Binding(get: { !game.legacyReports.isEmpty }, set: { if !$0 { game.legacyReports = [] } })) {
            LegacyInspectorView(reports: game.legacyReports)
        }
    }
}
