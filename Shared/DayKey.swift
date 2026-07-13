import Foundation

// Ein kleiner Helfer, der einen Tag als Text wie "2026-07-12" liefert.
// Warum als Text? @AppStorage kann nur einfache Typen (String, Int, Bool ...)
// speichern — und zwei solche Strings lassen sich super einfach vergleichen,
// um zu prüfen: "Ist der gespeicherte Tag heute? Oder gestern?"
enum DayKey {

    // DateFormatter ist teuer in der Erstellung, deshalb legen wir ihn
    // einmalig als statische Konstante an (das ist ein gängiges Muster).
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        // Wichtig bei festen Formaten: en_US_POSIX verhindert, dass regionale
        // Kalender-Einstellungen (z.B. islamischer Kalender) das Format verändern.
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// Der heutige Tag als "yyyy-MM-dd".
    static var today: String {
        formatter.string(from: Date())
    }

    /// Der gestrige Tag als "yyyy-MM-dd".
    static var yesterday: String {
        let gestern = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return formatter.string(from: gestern)
    }

    /// Beliebiges Datum → "yyyy-MM-dd".
    static func string(for date: Date) -> String {
        formatter.string(from: date)
    }

    /// "yyyy-MM-dd" → Datum (nil, falls der Text kein gültiges Datum ist).
    static func date(from string: String) -> Date? {
        formatter.date(from: string)
    }
}
