import Foundation

/// Kalender-Wochen-Schlüssel nach ISO 8601 ("2026-W28") — wird benutzt,
/// um zu zählen, ob in der aktuellen Woche schon eine Pause verbraucht wurde.
///
/// ISO-Wochen starten am Montag und sind international einheitlich, damit
/// sich Nutzer aus verschiedenen Regionen nicht uneinig sind, wann "die Woche"
/// anfängt.
enum WeekKey {

    /// ISO-Woche als "yyyy-Www" für ein gegebenes Datum.
    static func key(for date: Date, calendar: Calendar = Calendar(identifier: .iso8601)) -> String {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = comps.yearForWeekOfYear ?? 0
        let week = comps.weekOfYear ?? 0
        return String(format: "%04d-W%02d", year, week)
    }

    /// Die ISO-Woche für heute.
    static var current: String {
        key(for: Date())
    }
}
