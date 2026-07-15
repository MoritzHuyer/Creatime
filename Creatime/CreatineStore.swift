import Foundation
import Observation
import WidgetKit

// Das Herzstück der App: speichert JEDEN Tag, an dem Kreatin genommen wurde
// (oder explizit pausiert wurde). Daraus wird alles berechnet: Streak,
// beste Streak, Kalender, Quote ...
//
// @Observable (neu seit iOS 17) macht die Klasse für SwiftUI „beobachtbar":
// Jede View, die z.B. `store.currentStreak` anzeigt, aktualisiert sich
// automatisch, sobald sich die Daten ändern.

@Observable
final class CreatineStore {

    /// Alle Tage mit Einnahme als Strings wie „2026-07-12".
    private(set) var takenDays: Set<String> = []

    /// Tage, die mit „Pause" markiert wurden. Diese unterbrechen die
    /// Streak NICHT, zählen aber auch nicht als Tag dazu (Streak-Schutz).
    private(set) var skippedDays: Set<String> = []

    /// Tage, die als „Freeze" markiert wurden (Streak-Schutz-Eis-Tag,
    /// monatliches Limit). Semantisch identisch zu skippedDays für die
    /// Streak-Zählung, aber UI unterscheidet ❄️ vs ⏸ und das System
    /// zählt sie separat für das monatliche Limit (2 pro Monat).
    private(set) var frozenDays: Set<String> = []

    /// Einnahme-Zeit pro Tag: yyyy-MM-dd → Stunde (0–23).
    /// Wird beim Markieren gespeichert; das System nutzt es für die
    /// Smart-Reminder-Heuristik (siehe `typicalIntakeHour`).
    private(set) var intakeTimesByDay: [String: Int] = [:]

    /// Tageszahlen von Achievements, die schon gefeiert wurden. Damit das
    /// Konfetti nicht jedesmal wieder kommt, wenn die Streak einen
    /// Meilenstein erneut berührt.
    private(set) var celebratedMilestones: Set<Int> = []

    /// Welcher Milestone zuletzt gefeuert wurde — wird nach Sichtung
    /// (Acknowledge durch AchievementsView oder ContentView) auf nil
    /// gesetzt. Solo-Source-of-Truth für „soll ich gerade Konfetti
    /// abfeuern?".
    private(set) var lastCelebratedMilestone: Int?

    /// Mood-Emoji-Auswahl pro Tag (yyyy-MM-dd → key des emojis, siehe
    /// MoodEmojiPicker). Wird für MoodHistoryChart im HistoryView benutzt.
    private(set) var moodByDay: [String: String] = [:]

    /// Bis zu welchem Datum der „Urlaubsmodus" läuft. Während dieser Zeit
    /// ist die „1 Pause pro Woche"-Grenze aufgehoben.
    var vacationUntil: Date? {
        didSet {
            saveVacation()
        }
    }

    /// Optionaler UserDefaults-Speicher für Tests (App Group als Default).
    private let defaults: UserDefaults

    // MARK: - Default-Keys für die App-Group-Persistierung

    private let storageKey = "takenDays"
    private let skippedKey = "skippedDays"
    private let frozenKey = "frozenDays"
    private let intakeTimesKey = "intakeTimesByDay"
    private let celebratedKey = "celebratedMilestones"
    private let moodKey = "moodByDay"
    private let lastCelebratedMilestoneKey = "lastCelebratedMilestone"
    private let vacationUntilKey = "vacationUntil"
    private let lastFreezeMonthKey = "lastFreezeMonth"

    /// Maximale Anzahl Streak-Freeze-Tage pro Kalendermonat. Wird beim
    /// ersten Monatswechsel automatisch auf diesen Wert zurückgesetzt.
    static let freezeBudgetPerMonth = 2

