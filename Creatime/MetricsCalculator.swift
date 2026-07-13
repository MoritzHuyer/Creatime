import Foundation

// MARK: - Metrics Calculator
// Berechnet aggregierte Insights aus den Roh-Daten der Stores.
// Reine Funktionen, keine State-Abhängigkeit — perfekt testbar.

enum MetricsCalculator {

    // MARK: - Vergesslichkeits-Heat-Map (pro Wochentag)

    /// Liefert ein Dictionary `[Weekday: Vergessen-Anzahl]` für die letzten
    /// `daysBack` Tage. „Vergessen" = Tag nicht in `takenDays` UND nicht in
    /// `skippedDays`. Weekday nutzt Calendar mit firstWeekday=2 (= Montag).
    static func forgetfulnessByWeekday(
        takenDays: Set<String>,
        skippedDays: Set<String>,
        daysBack: Int = 90,
        today: Date = Date()
    ) -> [Int: Int] {
        var counts: [Int: Int] = [:]
        let calendar = Calendar(identifier: .iso8601)   // Wochenstart = Montag
        for offset in 0..<daysBack {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today)
            else { continue }
            let key = DayKey.string(for: day)
            let wasCovered = takenDays.contains(key) || skippedDays.contains(key)
            if !wasCovered {
                let weekday = calendar.component(.weekday, from: day)   // 1=Sunday..7=Saturday
                counts[weekday, default: 0] += 1
            }
        }
        return counts
    }

    /// Top-„Vergesslichkeits-Tag" als Tuple `(weekdayIndex, vergessenAnzahl)`.
    static func topForgetfulWeekday(
        takenDays: Set<String>,
        skippedDays: Set<String>,
        daysBack: Int = 90
    ) -> (weekday: Int, count: Int)? {
        let heatmap = forgetfulnessByWeekday(
            takenDays: takenDays,
            skippedDays: skippedDays,
            daysBack: daysBack
        )
        // `Dictionary.max(by:)` liefert ein Element-Optional (key,value),
        // wir mappen es auf das benannte Tuple für die UI-Schicht.
        return heatmap
            .max(by: { $0.value < $1.value })
            .map { (weekday: $0.key, count: $0.value) }
    }

    // MARK: - Konsistenz-Score (0–100)

    /// Gewichteter Score aus drei Komponenten:
    /// - **Coverage** (60%): like `last30DaysRate` × 100
    /// - **Streak-Strength** (30%): aktuelle Streak / Zielstreak (cap bei 30)
    /// - **Vacation-Balance** (10%): 100 minus Strafe für zu lange Urlaube
    static func consistencyScore(
        takenDays: Set<String>,
        skippedDays: Set<String>,
        currentStreak: Int,
        vacationUntil: Date?,
        daysBack: Int = 30,
        today: Date = Date(),
        streakGoal: Int = 30
    ) -> Int {
        let coverage = last30Coverage(
            takenDays: takenDays,
            skippedDays: skippedDays,
            daysBack: daysBack,
            today: today
        )
        let streakComponent = min(Double(currentStreak) / Double(streakGoal), 1.0)

        // Vacation-Sub-Score: 100 wenn kein Urlaub aktiv,
        // sonst gedeckelt auf Verbleib in Tagen × 4 (max 100).
        let vacationScore: Double
        if let until = vacationUntil, until > today {
            let remainingDays = Calendar.current.dateComponents([.day], from: today, to: until).day ?? 0
            vacationScore = min(Double(max(0, remainingDays)) * 4.0, 100.0)
        } else {
            vacationScore = 100
        }

        let raw = coverage * 60 + streakComponent * 30 + vacationScore * 0.10
        return max(0, min(100, Int(raw.rounded())))
    }

    /// 0.0–1.0 Anteil der letzten N Tage mit Einnahme ODER Skip (= „covered").
    static func last30Coverage(
        takenDays: Set<String>,
        skippedDays: Set<String>,
        daysBack: Int = 30,
        today: Date = Date()
    ) -> Double {
        let calendar = Calendar.current
        let covered = (0..<daysBack).filter { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today)
            else { return false }
            let key = DayKey.string(for: day)
            return takenDays.contains(key) || skippedDays.contains(key)
        }.count
        return Double(covered) / Double(daysBack)
    }

    // MARK: - Wochenvergleich

    /// Durchschnitt Wassermenge der **aktuellen** Kalenderwoche (Mo–So enthalten).
    static func thisWeekWaterAverage(waterByDay: [String: Int], today: Date = Date()) -> Int {
        averageForWeek(containing: today, waterByDay: waterByDay)
    }

    /// Durchschnitt der **vorherigen** Kalenderwoche.
    static func lastWeekWaterAverage(waterByDay: [String: Int], today: Date = Date()) -> Int {
        guard let lastWeekRef = Calendar(identifier: .iso8601)
            .date(byAdding: .day, value: -7, to: today)
        else { return 0 }
        return averageForWeek(containing: lastWeekRef, waterByDay: waterByDay)
    }

    /// Differenz zwischen den Wochen als Prozent (z. B. +0.15 = +15%).
    /// Gibt `nil` zurück, wenn letztes Wochen-Mittel 0 war (Division by 0).
    static func weekOverWeekDelta(
        waterByDay: [String: Int],
        today: Date = Date()
    ) -> Double? {
        let last = lastWeekWaterAverage(waterByDay: waterByDay, today: today)
        let current = thisWeekWaterAverage(waterByDay: waterByDay, today: today)
        guard last > 0 else { return nil }
        return (Double(current) - Double(last)) / Double(last)
    }

    private static func averageForWeek(
        containing reference: Date,
        waterByDay: [String: Int]
    ) -> Int {
        let calendar = Calendar(identifier: .iso8601)
        // Wochenstart (Montag) für das Referenz-Datum.
        let weekday = calendar.component(.weekday, from: reference)
        let mondayOffset = (weekday + 5) % 7   // Mon=0, Tue=1, ..., Sun=6
        guard let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: reference)
        else { return 0 }
        var total = 0
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: monday) else { continue }
            total += waterByDay[DayKey.string(for: day)] ?? 0
        }
        return total / 7
    }
}
