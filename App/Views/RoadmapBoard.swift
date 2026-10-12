import SwiftUI

/// Bead Plate, Big Road, the three derived roads and the Ask predictions.
/// Sizes, colours and marker styles are to be matched to the original's screenshots.
struct RoadmapBoard: View {
    @Environment(GameViewModel.self) private var game
    /// Roads one under another instead of side by side, for narrow windows.
    var isStacked = false

    var body: some View {
        let roads = RoadmapViewModel(snapshot: game.roads, bigRoadRows: game.bigRoadRows)
        let row = isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))

        GroupBox("Roadmaps") {
            VStack(alignment: .leading, spacing: 8) {
                row {
                    labelled("Bead Plate") { BeadPlateView(cells: roads.beadPlate) }
                        .frame(width: isStacked ? nil : 260)
                    labelled("Big Road") {
                        BigRoadView(cells: roads.bigRoad, leadingTies: roads.leadingTies, rows: roads.bigRoadRows)
                    }
                }
                row {
                    ForEach(DerivedRoadKind.allCases, id: \.self) { kind in
                        labelled(kind.title) { DerivedRoadView(kind: kind, cells: roads.derived(kind)) }
                    }
                    AskView(banker: roads.askBanker, player: roads.askPlayer)
                }
            }
            .padding(4)
        }
    }

    private func labelled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            content()
        }
    }
}

/// A scrollable grid that draws one cell per placed value.
struct RoadGridCanvas<Value>: View {
    let cells: [PlacedCell<Value>]
    let rows: Int
    let cellSize: CGFloat
    var minColumns = 20
    let drawCell: (GraphicsContext, CGRect, PlacedCell<Value>, Int) -> Void

    var body: some View {
        let columns = max((cells.map(\.position.x).max() ?? -1) + 2, minColumns)
        ScrollView(.horizontal) {
            Canvas { context, size in
                var grid = Path()
                for column in 0...columns {
                    let x = CGFloat(column) * cellSize
                    grid.move(to: CGPoint(x: x, y: 0))
                    grid.addLine(to: CGPoint(x: x, y: size.height))
                }
                for row in 0...rows {
                    let y = CGFloat(row) * cellSize
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(.secondary.opacity(0.3)), lineWidth: 0.5)

                for (index, cell) in cells.enumerated() {
                    let rect = CGRect(
                        x: CGFloat(cell.position.x) * cellSize,
                        y: CGFloat(cell.position.y) * cellSize,
                        width: cellSize,
                        height: cellSize
                    )
                    drawCell(context, rect, cell, index)
                }
            }
            .frame(width: CGFloat(columns) * cellSize, height: CGFloat(rows) * cellSize)
        }
        .defaultScrollAnchor(.trailing)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct BeadPlateView: View {
    let cells: [PlacedCell<Hand>]

    var body: some View {
        RoadGridCanvas(cells: cells, rows: 6, cellSize: 22, minColumns: 11) { context, rect, cell, _ in
            let circle = Path(ellipseIn: rect.insetBy(dx: 2, dy: 2))
            context.fill(circle, with: .color(cell.value.outcome.color))
            context.draw(
                Text(cell.value.outcome.rawValue).font(.system(size: 10, weight: .bold)).foregroundColor(.white),
                at: CGPoint(x: rect.midX, y: rect.midY)
            )
            drawPairs(context, rect: rect.insetBy(dx: 2, dy: 2), banker: cell.value.bankerPair, player: cell.value.playerPair)
        }
    }
}

struct BigRoadView: View {
    let cells: [PlacedCell<BigRoadEntry>]
    let leadingTies: Int
    let rows: Int

    var body: some View {
        RoadGridCanvas(cells: cells, rows: rows, cellSize: 20, minColumns: 30) { context, rect, cell, index in
            let entry = cell.value
            let inner = rect.insetBy(dx: 3, dy: 3)
            context.stroke(Path(ellipseIn: inner), with: .color(entry.outcome.color), lineWidth: 2)

            let ties = entry.tiesAfter + (index == 0 ? leadingTies : 0)
            if ties > 0 {
                var slash = Path()
                slash.move(to: CGPoint(x: inner.minX, y: inner.maxY))
                slash.addLine(to: CGPoint(x: inner.maxX, y: inner.minY))
                context.stroke(slash, with: .color(.green), lineWidth: 1.5)
                if ties > 1 {
                    context.draw(
                        Text("\(ties)").font(.system(size: 8, weight: .bold)).foregroundColor(.green),
                        at: CGPoint(x: rect.midX, y: rect.midY)
                    )
                }
            }
            drawPairs(context, rect: inner, banker: entry.bankerPair, player: entry.playerPair)
        }
    }
}

struct DerivedRoadView: View {
    let kind: DerivedRoadKind
    let cells: [PlacedCell<RoadColor>]

    var body: some View {
        RoadGridCanvas(cells: cells, rows: 6, cellSize: 12, minColumns: 18) { context, rect, cell, _ in
            drawDerivedMark(context, kind: kind, color: cell.value, in: rect.insetBy(dx: 2, dy: 2))
        }
    }
}

/// What each derived road would add if the next result were Banker or Player.
struct AskView: View {
    let banker: [DerivedRoadKind: RoadColor]
    let player: [DerivedRoadKind: RoadColor]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ask").font(.caption).foregroundStyle(.secondary)
            row("Banker", color: .red, marks: banker)
            row("Player", color: .blue, marks: player)
        }
        .frame(width: 120, alignment: .leading)
    }

    private func row(_ title: String, color: Color, marks: [DerivedRoadKind: RoadColor]) -> some View {
        HStack(spacing: 6) {
            Text(title).foregroundStyle(color).frame(width: 48, alignment: .leading)
            ForEach(DerivedRoadKind.allCases, id: \.self) { kind in
                Canvas { context, size in
                    if let mark = marks[kind] {
                        drawDerivedMark(context, kind: kind, color: mark, in: CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1))
                    }
                }
                .frame(width: 12, height: 12)
            }
        }
        .font(.caption)
    }
}

/// Big Eye Boy: hollow circle · Small Road: solid dot · Cockroach Pig: slash.
func drawDerivedMark(_ context: GraphicsContext, kind: DerivedRoadKind, color: RoadColor, in rect: CGRect) {
    switch kind {
    case .bigEyeBoy:
        context.stroke(Path(ellipseIn: rect), with: .color(color.color), lineWidth: 1.5)
    case .smallRoad:
        context.fill(Path(ellipseIn: rect), with: .color(color.color))
    case .cockroachPig:
        var slash = Path()
        slash.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        slash.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        context.stroke(slash, with: .color(color.color), lineWidth: 2)
    }
}

/// Pair dots: Banker top-left in red, Player bottom-right in blue.
func drawPairs(_ context: GraphicsContext, rect: CGRect, banker: Bool, player: Bool) {
    let dot: CGFloat = 5
    if banker {
        context.fill(Path(ellipseIn: CGRect(x: rect.minX - 1, y: rect.minY - 1, width: dot, height: dot)), with: .color(.red))
    }
    if player {
        context.fill(
            Path(ellipseIn: CGRect(x: rect.maxX - dot + 1, y: rect.maxY - dot + 1, width: dot, height: dot)),
            with: .color(.blue)
        )
    }
}
