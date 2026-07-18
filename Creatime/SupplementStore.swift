import Foundation
import Observation
import WidgetKit

// MARK: - Supplement-Store (zusätzliche Supplements neben Kreatin)
//
// Kreatin bleibt der „Held" der App (eigener Store, Streak, Kalender,
// Erfolge). Dieser Store verwaltet OPTIONALE Zusatz-Supplements als
// einfache Tages-Checkliste: Vitamin D, Omega 3, Magnesium … Der Nutzer
// wählt in den Einstellungen, welche in der „Heute"-Liste erscheinen.
//
// Bewusst KEINE eigene Streak-/Achievement-Maschinerie pro Supplement —
// das würde die App überladen. Nur: „heute genommen?" + eine kleine
// Wochen-Quote (x/7) als Konsistenz-Hinweis.

@Observable
final class SupplementStore {

    struct Supplement: Identifiable, Codable, Equatable {
        var id: String
        var name: String
        var emoji: String
        var enabled: Bool
    }

    /// Katalog aller bekannten Zusatz-Supplements (mit enabled-Flag).
    private(set) var supplements: [Supplement] = []

    /// Pro Tag die IDs der genommenen Supplements. dayKey → [supplementID].
    private var takenByDay: [String: [String]] = [:]

    private let supplementsKey = "supplementCatalog"
    private let takenKey = "supplementTakenByDay"
    private let defaults = SharedDefaults.store

    /// Standard-Katalog: eine gängige Auswahl, damit das Feature sichtbar
    /// ist. Der Nutzer kann in den Einstellungen an-/abwählen.
    static let defaultCatalog: [Supplement] = [
        // Standardmäßig sichtbar (gängiger Stack):
        Supplement(id: "vitaminD",    name: "Vitamin D",   emoji: "💊", enabled: true),
        Supplement(id: "omega3",      name: "Omega 3",     emoji: "🐟", enabled: true),
        Supplement(id: "magnesium",   name: "Magnesium",   emoji: "✨", enabled: true),
        // Weitere Vorlagen (per Verwaltung hinzufügbar):
        Supplement(id: "zink",        name: "Zink",        emoji: "🧲", enabled: false),
        Supplement(id: "vitaminC",    name: "Vitamin C",   emoji: "🍊", enabled: false),
        Supplement(id: "protein",     name: "Protein",     emoji: "🥤", enabled: false),
        Supplement(id: "vitaminB12",  name: "Vitamin B12", emoji: "🔋", enabled: false),
        Supplement(id: "vitaminK2",   name: "Vitamin K2",  emoji: "🦴", enabled: false),
        Supplement(id: "eisen",       name: "Eisen",       emoji: "🩸", enabled: false),
        Supplement(id: "kalzium",     name: "Kalzium",     emoji: "🥛", enabled: false),
        Supplement(id: "ashwagandha", name: "Ashwagandha", emoji: "🌿", enabled: false),
        Supplement(id: "kollagen",    name: "Kollagen",    emoji: "💫", enabled: false),
        Supplement(id: "betaAlanin",  name: "Beta-Alanin", emoji: "⚡️", enabled: false),
        Supplement(id: "koffein",     name: "Pre-Workout", emoji: "🔥", enabled: false),
    ]

    init() {
        // Katalog laden oder Standard verwenden; fehlende Standard-Einträge
        // ergänzen (falls später neue Supplements dazukommen).
        if let data = defaults.data(forKey: supplementsKey),
           let saved = try? JSONDecoder().decode([Supplement].self, from: data),
           !saved.isEmpty {
            var merged = saved
            for def in Self.defaultCatalog where !merged.contains(where: { $0.id == def.id }) {
                merged.append(def)
            }
            supplements = merged
        } else {
            supplements = Self.defaultCatalog
        }

        if let data = defaults.data(forKey: takenKey),
           let saved = try? JSONDecoder().decode([String: [String]].self, from: data) {
            takenByDay = saved
        }
    }

    private func saveCatalog() {
        if let data = try? JSONEncoder().encode(supplements) {
            defaults.set(data, forKey: supplementsKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func saveTaken() {
        if let data = try? JSONEncoder().encode(takenByDay) {
            defaults.set(data, forKey: takenKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Abfragen

    /// Die in der „Heute"-Liste sichtbaren (aktivierten) Supplements.
    var enabledSupplements: [Supplement] {
        supplements.filter(\.enabled)
    }

    func isTakenToday(_ id: String) -> Bool {
        takenByDay[DayKey.today]?.contains(id) ?? false
    }

    func isTaken(_ id: String, on date: Date) -> Bool {
        takenByDay[DayKey.string(for: date)]?.contains(id) ?? false
    }

    /// Wie viele der aktivierten Supplements sind heute schon abgehakt?
    var takenTodayCount: Int {
        enabledSupplements.filter { isTakenToday($0.id) }.count
    }

    /// Kleine Wochen-Quote (letzte 7 Tage inkl. heute) für ein Supplement.
    func takenCountThisWeek(_ id: String) -> Int {
        let calendar = Calendar.current
        return (0..<7).filter { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return false }
            return isTaken(id, on: day)
        }.count
    }

    // MARK: - Aktionen

    /// Supplement für heute an-/abhaken.
    func toggleToday(_ id: String) {
        let key = DayKey.today
        var ids = takenByDay[key] ?? []
        if let idx = ids.firstIndex(of: id) {
            ids.remove(at: idx)
        } else {
            ids.append(id)
        }
        takenByDay[key] = ids
        saveTaken()
    }

    /// Ein Supplement in der „Heute"-Liste ein-/ausblenden (aus Settings).
    func setEnabled(_ id: String, _ enabled: Bool) {
        guard let idx = supplements.firstIndex(where: { $0.id == id }) else { return }
        supplements[idx].enabled = enabled
        saveCatalog()
    }
}
