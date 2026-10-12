import Foundation
import BaccaratDomain

/// Turns a roads snapshot into drawn grid cells for the roadmap views.
struct RoadmapViewModel {
    let snapshot: RoadmapSnapshot
    let bigRoadRows: Int

    var beadPlate: [PlacedCell<Hand>] {
        RoadLayout.beadPlate(snapshot.history)
    }

    var bigRoad: [PlacedCell<BigRoadEntry>] {
        RoadLayout.place(snapshot.bigRoad.columns, rows: bigRoadRows)
    }

    var leadingTies: Int { snapshot.bigRoad.leadingTies }

    func derived(_ kind: DerivedRoadKind) -> [PlacedCell<RoadColor>] {
        RoadLayout.place(snapshot.derived(kind).columns, rows: 6)
    }

    /// Ask predictions for the next Banker and Player result.
    var askBanker: [DerivedRoadKind: RoadColor] { RoadmapEngine.ask(.banker, after: snapshot.history) }
    var askPlayer: [DerivedRoadKind: RoadColor] { RoadmapEngine.ask(.player, after: snapshot.history) }
}