    init(defaults: UserDefaults = SharedDefaults.store) {
        self.defaults = defaults

        migrateFromStandardDefaultsIfNeeded()
        if let saved = defaults.stringArray(forKey: storageKey) {
            takenDays = Set(saved)
        }
        if let saved = defaults.stringArray(forKey: skippedKey) {
            skippedDays = Set(saved)
        }
        if let saved = defaults.stringArray(forKey: frozenKey) {
            frozenDays = Set(saved)
        }
        if let saved = defaults.dictionary(forKey: intakeTimesKey) as? [String: Int] {
            intakeTimesByDay = saved
        }
        if let saved = defaults.array(forKey: celebratedKey) as? [Int] {
            celebratedMilestones = Set(saved)
        }
        if let saved = defaults.dictionary(forKey: moodKey) as? [String: String] {
            moodByDay = saved
        }
        if let last = defaults.object(forKey: lastCelebratedMilestoneKey) as? Int {
            lastCelebratedMilestone = last
        }
        if let ts = defaults.object(forKey: vacationUntilKey) as? Double {
            vacationUntil = Date(timeIntervalSince1970: ts)
        }

        // Erste-Launch-Tracking: wird in AppShortcut-Handler / Onboarding
        // verwendet, um Onboarding-Achievement (days: 0) zu triggern.
        if defaults.object(forKey: "firstLaunchAt") == nil {
            defaults.set(Date().timeIntervalSince1970, forKey: "firstLaunchAt")
        }

        migrateOldDataIfNeeded()
        ensureFreezeBudgetIsCurrentMonth()
    }

    private func save() {
        defaults.set(Array(takenDays).sorted(), forKey: storageKey)
        defaults.set(Array(skippedDays).sorted(), forKey: skippedKey)
        defaults.set(Array(frozenDays).sorted(), forKey: frozenKey)
        defaults.set(intakeTimesByDay, forKey: intakeTimesKey)
        defaults.set(moodByDay, forKey: moodKey)
        defaults.set(Array(celebratedMilestones).sorted(), forKey: celebratedKey)
        if let last = lastCelebratedMilestone {
            defaults.set(last, forKey: "lastCelebratedMilestone")
        } else {
            defaults.removeObject(forKey: "lastCelebratedMilestone")
        }
        if let date = vacationUntil {
            defaults.set(date.timeIntervalSince1970, forKey: vacationUntilKey)
        } else {
            defaults.removeObject(forKey: vacationUntilKey)
        }
        // Dem Widget Bescheid geben, dass es sich neu zeichnen soll:
        WidgetCenter.shared.reloadAllTimelines()
        // App-Icon-Badge auf die aktuelle Streak setzen — User sieht die
        // Zahl auch ohne die App zu öffnen, direkt auf dem Homescreen.
        AppBadgeManager.setBadge(currentStreak)
    }

