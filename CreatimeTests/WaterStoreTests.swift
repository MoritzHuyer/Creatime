import XCTest
@testable import Creatime

// MARK: - WaterStore Unit-Tests

final class WaterStoreTests: XCTestCase {

    private var testSuite: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testSuite = "WaterStoreTests_" + UUID().uuidString
        defaults = UserDefaults(suiteName: testSuite)!
        defaults.removePersistentDomain(forName: testSuite)

        // Migration-Schutz: Wir PRE-SETZEN die relevanten Keys auf einen
        // Sentinel-Wert, damit die `WaterStore.init()`-Migration NICHT aus
        // `UserDefaults.standard` (Produktivdaten!) in unsere Test-Suite
        // kopiert. Sonst wären Tests wie „default-goal = 2500" flakig.
        defaults.set(2500, forKey: "waterDailyGoal")
        defaults.set([Int](), forKey: "waterQuickAmounts")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: testSuite)
        super.tearDown()
    }

    private func makeStore(goal: Int? = nil) -> WaterStore {
        if let g = goal {
            defaults.set(g, forKey: "waterDailyGoal")
        }
        return WaterStore(defaults: defaults)
    }

    // MARK: - Init / Defaults

    func test_init_defaultGoalIs2500() {
        let store = makeStore()
        XCTAssertEqual(store.dailyGoal, 2500)
    }

    func test_init_loadedGoalFromDefaults() {
        let store = makeStore(goal: 3000)
        XCTAssertEqual(store.dailyGoal, 3000)
    }

    func test_init_defaultQuickAmounts() {
        let store = makeStore()
        XCTAssertEqual(store.quickAmounts, [250, 330, 500])
    }

    // MARK: - addToday

    func test_addTodayIncrements() {
        let store = makeStore()
        XCTAssertEqual(store.todayAmount, 0)
        store.addToday(250)
        XCTAssertEqual(store.todayAmount, 250)
        store.addToday(330)
        XCTAssertEqual(store.todayAmount, 580)
    }

    func test_addTodayNegativeCapsAtZero() {
        let store = makeStore()
        store.addToday(200)
        store.addToday(-500)
        XCTAssertEqual(store.todayAmount, 0)
    }

    // MARK: - goalReachedToday

    func test_goalReached_returnsTrueWhenAmountEqualsGoal() {
        let store = makeStore(goal: 500)
        XCTAssertFalse(store.goalReachedToday)
        store.addToday(500)
        XCTAssertTrue(store.goalReachedToday)
    }

    func test_goalReached_returnsFalseWhenBelowGoal() {
        let store = makeStore(goal: 1000)
        store.addToday(999)
        XCTAssertFalse(store.goalReachedToday)
    }

    // MARK: - progress / weeklyAverage

    func test_todayProgress_returnsFraction() {
        let store = makeStore(goal: 1000)
        store.addToday(250)
        XCTAssertEqual(store.todayProgress, 0.25, accuracy: 0.001)
    }

    func test_weeklyAverage_averagesLastSevenDays() {
        // Manuell Tageswerte für die letzten 7 Tage in defaults setzen.
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dict: [String: Int] = [:]
        let values = [500, 1000, 1500, 2000, 2500, 1000, 500]   // 7 Tage
        for (i, value) in values.enumerated() {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            dict[DayKey.string(for: date)] = value
        }
        defaults.set(dict, forKey: "waterByDay")
        let store = WaterStore(defaults: defaults)

        let sum = values.reduce(0, +)
        let expected = sum / 7
        XCTAssertEqual(store.weeklyAverage, expected)
    }
}
