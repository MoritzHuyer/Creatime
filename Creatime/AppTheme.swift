import SwiftUI
import WidgetKit

// MARK: - Theme-System
//
// Creatime hat 5 feste Themes. Der User wählt in Settings → das Ergebnis
// landet in @AppStorage("themeRaw") und wird über `ThemeManager` (ein
// Singleton @Observable) an die Views verteilt.
//
// Bewusst NICHT `Color.accentColor`: das ist ein SYSTEM-Level-Wert,
// pro-App-Overrides brauchen ein eigenes Tint-System. Wir setzen daher
// `.tint(themeManager.tint)` an der Wurzel und alle `Color.accentColor`-
// Aufrufe folgen automatisch dem Theme.
//
// Wichtig: Die `primary`-Farbe muss ≥ 4,5 : 1 Kontrast zum Background
// haben — Light- und Dark-Mode werden über `Color.dynamic(...)` gehandhabt
// (zwei Varianten pro Theme).

enum AppTheme: String, CaseIterable, Identifiable {
    case indigo
    case teal
    case magenta
    case sunset
    case ocean

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .indigo:  return "Indigo"
        case .teal:    return "Teal"
        case .magenta: return "Magenta"
        case .sunset:  return "Sunset"
        case .ocean:   return "Ocean"
        }
    }

    /// Symbolisches Icon für den Theme-Picker.
    var symbol: String {
        switch self {
        case .indigo:  return "paintbrush.fill"
        case .teal:    return "leaf.fill"
        case .magenta: return "sparkles"
        case .sunset:  return "sun.horizon.fill"
        case .ocean:   return "water.waves"
        }
    }

    /// Akzentfarbe für LIGHT mode (großzügig Sättigung).
    var lightHex: String {
        switch self {
        case .indigo:  return "#5856E8"
        case .teal:    return "#1FA8A8"
        case .magenta: return "#B83C9C"
        case .sunset:  return "#E8774F"
        case .ocean:   return "#2176AE"
        }
    }

    /// Akzentfarbe für DARK mode (etwas heller, damit sie auf dunklem
    /// Material sichtbar bleibt).
    var darkHex: String {
        switch self {
        case .indigo:  return "#7B79FF"
        case .teal:    return "#3FC9C9"
        case .magenta: return "#E55CB6"
        case .sunset:  return "#FF9B70"
        case .ocean:   return "#4DA3D8"
        }
    }

    /// Paar von Light/Dark Farben — als dynamic Color.
    var primary: Color {
        Color(lightHex: lightHex, darkHex: darkHex)
    }
}

// MARK: - ThemeManager (Singleton)
//
// @Observable + statisches `shared`. Alle Views lesen `.tint` und folgen
// automatisch dem aktuellen Theme.

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    /// Aktuelles Theme — gebunden an @AppStorage in der App.
    /// Wir spiegeln den Wert hier rein, damit andere Subsystems
    /// (z. B. der Long-Press QuickAction-Handler, der die App
    /// ggf. neu zeichnen muss) den Wert synchron lesen können.
    private(set) var theme: AppTheme = .indigo {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
            // Zusätzlich in die App Group spiegeln, damit das Widget
            // (eigener Prozess) die gewählte Akzentfarbe übernehmen kann.
            SharedDefaults.store.set(theme.rawValue, forKey: themeKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private let themeKey = "themeRaw"

    init() {
        if let raw = UserDefaults.standard.string(forKey: themeKey),
           let t = AppTheme(rawValue: raw) {
            self.theme = t
        }
        // Beim Start einmal in die App Group spiegeln (falls noch nie gesetzt).
        SharedDefaults.store.set(theme.rawValue, forKey: themeKey)
    }

    /// Wechsel direkt (z.B. aus Settings-Picker).
    func setTheme(_ theme: AppTheme) {
        self.theme = theme
    }

    /// Tint-Color für den Root-View (`ContentView.tint(...)`).
    var tint: Color { theme.primary }
}

// MARK: - Color(hex:) Initializers

extension Color {
    /// Erzeugt eine Color aus einem Hex-String wie "#5856E8" oder
    /// "5856E8". Unterstützt 6-stellige RGB-Hex-Codes.
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&int)
        let r, g, b: UInt64
        switch trimmed.count {
        case 6:
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        default:
            r = 128; g = 128; b = 128   // Fallback-Grau bei kaputtem Hex
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: 1
        )
    }

    /// Erzeugt eine Color, die je nach Light/Dark mode ihren Hex-Wert
    /// wechselt. SwiftUI löst das automatisch auf.
    init(lightHex: String, darkHex: String) {
        #if os(iOS)
        self = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: darkHex)
                : UIColor(hex: lightHex)
        })
        #else
        self = Color(hex: lightHex)
        #endif
    }
}

extension UIColor {
    convenience init(hex: String) {
        let trimmed = hex.replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255.0
        let g = CGFloat((int >> 8) & 0xFF) / 255.0
        let b = CGFloat(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

#Preview("Themes") {
    VStack(spacing: 16) {
        ForEach(AppTheme.allCases) { theme in
            HStack {
                Image(systemName: theme.symbol)
                    .foregroundStyle(theme.primary)
                Text(theme.displayName)
                Spacer()
                Circle()
                    .fill(theme.primary)
                    .frame(width: 32, height: 32)
            }
            .padding()
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
