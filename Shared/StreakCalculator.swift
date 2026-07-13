import Foundation

// Die Streak-Berechnung als eigenständige Funktion — ausgelagert,
// damit App UND Widget exakt dieselbe Logik verwenden und die Zahlen
// garantiert übereinstimmen.
enum StreakCalculator {

    /// Aktuelle Streak, optional mit „Pausen-Tagen" und „Frozen-Tagen".
    ///
    /// Regeln:
    /// - Wenn heute genommen → ab heute rückwärts zählen.
    /// - Wenn heute nur „übersprungen" ODER „frozen" → auch ab heute, aber
    ///   diese Tage werden in der Streak **nicht** mitgezählt (kein +1).
    /// - Wenn heute weder genommen noch übersprungen noch frozen → ab gestern rückwärts.
    /// - Sobald ein Tag weder in `takenDays` noch in `skippedDays` noch
    ///   in `frozenDays` liegt, ist die Kette zu Ende → Abbruch.
    ///
    /// Frozen-Tage sind semantisch identisch zu Skipped (Streak-Schutz,
    /// kein +1) — aber werden separat getrackt, damit UI sie als ❄️
    /// statt ⏸ rendert und ein monatliches Limit (Freeze-System)
    /// hochgezählt werden kann.
    ///
    /// Bleibt rückwärtskompatibel: ohne `skippedDays` und ohne `frozenDays`
    /// verhält sich die Funktion exakt wie vorher.
    static func currentStreak(
        takenDays: Set<String>,
        skippedDays: Set<String> = [],
        frozenDays: Set<String> = []
    ) -> Int {
        let calendar = Calendar.current
        let takenToday = takenDays.contains(DayKey.today)
        let pausedToday = skippedDays.contains(DayKey.today) || frozenDays.contains(DayKey.today)

        // Wir brauchen `var day`, weil die Schleife weiter unten `day = previous`
        // macht. Ein einfaches if/else vermeidet den „guard var X = Non-Optional"
        // Compile-Fehler (Ternäre ohne Nil-Zweig ist `T`, nicht `T?`).
        var day: Date
        if takenToday || pausedToday {
            day = Date()
        } else {
            day = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        }

        var count = 0
        while takenDays.contains(DayKey.string(for: day))
                || skippedDays.contains(DayKey.string(for: day))
                || frozenDays.contains(DayKey.string(for: day)) {
            if takenDays.contains(DayKey.string(for: day)) {
                count += 1
            }
            // skipped + frozen tragen NICHTS zur Streak-Zahl bei — nur
            // zur „Kette bleibt erhalten"-Garantie. Daher kein count += 1
            // in diesen beiden Fällen.
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else {
                break
            }
            day = previous
        }
        return count
    }
}