    /// Nur das Urlaubs-Datum speichern (weniger Schreiblast, schneller).
    private func saveVacation() {
        if let date = vacationUntil {
            defaults.set(date.timeIntervalSince1970, forKey: vacationUntilKey)
        } else {
            defaults.removeObject(forKey: vacationUntilKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Liest den aktuellen Stand aus dem App-Group-Speicher neu ein,
    /// ohne den Store neu zu instanziieren. Wird aufgerufen, sobald die
    /// App wieder aktiv wird — z.B. nachdem ein AppIntent (Siri/Shortcuts)
    /// die `takenDays` im Hintergrund verändert hat.
    func reload() {
        if let saved = defaults.stringArray(forKey: storageKey) {
            takenDays = Set(saved)
        }
        if let saved = defaults.stringArray(forKey: skippedKey) {
            skippedDays = Set(saved)
        }
        if let saved = defaults.stringArray(forKey: frozenKey) {
            frozenDays = Set(saved)
        }
        if let saved = defaults.dictionary(forKey: intakeTimesKey) as? [String: Int] {
            intakeTimesByDay = saved
        }
        if let saved = defaults.dictionary(forKey: moodKey) as? [String: String] {
            moodByDay = saved
        }
        WidgetCenter.shared.reloadAllTimelines()
        AppBadgeManager.setBadge(currentStreak)
        ensureFreezeBudgetIsCurrentMonth()
    }

    /// Zieht Daten aus dem alten Standard-Speicher in die App Group um
    /// (nötig, weil frühere Versionen noch ohne Widget/App Group liefen).
    private func migrateFromStandardDefaultsIfNeeded() {
        if defaults.stringArray(forKey: storageKey) == nil,
           let old = UserDefaults.standard.stringArray(forKey: storageKey) {
            defaults.set(old, forKey: storageKey)
        }
        if defaults.stringArray(forKey: skippedKey) == nil,
           let old = UserDefaults.standard.stringArray(forKey: skippedKey) {
            defaults.set(old, forKey: skippedKey)
        }
    }

    /// Übernimmt Daten aus der allerersten App-Version (die nur
    /// „lastTakenDate" und „streak" kannte).
    private func migrateOldDataIfNeeded() {
        let standard = UserDefaults.standard
        let oldDate = standard.string(forKey: "lastTakenDate") ?? ""
        let oldStreak = standard.integer(forKey: "streak")

        guard takenDays.isEmpty, !oldDate.isEmpty,
              let lastDay = DayKey.date(from: oldDate) else { return }

        for i in 0..<max(oldStreak, 1) {
            if let day = Calendar.current.date(byAdding: .day, value: -i, to: lastDay) {
                takenDays.insert(DayKey.string(for: day))
            }
        }
        save()
        standard.removeObject(forKey: "lastTakenDate")
        standard.removeObject(forKey: "streak")
    }

    // MARK: - Aktionen

    /// Markiert den heutigen Tag als „genommen". Gibt ein Achievement zurück,
    /// falls dadurch ein neuer Meilenstein freigeschaltet wurde — das nutzt
    /// die UI, um Konfetti zu zeigen.
    ///
    /// NEU in v3: Speichert zusätzlich die aktuelle Stunde in
    /// `intakeTimesByDay` — das ist das Rohmaterial für die Smart-
    /// Reminder-Heuristik.
    @discardableResult
    func markTodayAsTaken() -> Achievement? {
        let oldBest = bestStreak
        let isFirstTakenToday = !takenDays.contains(DayKey.today)
        takenDays.insert(DayKey.today)

        if isFirstTakenToday {
            let hour = Calendar.current.component(.hour, from: Date())
            intakeTimesByDay[DayKey.today] = hour
        }

        save()
        return newlyAchieved(before: oldBest, after: bestStreak)
    }

    /// Markiert den heutigen Tag als „Pause". Maximal eine Pause pro Woche,
    /// außer der Urlaubsmodus ist aktiv.
    /// - Returns: true, wenn die Pause eingetragen wurde.
    @discardableResult
    func markTodayAsSkipped() -> Bool {
        guard canSkipToday else { return false }
        skippedDays.insert(DayKey.today)
        save()
        return true
    }

    /// Nimmt eine Pause wieder zurück (z.B. wenn man sich verklickt hat).
    func unskip(date: Date) {
        skippedDays.remove(DayKey.string(for: date))
        save()
    }

    /// Setzt die Stimmung für den heutigen Tag. Mehrfach-Aufrufe an
    /// einem Tag überschreiben sich gegenseitig (kein History-Stacking,
    /// würde Over-Engineering sein).
    func setMoodToday(_ moodKey: String) {
        moodByDay[DayKey.today] = moodKey
        save()
    }

    /// Liest die Stimmung für einen Tag (z.B. für History-Chart).
    func moodFor(date: Date) -> String? {
        moodByDay[DayKey.string(for: date)]
    }

    /// Verwendet einen Streak-Freeze für ein Datum.
    ///
    /// FREEZE-TAG = „Ich will heute nichts sagen, aber meine Streak soll
    /// nicht abreißen" — semantisch identisch zu skippedDays für die
    /// Streak-Logik, aber das System zählt sie separat, damit das
    /// monatliche Budget (2) sich nicht mit dem Weekly Skip vermischt.
    ///
    /// Returns: true wenn der Freeze gebucht wurde. False wenn:
    ///   • das Datum schon taken/skipped ist (kein Override)
    ///   • das Monats-Budget aufgebraucht ist
    @discardableResult
    func useFreeze(for date: Date) -> Bool {
        let key = DayKey.string(for: date)
        if takenDays.contains(key) { return false }
        if skippedDays.contains(key) { return false }
        if frozenDays.contains(key) { return false }   // schon gefroren
        ensureFreezeBudgetIsCurrentMonth()
        guard freezesUsedThisMonth < Self.freezeBudgetPerMonth else { return false }
        frozenDays.insert(key)
        save()
        return true
    }

    /// Nimmt einen Freeze zurück.
    func unfreeze(date: Date) {
        frozenDays.remove(DayKey.string(for: date))
        save()
    }

    /// Startet den Urlaubsmodus bis zum angegebenen Datum.
    func startVacation(until date: Date) {
        vacationUntil = Calendar.current.startOfDay(for: date)
    }

    /// Beendet den Urlaubsmodus sofort.
    func endVacation() {
        vacationUntil = nil
    }

    // MARK: - Abfragen (heutiger Tag)

    var takenToday: Bool {
        takenDays.contains(DayKey.today)
    }

    /// Hat der Nutzer heute explizit „Pause" gedrückt?
    var skippedToday: Bool {
        skippedDays.contains(DayKey.today)
    }

    /// Hat der Nutzer heute einen „Freeze" gebucht?
    var frozenToday: Bool {
        frozenDays.contains(DayKey.today)
    }

    /// Gegenteil von `takenToday || skippedToday || frozenToday`.
    var untouchedToday: Bool {
        !takenToday && !skippedToday && !frozenToday
    }

    func isTaken(_ date: Date) -> Bool {
        takenDays.contains(DayKey.string(for: date))
    }

    func isSkipped(_ date: Date) -> Bool {
        skippedDays.contains(DayKey.string(for: date))
    }

    func isFrozen(_ date: Date) -> Bool {
        frozenDays.contains(DayKey.string(for: date))
    }

    /// Streak-Schutz-Tag = entweder froze oder skipped (für Kalender-UI).
    func isStreakProtected(_ date: Date) -> Bool {
        isSkipped(date) || isFrozen(date)
    }

    // MARK: - Freeze-System (2 pro Kalendermonat)

    /// „yyyy-MM" Schlüssel für den aktuellen Monat. Hilfsschlüssel für
    /// die Auto-Reset-Logik.
    private var currentMonthKey: String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        return String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
    }

    /// Setzt das Freeze-Budget automatisch zurück, wenn ein neuer Monat
    /// begonnen hat. Wird in init() und reload() aufgerufen.
    private func ensureFreezeBudgetIsCurrentMonth() {
        let last = defaults.string(forKey: lastFreezeMonthKey) ?? ""
        if last != currentMonthKey {
            // Reset: das Budget ist 2 für den neuen Monat. Wir löschen
            // KEINE alten frozenDays — die gehören zum vorherigen Monat
            // und werden im UI dezent als „historisch" markiert. Hier
            // wird nur der Zähler-Key für die Anzeige zurückgesetzt.
            defaults.set(currentMonthKey, forKey: lastFreezeMonthKey)
        }
    }

    /// Wieviele Freezes in DIESEM Monat bereits verbraucht wurden.
    var freezesUsedThisMonth: Int {
        let monthKey = currentMonthKey
        let cal = Calendar.current
        return frozenDays.filter { key in
            guard let date = DayKey.date(from: key) else { return false }
            let comps = cal.dateComponents([.year, .month], from: date)
            return String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0) == monthKey
        }.count
    }

    /// Verbleibende Freezes für DIESEN Monat (`budget - verbraucht`).
    var freezesRemainingThisMonth: Int {
        max(0, Self.freezeBudgetPerMonth - freezesUsedThisMonth)
    }

    /// Wahr, wenn der heutige Tag mit einem Freeze abgedeckt werden könnte.
    var canFreezeToday: Bool {
        if takenToday || skippedToday || frozenToday { return false }
        if vacationEnabled { return false }    // Im Urlaub: kein Freeze nötig
        ensureFreezeBudgetIsCurrentMonth()
        return freezesRemainingThisMonth > 0
    }

    // MARK: - Smart-Reminder-Heuristik

    /// Berechnet die typische Einnahme-Stunde über die letzten 14 Tage.
    /// Gibt `nil` zurück, wenn weniger als 3 Datenpunkte vorliegen
    /// (= zu wenig für sinnvolle Heuristik).
    var typicalIntakeHour: Int? {
        let cal = Calendar.current
        let now = Date()
        let cutoff = cal.date(byAdding: .day, value: -14, to: now) ?? now
        let cutoffKey = DayKey.string(for: cutoff)

        // Wir zählen nur Daten = UND nach dem Cutoff Tag.
        let recent = intakeTimesByDay.filter { (key, _) in key >= cutoffKey }
        guard recent.count >= 3 else { return nil }

        let hours = recent.values.sorted()
        let median = hours[hours.count / 2]
        return median
    }

    /// Drei Reminder-Zeiten für den heutigen Tag (oder NULL wenn der
    /// typische Intake nicht ermittelbar ist). Wir geben einen
    /// Haupt-Reminder (typische Stunde) + 2 Backup-Slots (typische ± 2 h)
    /// zurück. NotificationManager nutzt das zum Scheduling.
    var suggestedReminderHoursToday: [Int]? {
        guard let median = typicalIntakeHour else { return nil }
        let options = [median - 2, median, median + 2].filter { (0..<24).contains($0) }
        let unique = Array(Set(options)).sorted()
        // Mindestens 1, sonst lieber nichts zurück.
        return unique.isEmpty ? nil : unique
    }

    // MARK: - Feier-Mechanik

    /// Welches Achievement (falls überhaupt eines) wurde durch den Sprung von
    /// `before` zu `after` neu freigeschaltet? Markiert es gleichzeitig als
    /// „schon gefeiert", damit es kein zweites Mal Konfetti gibt.
    private func newlyAchieved(before: Int, after: Int) -> Achievement? {
        for achievement in Achievement.all
            where achievement.days > before && achievement.days <= after {
            if !celebratedMilestones.contains(achievement.days) {
                celebratedMilestones.insert(achievement.days)
                lastCelebratedMilestone = achievement.days
                save()
                return achievement
            }
        }
        return nil
    }

    /// Special-Case: das Onboarding-Erfolgserlebnis (`Achievement(days: 0)`).
    /// Wird beim ersten erfolgreichen Einnahme-Druck ausgelöst, NACHDEM
    /// das Onboarding abgeschlossen wurde. Wir gucken also an zwei Stellen
    /// „gibt es schon gefeiert? sonst: jetzt feiern".
    @discardableResult
    func celebrateOnboardingIfFirstTake() -> Achievement? {
        guard !celebratedMilestones.contains(0),
              hasCompletedOnboarding else { return nil }
        celebratedMilestones.insert(0)
        lastCelebratedMilestone = 0
        save()
        return Achievement.onboardingStarter
    }

    /// Setzt das Konfetti-Flag zurück, NACHDEM die AchievementsView es
    /// gesehen hat. So wird die UI nicht endlos Konfetti abfeuern,
    /// wenn die User mehrere Tage auf der Erfolge-Tab verbringt.
    func acknowledgeLatestMilestone() {
        guard lastCelebratedMilestone != nil else { return }
        lastCelebratedMilestone = nil
        defaults.removeObject(forKey: "lastCelebratedMilestone")
    }

    /// Liest @AppStorage-Wert CLEAN ohne circular dependency. Wird in
    /// `init`/init-Helfer als Argument reingereicht.
    var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    // MARK: - Streak-Berechnungen

    /// Die aktuelle Streak — die Rechenlogik liegt in Shared/StreakCalculator,
    /// damit das Widget exakt dieselbe verwendet.
    var currentStreak: Int {
        StreakCalculator.currentStreak(
            takenDays: takenDays,
            skippedDays: skippedDays,
            frozenDays: frozenDays
        )
    }

    /// Die längste Serie aller Zeiten. Zählt sowohl genommene als auch
    /// übersprungene als auch gefrorene Tage als Teil der Kette.
    var bestStreak: Int {
        let calendar = Calendar.current
        let combined = takenDays.union(skippedDays).union(frozenDays)
        let dates = combined.compactMap(DayKey.date(from:)).sorted()

        var best = 0
        var current = 0
        var previous: Date?

        for date in dates {
            if let prev = previous,
               let expected = calendar.date(byAdding: .day, value: 1, to: prev),
               calendar.isDate(date, inSameDayAs: expected) {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previous = date
        }
        return best
    }

    /// Wie viele Tage insgesamt bestätigt wurden.
    var totalDays: Int {
        takenDays.count
    }

    /// Anteil der letzten 30 Tage (inkl. heute) mit Einnahme: 0.0 bis 1.0.
    /// Übersprungene UND gefrorene Tage zählen als „voll" (Streak-Schutz!).
    var last30DaysRate: Double {
        let calendar = Calendar.current
        let coveredCount = (0..<30).filter { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return false }
            let key = DayKey.string(for: day)
            return takenDays.contains(key)
                || skippedDays.contains(key)
                || frozenDays.contains(key)
        }.count
        return Double(coveredCount) / 30.0
    }

    /// Anzahl der letzten 30 Tage (inkl. heute), an denen Kreatin
    /// genommen wurde (= taken, nicht skipped/frozen). Wird für die
    /// v13 „Perfekte Tage"-Stat-Kachel im HistoryView verwendet.
    var perfectDaysLast30: Int {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let cutoffKey = DayKey.string(for: cutoff)
        return takenDays.filter { $0 >= cutoffKey }.count
    }

    // MARK: - Streak-Schutz (1 Pause pro Woche)

    /// Wie oft in der aktuellen ISO-Woche schon pausiert (skip-typisch) wurde.
    var skipsThisWeek: Int {
        let currentWeek = WeekKey.current
        return skippedDays.filter { key in
            guard let date = DayKey.date(from: key) else { return false }
            return WeekKey.key(for: date) == currentWeek
        }.count
    }

    /// Verbleibende Pausen in dieser Woche (Differenz zu 1).
    var skipsRemainingThisWeek: Int {
        max(0, 1 - skipsThisWeek)
    }

    /// Darf der Nutzer heute pausieren? (Weekly-Budget)
    var canSkipToday: Bool {
        if takenToday || skippedToday || frozenToday { return false }
        if vacationEnabled { return true }    // Urlaubsmodus hebt das Limit auf
        return skipsRemainingThisWeek > 0
    }

    /// Ist der Urlaubsmodus gerade aktiv?
    var vacationEnabled: Bool {
        guard let until = vacationUntil else { return false }
        return until >= Calendar.current.startOfDay(for: Date())
    }

    // MARK: - Insights-Properties (delegiert an MetricsCalculator)

    var forgetfulnessByWeekday: [Int: Int] {
        MetricsCalculator.forgetfulnessByWeekday(
            takenDays: takenDays,
            skippedDays: skippedDays,
            daysBack: 90
        )
    }

    var topForgetfulWeekday: (weekday: Int, count: Int)? {
        MetricsCalculator.topForgetfulWeekday(
            takenDays: takenDays,
            skippedDays: skippedDays,
            daysBack: 90
        )
    }

    var consistencyScore: Int {
        MetricsCalculator.consistencyScore(
            takenDays: takenDays,
            skippedDays: skippedDays,
            currentStreak: currentStreak,
            vacationUntil: vacationUntil
        )
    }

    /// Welcher aktuelle Streak gilt als „großer Meilenstein" für Extra-Konfetti?
    var currentMilestoneDescription: String? {
        switch currentStreak {
        case 7:   return "Erste Woche 🎉"
        case 14:  return "Zwei Wochen 🔥"
        case 30:  return "Ein Monat 🏅"
        case 60:  return "Zwei Monate 💎"
        case 100: return "100-Tage-Club 🏆"
        case 200: return "200 Tage — Wahnsinn 🚀"
        case 365: return "Ein ganzes Jahr 🎂"
        default:  return nil
        }
    }
}
