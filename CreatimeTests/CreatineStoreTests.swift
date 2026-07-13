import XCTest
@testable import Creatime

// MARK: - CreatineStore Unit-Tests

final class CreatineStoreTests: XCTestCase {

    private var testSuite: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testSuite = "CreatineStoreTests_" + UUID().uuidString
        defaults = UserDefaults(suiteName: testSuite)!
        defaults.removePersistentDomain(forName: testSuite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: testSuite)
        super.tearDown()
    }

    // MARK: - Helpers

    /// Erzeugt einen Store mit vorbereiteter Datenlage und gibt ihn zurück.
    private func makeStore(
        takenOffsets: [Int] = [],
        skippedOffsets: [Int] = [],
        celebrated: [Int] = []
    ) -> CreatineStore {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let taken = takenOffsets.compactMap { off -> String? in
            calendar.date(byAdding: .day, value: -off, to: today)
                .map { DayKey.string(for: $0) }
        }
        let skipped = skippedOffsets.compactMap { off -> String? in
            calendar.date(byAdding: .day, value: -off, to: today)
                .map { DayKey.string(for: $0) }
        }

        defaults.set(taken, forKey: "takenDays")
        defaults.set(skipped, forKey: "skippedDays")
        defaults.set(celebrated, forKey: "celebratedMilestones")
        defaults.synchronize()
        return CreatineStore(defaults: defaults)
    }

    // MARK: - Laden

    func test_init_loadsTakenDaysFromDefaults() {
        let store = makeStore(takenOffsets: [0, 1, 2])
        XCTAssertEqual(store.takenDays.count, 3)
        XCTAssertTrue(store.takenToday)
    }

    func test_init_withEmptyData_isEmpty() {
        // Anti-Migration: keine Keys in `defaults`, also liest die Init auch
        // nichts. Standard-UserDefaults könnten in Theorie Daten haben, aber
        // wir nutzen ein frisches Suite.
        let store = makeStore()
        XCTAssertEqual(store.takenDays.count, 0)
        XCTAssertFalse(store.takenToday)
        XCTAssertEqual(store.celebratedMilestones.count, 0)
    }

    // MARK: - markTodayAsTaken

    func test_markTodayAsTaken_setsTakenTodayTrue() {
        let store = makeStore()
        XCTAssertFalse(store.takenToday)
        _ = store.markTodayAsTaken()
        XCTAssertTrue(store.takenToday)
        XCTAssertEqual(store.takenDays.count, 1)
    }

    func test_markTodayAsTaken_returns7DayAchievementAtThreshold() {
        // Streak = 6 vor dem Markieren; nach Markieren = 7 → Achievement 7 feuert.
        let store = makeStore(takenOffsets: [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(store.bestStreak, 6)

        let result = store.markTodayAsTaken()

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.days, 7)
        XCTAssertTrue(store.celebratedMilestones.contains(7))
    }

    func test_markTodayAsTaken_doesNotRefireCelebratedMilestone() {
        // 7 ist schon gefeiert; Übergang von 7 → 8 ergibt KEIN Achievement,
        // weil keines im Intervall (7, 8] liegt.
        let store = makeStore(takenOffsets: [1, 2, 3, 4, 5, 6], celebrated: [7])
        let result = store.markTodayAsTaken()
        XCTAssertNil(result)
    }

    // MARK: - markTodayAsSkipped

    func test_markTodayAsSkipped_succeedsOnFreshDay() {
        let store = makeStore()
        XCTAssertTrue(store.canSkipToday)
        XCTAssertTrue(store.markTodayAsSkipped())
        XCTAssertTrue(store.skippedToday)
        XCTAssertEqual(store.skipsThisWeek, 1)
    }

    func test_markTodayAsSkipped_returnsFalseWhenAlreadyTaken() {
        let store = makeStore(takenOffsets: [0])
        XCTAssertFalse(store.canSkipToday)
        XCTAssertFalse(store.markTodayAsSkipped())
    }

    func test_markTodayAsSkipped_returnsFalseWhenAlreadySkipped() {
        let store = makeStore(skippedOffsets: [0])
        XCTAssertFalse(store.canSkipToday)
        XCTAssertFalse(store.markTodayAsSkipped())
    }

    func test_unskip_removesSkip() {
        let store = makeStore(skippedOffsets: [0])
        XCTAssertTrue(store.skippedToday)
        store.unskip(date: Date())
        XCTAssertFalse(store.skippedToday)
        XCTAssertEqual(store.skipsThisWeek, 0)
    }

    // MARK: - Vacation-Mode

    func test_vacationMode_enablesAndDisables() {
        let store = makeStore()
        XCTAssertFalse(store.vacationEnabled)

        let future = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        store.startVacation(until: future)
        XCTAssertTrue(store.vacationEnabled)

        store.endVacation()
        XCTAssertFalse(store.vacationEnabled)
    }

    func test_vacationMode_allowsUnlimitedSkips() {
        // Normalerweise nur 1 Pause/Woche — im Urlaub unbegrenzt.
        let store = makeStore(skippedOffsets: [0])   // diese Woche schon verbraucht
        XCTAssertFalse(store.canSkipToday)            // ... außer Vacation ist an

        let future = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
        store.startVacation(until: future)
        XCTAssertTrue(store.canSkipToday)
    }

    // MARK: - bestStreak mit Skips

    func test_bestStreak_countsSkippedDaysAsChain() {
        // 3 taken + 3 skipped lückenlos → 6
        let store = makeStore(takenOffsets: [0, 2, 4], skippedOffsets: [1, 3, 5])
        XCTAssertEqual(store.bestStreak, 6)
    }

    func test_bestStreak_resetsOnGap() {
        // taken: 0, 2, 4 → Kette 0→1 (gap!)→reset; 2→3 (gap)→reset; 4 → 1
        let store = makeStore(takenOffsets: [0, 2, 4])
        XCTAssertEqual(store.bestStreak, 1)
    }

    // MARK: - last30DaysRate

    func test_last30DaysRate_halfCovered() {
        // 15 von 30 Tagen als taken → 0.5
        let store = makeStore(takenOffsets: Array(0..<15))
        XCTAssertEqual(store.last30DaysRate, 0.5, accuracy: 0.001)
    }

    func test_last30DaysRate_skippedDaysCountAsCovered() {
        // 10 taken + 5 skipped = 15 von 30 → 0.5
        let store = makeStore(takenOffsets: Array(0..<10), skippedOffsets: Array(10..<15))
        XCTAssertEqual(store.last30DaysRate, 0.5, accuracy: 0.001)
    }
}
