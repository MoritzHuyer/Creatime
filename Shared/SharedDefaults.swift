import Foundation

// App und Widget sind zwei GETRENNTE Programme mit getrennten Speichern.
// Damit beide dieselben Daten sehen, nutzen wir eine "App Group" —
// einen gemeinsamen Speicherbereich, den Apple beiden Programmen erlaubt.
// Die Group-ID hier muss exakt mit der in den .entitlements-Dateien
// (Ordner Config/) übereinstimmen!
enum SharedDefaults {

    static let appGroupID = "group.com.moritz.Creatime"

    /// Der gemeinsame Speicher für App UND Widget.
    /// Fallback auf .standard, falls die App Group nicht verfügbar ist.
    static var store: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
