import AppIntents
import Foundation
import WidgetKit

// MARK: - App-Intent: Kreatin-Einnahme per Widget markieren
//
// WICHTIG: Diese Datei liegt im **Shared/-Ordner** und ist damit in BEIDEN
// Targets (Creatime-App + CreatimeWidget) sichtbar. iOS 17 `AppIntentTimelineProvider`
// verlangt, dass das Intent aus dem Widget kompiliert wird.
//
// Bewusste Design-Entscheidung:
//   • Das Intent ruft KEINEN `AppBadgeManager.setBadge()` auf, weil dieser
//     App-Only ist. App-Badge ist eine App-Icon-Funktion und macht im
//     Widget-Kontext ohnehin keinen Sinn.
//   • Das Intent ruft `WidgetCenter.shared.reloadAllTimelines()` — das
//     IST in beiden Targets verfügbar — damit nach dem Mark-Speichern
//     alle Widgets (Home-Screen + Lock-Screen + StandBy + LiveActivity)
//     sich selbst neu zeichnen.
//
// Beim nächsten App-Start synchronisiert `CreatineStore.reload()` die
// Werte aus dem App-Group-Speicher; AppBadgeManager.setBadge wird aus
// der Save-Funktion aufgerufen.

struct MarkCreatineTakenIntent: WidgetConfigurationIntent {

    static var title: LocalizedStringResource = "Kreatin als genommen markieren"

    static var description: IntentDescription = IntentDescription(
        "Speichert deine heutige Kreatin-Einnahme direkt, ohne die App zu öffnen. Funktioniert auch aus dem Sperrbildschirm, dem Home-Screen-Widget und über die Apple-Watch.",
        categoryName: "Tracking"
    )

    /// Hintergrund-Modus: die App wird NICHT geöffnet. Der Nutzer bleibt
    /// in dem Kontext, in dem er gerade ist (Widget, Lock-Screen, Siri).
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = SharedDefaults.store

        // Aktuellen Stand aus dem App-Group-Speicher holen.
        var takenDays = Set(defaults.stringArray(forKey: "takenDays") ?? [])
        let skippedDays = Set(defaults.stringArray(forKey: "skippedDays") ?? [])
        let frozenDays = Set(defaults.stringArray(forKey: "frozenDays") ?? [])

        let didInsert = !takenDays.contains(DayKey.today)
        if didInsert {
            takenDays.insert(DayKey.today)

            // Einnahme-Zeit tracken (für Smart-Reminder-Heuristik).
            var intakeTimes = defaults.dictionary(forKey: "intakeTimesByDay") as? [String: Int] ?? [:]
            let hour = Calendar.current.component(.hour, from: Date())
            intakeTimes[DayKey.today] = hour
            defaults.set(intakeTimes, forKey: "intakeTimesByDay")

            defaults.set(Array(takenDays).sorted(), forKey: "takenDays")
        }

        // Streak mit der gleichen Logik wie die App/Widget berechnen.
        let streak = StreakCalculator.currentStreak(
            takenDays: takenDays,
            skippedDays: skippedDays,
            frozenDays: frozenDays
        )

        // NEU: schreibt zusätzlich die neue Streak in eine spezielle
        // Widget-Sync-Variable, die auch im on-brand Splash genutzt wird.
        defaults.set(streak, forKey: "lastKnownStreak")

        // Widget-Zeitleiste neu zeichnen — das ist die EINZIGE Live-Sync
        // Möglichkeit aus dem Widget-/Background-Kontext.
        WidgetCenter.shared.reloadAllTimelines()

        let spokenText: String = didInsert
            ? "Top, Kreatin für heute gespeichert. Deine Streak ist jetzt \(streak) Tage. Bleib dran!"
            : "Du hattest heute schon eingetragen — Streak bleibt bei \(streak) Tagen."

        return .result(dialog: IntentDialog(stringLiteral: spokenText))
    }
}
