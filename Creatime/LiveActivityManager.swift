import ActivityKit
import Foundation
import Observation

// MARK: - Live-Activity-Manager
//
// Hält die Brücke zwischen Haupt-App und der Dynamic Island. Wird
// zentral im `CreatimeApp` initialisiert und kann sowohl auf
// Scene-Phase-Übergänge als auch auf Daten-Änderungen (Streak, Wasser)
// reagieren.
//
// Kernaufgaben:
//   • **Nicht** bei jedem `startOrUpdate(...)` eine neue Activity
//     erzeugen — das würde die Dynamic Island zumüllen. Stattdessen
//     merken wir uns die aktive Activity in `current` und ruft bei
//     Folge-Calls nur `.update(...)` darauf.
//   • Orphan-Activities aufräumen (z. B. wenn der User die App per
//     Force-Kill schließt, während eine Activity läuft).
//   • Auf nicht-verfügbare Live-Activities (z. B. User ausgeschaltet,
//     oder iPad) gracefully mit No-Op reagieren.

@MainActor
@Observable
final class LiveActivityManager {

    /// Shared-Instanz: das Lifecycle-Ding existiert nur einmal pro App-Run.
    static let shared = LiveActivityManager()
    private init() {}

    /// Verweis auf die aktuell laufende Activity. Solange diese nicht nil
    /// ist, ist unsere Live-Stelle mit der Dynamic Island verbunden.
    /// Auch `@Observable`, weil ContentViews darauf gucken, um z. B. ein
    /// „running"-Badge im SettingsView anzuzeigen.
    private(set) var current: Activity<CreatimeActivityAttributes>?

    /// Ist die Live-Activity-API überhaupt verfügbar? Auf iPad gibt's
    /// ActivityKit nicht in dieser Form, und User können es in den
    /// System-Settings abschalten.
    var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // MARK: - Updates

    /// Idempotenter Hauptpfad:
    /// • Wenn `current` läuft: ruft `Activity.update(...)` darauf
    /// • Wenn nicht: startet eine neue, falls die API verfügbar ist
    /// • Räumt vorher etwaige Orphan-Activities auf (vorherige Runs)
    ///
    /// Bewusst `async`: Activity.request läuft asynchron und braucht
    /// `await` (auch wenn's sofort resolved).
    func startOrUpdate(
        streak: Int,
        waterML: Int,
        waterGoalML: Int,
        creatineTaken: Bool
    ) async {
        guard isAvailable else {
            // Live Activities global deaktiviert → still ignorieren.
            return
        }

        // 1. Erstmal aufräumen — falls eine vorige App-Run noch eine
        //    Activity offen hat (sehr selten, aber möglich, wenn die
        //    App extrem abrupt beendet wurde).
        await endOrphans(except: current?.id)

        // 2. Neuen State im SharedDefaults-Style serialisieren.
        let state = CreatimeActivityAttributes.ContentState(
            streak: streak,
            waterML: waterML,
            waterGoalML: waterGoalML,
            creatineTaken: creatineTaken
        )
        let content = ActivityContent(state: state, staleDate: nil)

        // 3. Pfad A: bereits aktiv → Update senden.
        if let running = current {
            await running.update(content)
            return
        }

        // 4. Pfad B: neu starten.
        do {
            let activity = try Activity<CreatimeActivityAttributes>.request(
                attributes: CreatimeActivityAttributes(),
                content: content,
                pushType: nil    // pushType = nil → keine APNs, reine In-App-Updates (für v1 OK)
            )
            current = activity
        } catch {
            // Häufigste Ursache: User hat Global-Rechte gekippt.
            // Wir loggen aber geben kein UI-Feedback — der User sieht
            // sowieso nichts in der Dynamic Island, falls es nicht klappt.
            print("LiveActivity request failed: \(error)")
        }
    }

    /// Entfernt die aktuelle (und alle orphan-) Activities. Wird
    /// gerufen, wenn die App in den Hintergrund geht.
    func end() async {
        await endOrphans(except: nil)
        current = nil
    }

    /// Beendet alle Aktivitäten außer der angegebenen. `keep` ist die
    /// Activity-ID, die wir behalten wollen — typischerweise `current?.id`,
    /// oder `nil` wenn wir **alle** beenden wollen (End-of-Life).
    private func endOrphans(except keep: String?) async {
        let running = Activity<CreatimeActivityAttributes>.activities
        for activity in running where activity.id != keep {
            await activity.end(nil, dismissalPolicy: .immediate)
            // Wenn „current" auf eine gerade beendete Activity zeigte,
            // freigeben — sonst hängt unsere Ref in der Luft und beim
            // nächsten .update(...) kracht's.
            if current?.id == activity.id {
                current = nil
            }
        }
    }
}
