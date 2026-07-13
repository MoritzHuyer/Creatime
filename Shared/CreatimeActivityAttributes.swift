import Foundation
import ActivityKit

// MARK: - ActivityAttributes für Creatime Live Activity
//
// Diese Struct muss in `Shared/` liegen, weil SIE aus zwei Targets
// heraus referenziert wird:
//   • `Creatime` (Haupt-App): ruft `Activity<CreatimeActivityAttributes>.request(...)`
//   • `CreatimeWidget` (Widget Extension): rendert die Live-Activity-UI
//
// `ActivityAttributes` ist das iOS-16.1+ Protokoll, das ActivityKit
// erwartet. Es hat zwei Teile:
//
//   • `ContentState`: alle FELDER, die sich WÄHREND der Laufzeit
//     ändern können (Streak, Wasser) — werden in `Activity.update(...)`
//     neu übergeben und triggern eine UI-Aktualisierung im Widget.
//
//   • der Rest der Struct: alles, was währEND der gesamten Laufzeit
//     der Activity STABIL bleibt (Startzeit). Seltene Updates möglich,
//     aktualisieren aber nicht das UI.

struct CreatimeActivityAttributes: ActivityAttributes {

    /// Mutable Per-Update-State. Wird vom Haupt-Process in einen
    /// serialisierbaren Container verpackt und im Widget-Prozess wieder
    /// deserialisiert. **MUSS** `Codable & Hashable` sein.
    public struct ContentState: Codable, Hashable {
        public var streak: Int
        public var waterML: Int
        public var waterGoalML: Int
        public var creatineTaken: Bool

        public init(streak: Int, waterML: Int, waterGoalML: Int, creatineTaken: Bool) {
            self.streak = streak
            self.waterML = waterML
            self.waterGoalML = waterGoalML
            self.creatineTaken = creatineTaken
        }
    }

    /// Stabiler Teil der Activity. Aktuell nur `startedAt` — könnte
    /// später z. B. das Wasserziel enthalten (das ändert sich nicht
    /// mitten in einer Activity).
    public var startedAt: Date

    public init(startedAt: Date = Date()) {
        self.startedAt = startedAt
    }
}
