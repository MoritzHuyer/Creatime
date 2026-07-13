import XCTest
@testable import Creatime

// MARK: - StreakCalculator Unit-Tests

final class StreakCalculatorTests: XCTestCase {

    /// Datum → ISO-Key (wie DayKey.string(for:)).
    private func key(_ offset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
        return DayKey.string(for: date)
    }

    // MARK: - Reine "takenDays"-Pfade (rückwärtskompatibel)

    func test_empty_returnsZero() {
        XCTAssertEqual(StreakCalculator.currentStreak(takenDays: []), 0)
    }

    func test_onlyToday_returnsOne() {
        XCTAssertEqual(StreakCalculator.currentStreak(takenDays: [key(0)]), 1)
    }

    func test_todayAndYesterday_returnsTwo() {
        let taken: Set<String> = [key(0), key(1)]
        XCTAssertEqual(StreakCalculator.currentStreak(takenDays: taken), 2)
    }

    func test_yesterdayWithoutToday_returnsOne() {
        // Heute vergessen, gestern markiert → Kette beginnt ab gestern.
        let taken: Set<String> = [key(1)]
        XCTAssertEqual(StreakCalculator.currentStreak(takenDays: taken), 1)
    }

    func test_gapBreaksTheChain() {
        // Heute ✓, gestern Lücke (vergessen), vorgestern ✓ → nur 1.
        let taken: Set<String> = [key(0), key(2)]
        XCTAssertEqual(StreakCalculator.currentStreak(takenDays: taken), 1)
    }

    func test_fiveDaysInARow_returnsFive() {
        let taken = Set((0..<5).map(key))
        XCTAssertEqual(StreakCalculator.currentStreak(takenDays: taken), 5)
    }

    // MARK: - Mit Skipped Days

    func test_skippedToday_thenTakenYesterday_returnsOne() {
        let taken: Set<String> = [key(1)]
        let skipped: Set<String> = [key(0)]
        // Anfang bei heute (skipped → mitzählen beginnt erst bei taken),
        // gestern → +1, dann Lücke → Ende. Kette: 1.
        XCTAssertEqual(StreakCalculator.currentStreak(takenDays: taken, skippedDays: skipped), 1)
    }

    func test_takenSkippedTakenSkipped_chain() {
        // heute ✓, gestern skip, vorgestern ✓, vor 3 Tagen skip → 2 taken, 2 skipped dazwischen
        let taken: Set<String> = [key(0), key(2)]
        let skipped: Set<String> = [key(1), key(3)]
        XCTAssertEqual(StreakCalculator.currentStreak(takenDays: taken, skippedDays: skipped), 2)
    }

    func test_onlySkippedToday_doesNotCountAsOne() {
        // Nur heute ist skipped; gestern ist nichts.
        let taken: Set<String> = []
        let skipped: Set<String> = [key(0)]
        // Heute ist skipped → zählt nicht → 0.
        XCTAssertEqual(StreakCalculator.currentStreak(takenDays: taken, skippedDays: skipped), 0)
    }

    func test_LONGChainWithSkipped_keepsCount() {
        // 7 aufeinanderfolgende Tage: T, S, T, S, T, S, T (Offsets 0–6).
        // 4 taken + 3 skipped, lückenlos → aktuelle Streak = 4.
        let taken: Set<String>   = [key(0), key(2), key(4), key(6)]
        let skipped: Set<String> = [key(1), key(3), key(5)]
        XCTAssertEqual(StreakCalculator.currentStreak(takenDays: taken, skippedDays: skipped), 4)
    }
}
