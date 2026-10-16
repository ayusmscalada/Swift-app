import SwiftUI
import UniformTypeIdentifiers

struct SessionListView: View {
    @Environment(GameViewModel.self) private var game
    @State private var renamingID: Int64?
    @State private var renameText = ""

    private var selection: Binding<Int64?> {
        Binding(get: { game.selectedSessionID }, set: { game.select($0) })
    }

    private var isRenaming: Binding<Bool> {
        Binding(get: { renamingID != nil }, set: { if !$0 { renamingID = nil } })
    }

    private var isShowingLegacyReports: Binding<Bool> {
        Binding(get: { !game.legacyReports.isEmpty }, set: { if !$0 { game.legacyReports = [] } })
    }

    var body: some View {
        @Bindable var game = game

        List(selection: selection) {
            ForEach(game.sessions) { session in
                SessionRow(session: session, onRename: beginRename)
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
        .alert("Rename Session", isPresented: isRenaming) {
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
        .sheet(isPresented: isShowingLegacyReports) {
            LegacyInspectorView(reports: game.legacyReports)
        }
    }

    private func beginRename(_ session: SessionRecord) {
        renameText = session.name
        renamingID = session.id
    }
}

/// One session in the sidebar: its name and strategy, with a right-click menu.
private struct SessionRow: View {
    @Environment(GameViewModel.self) private var game
    let session: SessionRecord
    let onRename: (SessionRecord) -> Void

    var body: some View {
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
        // A fixed vertical size and a minimum height let a newly inserted row measure
        // itself at once; without them the new row first appears at half height.
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 36, maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .help(session.name)
        .tag(session.id)
        .contextMenu {
            if let id = session.id {
                Button("Rename…") { onRename(session) }
                Button("Duplicate") { game.duplicate(id) }
                Divider()
                Button("Delete", role: .destructive) { game.delete(id) }
            }
        }
    }
}
