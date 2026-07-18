import SwiftUI

// Geteilte Theme-Akzentfarbe für App UND Widget.
//
// Problem: `AppTheme`/`ThemeManager` (mit den Hex-Farben) leben nur im
// App-Target — das Widget ist ein eigener Prozess und kcommt da nicht ran.
// Diese Datei liegt im `Shared/`-Ordner (beide Targets) und liefert die
// Akzentfarbe allein aus dem in der App Group gespeicherten Theme-Namen.
//
// Die Hex-Werte sind bewusst identisch zu `AppTheme.lightHex/darkHex` —
// bei Änderungen dort bitte hier mitziehen.

enum ThemeAccent {

    /// Liefert die Akzentfarbe zu einem gespeicherten Theme-Namen
    /// ("indigo", "teal", …). Fällt auf Indigo zurück, wenn unbekannt/nil.
    static func color(forRawValue raw: String?, dark: Bool) -> Color {
        let key = raw ?? "indigo"
        let hex = (dark ? darkHex[key] : lightHex[key])
            ?? (dark ? "#7B79FF" : "#5856E8")
        return Color(sharedHex: hex)
    }

    private static let lightHex: [String: String] = [
        "indigo":  "#5856E8",
        "teal":    "#1FA8A8",
        "magenta": "#B83C9C",
        "sunset":  "#E8774F",
        "ocean":   "#2176AE",
    ]

    private static let darkHex: [String: String] = [
        "indigo":  "#7B79FF",
        "teal":    "#3FC9C9",
        "magenta": "#E55CB6",
        "sunset":  "#FF9B70",
        "ocean":   "#4DA3D8",
    ]
}

extension Color {
    /// Eigener Hex-Initializer für das Shared-Modul. Bewusst NICHT
    /// `init(hex:)` genannt, damit es nicht mit dem gleichnamigen
    /// Initializer im App-Target kollidiert (Doppel-Definition).
    init(sharedHex: String) {
        let s = sharedHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
