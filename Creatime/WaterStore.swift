import Foundation
import Observation
import WidgetKit

// Der Wasser-Store: gleiches Muster wie CreatineStore, aber statt
// "Tag genommen: ja/nein" speichern wir hier PRO TAG EINE MENGE (in ml).
// Ein Dictionary ist dafür perfekt: ["2026-07-12": 1500, "2026-07-11": 2500]
@Observable
final class WaterStore {

    /// Getrunkene Menge pro Tag in Millilitern.
    private(set) var waterByDay: [String: Int] = [:]

    /// Tagesziel in ml. didSet läuft bei jeder Änderung und speichert sofort.
    /// Anzeige-Modus (ml|glasses|bottles) bestimmt, wie die Quick-Amounts
    /// umgerechnet werden.
    var dailyGoal: Int {
        didSet {
            defaults.set(dailyGoal, forKey: goalKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// Welche Einheit prägt aktuell die UI? Bestimmt, wie liter/glasses/
    /// bottles berechnet werden. Standard: ml (klassisch).
    /// Beim Wechsel auf eine neue Einheit wird dailyGoal auf das
    /// nächste Vielfache von perUnitML gerundet, damit die UI keine
    /// krummen Werte wie 8,5 / 8 Glaeser zeigt.
    var goalMode: GoalMode {
        didSet {
            guard oldValue != goalMode, goalMode.perUnitML > 0 else { return }
            defaults.set(goalMode.rawValue, forKey: goalModeKey)
            let steps = (Double(dailyGoal) / goalMode.perUnitML).rounded()
            dailyGoal = max(Int(goalMode.perUnitML), Int(steps * goalMode.perUnitML))
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// Die Buttons-Größen, die in der Wasser-Karte erscheinen (in ml).
    /// Standard: 250 ml (Glas), 330 ml (Dose), 500 ml (Flasche).
    var quickAmounts: [Int] {
        didSet {
            defaults.set(quickAmounts, forKey: quickAmountsKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// Default-Größen, falls der Nutzer noch keine konfiguriert hat.
    static let defaultQuickAmounts: [Int] = [250, 330, 500]

    private let storageKey = "waterByDay"
    private let goalKey = "waterDailyGoal"
    private let goalModeKey = "waterGoalMode"
    private let quickAmountsKey = "waterQuickAmounts"

    // MARK: - Goal-Modus-Logik
    //
    // Der gleiche dailyGoal-Milliliter-Wert wird je nach `goalMode` zu
    // unterschiedlich vielen Einheiten umgerechnet. „Gläser" gehen von 250
    // ml pro Glas aus (Standard-Haushaltsmaß); „Flaschen" von 500 ml
    // (Standard-Sportflasche). User können dailyGoal in der gewohnten
    // Einheit eingeben — die Funktion rechnet das in ml um.

    enum GoalMode: String, CaseIterable, Identifiable {
        case ml      // klassisch — Anzeige in Litern
        case glasses // 1 Glas = 250 ml
        case bottles // 1 Flasche = 500 ml

        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .ml:      return "Liter"
            case .glasses: return "Gläser"
            case .bottles: return "Flaschen"
            }
        }
        var symbol: String {
            switch self {
            case .ml:      return "drop.fill"
            case .glasses: return "cup.and.saucer.fill"
            case .bottles: return "waterbottle.fill"
            }
        }
        var perUnitML: Double {
            switch self {
            case .ml:      return 1000
            case .glasses: return 250
            case .bottles: return 500
            }
        }

        /// Wieviele ml pro 1 Einheit (z. B. 1 Glas = 250ml).
        /// Default für ml-Modus: 1000 (= Liter).
        func mlToUnits(_ ml: Int) -> Double {
            Double(ml) / perUnitML
        }
        func unitsToML(_ units: Double) -> Int {
            Int((units * perUnitML).rounded())
        }
    }

    /// Gemeinsamer Speicher (App Group) — auch das Widget liest hier.
    private let defaults = SharedDefaults.store

    /// Optional kann ein eigener UserDefaults-Speicher übergeben werden —
    /// praktisch für Unit-Tests, die sich nicht mit dem App-Group-Speicher
    /// oder App-Daten vermischen wollen.
    init(defaults: UserDefaults = SharedDefaults.store) {
        // Daten aus dem alten Standard-Speicher in die App Group umziehen:
        if defaults.dictionary(forKey: storageKey) == nil,
           let old = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Int] {
            defaults.set(old, forKey: storageKey)
        }
        if defaults.integer(forKey: goalKey) == 0,
           UserDefaults.standard.integer(forKey: goalKey) > 0 {
            defaults.set(UserDefaults.standard.integer(forKey: goalKey), forKey: goalKey)
        }

        if let saved = defaults.dictionary(forKey: storageKey) as? [String: Int] {
            waterByDay = saved
        }
        // integer(forKey:) liefert 0, wenn noch nie gespeichert wurde —
        // dann nehmen wir den Standardwert 2,5 Liter.
        let savedGoal = defaults.integer(forKey: goalKey)
        dailyGoal = savedGoal > 0 ? savedGoal : 2500

        // Quick-Amounts: gespeicherte verwenden, sonst Default.
        if let saved = defaults.array(forKey: quickAmountsKey) as? [Int], !saved.isEmpty {
            quickAmounts = saved
        } else {
            quickAmounts = Self.defaultQuickAmounts
        }

        // Goal-Modus: gespeicherten verwenden, sonst „ml" als Default.
        if let raw = defaults.string(forKey: goalModeKey),
           let mode = GoalMode(rawValue: raw) {
            goalMode = mode
        } else {
            goalMode = .ml
        }
    }

    private func save() {
        defaults.set(waterByDay, forKey: storageKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Aktionen

    /// Menge für heute ändern. Auch für Minus geeignet (z.B. addToday(-250)),
    /// max(0, ...) verhindert negative Werte.
    func addToday(_ ml: Int) {
        waterByDay[DayKey.today] = max(0, todayAmount + ml)
        save()
    }

    // MARK: - Abfragen

    var todayAmount: Int {
        waterByDay[DayKey.today] ?? 0
    }

    func amount(on date: Date) -> Int {
        waterByDay[DayKey.string(for: date)] ?? 0
    }

    /// Fortschritt Richtung Tagesziel als Wert von 0.0 bis 1.0 (für den Balken).
    var todayProgress: Double {
        min(1.0, Double(todayAmount) / Double(dailyGoal))
    }

    var goalReachedToday: Bool {
        todayAmount >= dailyGoal
    }

    /// Heute getrunkene Menge, ausgedrückt in `goalMode`-Einheiten
    /// (z. B. „3.5 Gläser" oder „1.2 Flaschen"). Wird in der UI angezeigt.
    var todayAmountInUnits: Double {
        goalMode.mlToUnits(todayAmount)
    }

    /// Tagesziel ausgedrückt in `goalMode`-Einheiten.
    var dailyGoalInUnits: Double {
        goalMode.mlToUnits(dailyGoal)
    }

    /// Durchschnittlich getrunkene Menge der letzten 7 Tage in ml.
    var weeklyAverage: Int {
        let calendar = Calendar.current
        let total = (0..<7).reduce(0) { sum, offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return sum }
            return sum + amount(on: day)
        }
        return total / 7
    }

    // MARK: - Wochenvergleich (delegiert an MetricsCalculator)
    //
    // „Diese Woche" und „letzte Woche" laufen Mo–So (ISO-8601). So kann
    // man z.B. sehen, ob man in dieser Woche mehr trinkt als letzte.

    /// Durchschnitt dieser Kalenderwoche in ml (Mo–So).
    var thisWeekAverageML: Int {
        MetricsCalculator.thisWeekWaterAverage(waterByDay: waterByDay)
    }

    /// Durchschnitt der vorigen Kalenderwoche in ml.
    var lastWeekAverageML: Int {
        MetricsCalculator.lastWeekWaterAverage(waterByDay: waterByDay)
    }

    /// Veränderung gegenüber letzter Woche als Bruch (z.B. +0.15 = +15 %).
    /// Gibt `nil` zurück, wenn die Vorwoche 0 ml hatte (Division unmöglich).
    var weekOverWeekDelta: Double? {
        MetricsCalculator.weekOverWeekDelta(waterByDay: waterByDay)
    }

    /// Menschenlesbares Delta: „+15 %" / „−5 %" / „±0 %" / „neu".
    var weekOverWeekText: String {
        guard let delta = weekOverWeekDelta else { return "neu" }
        let pct = Int((delta * 100).rounded())
        if pct == 0 { return "±0 %" }
        return pct > 0 ? "+\(pct) %" : "\(pct) %"
    }
}
