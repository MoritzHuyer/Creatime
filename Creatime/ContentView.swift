import SwiftUI

// Die Wurzel der App. Sie entscheidet als Erstes:
// Onboarding schon erledigt? Wenn nein → Willkommens-Seiten zeigen.
// Wenn ja → die normale App mit Tab-Leiste.
struct ContentView: View {
    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var waterStore
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("remindersEnabled") private var remindersEnabled: Bool = true

    // Merkt sich den zuletzt geöffneten Tab über App-Starts hinweg.
    @AppStorage("selectedTab") private var selectedTab = 0

    /// Zentrale Reschedule-Routine — wird in beiden scenePhase/tabSwitch-
    /// Handlern aufgerufen, damit Nag-Reminders beim App-Open ODER beim
    /// Tab-Wechsel auf „Heute" neu geplant werden (wenn der Tag noch
    /// offen ist).
    private func rescheduleAllReminders() {
        store.reload()
        NotificationManager.rescheduleSmartReminders(
            takenToday: store.takenToday,
            suggestedHours: store.suggestedReminderHoursToday,
            fallbackHour: reminderHour,
            fallbackMinute: reminderMinute,
            remindersEnabled: remindersEnabled
        )
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainApp
            } else {
                OnboardingView()
            }
        }
        .animation(.default, value: hasCompletedOnboarding)
    }

    private var mainApp: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Heute", systemImage: "checkmark.circle.fill")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("Fortschritt", systemImage: "chart.bar.fill")
                }
                .tag(1)

            AchievementsView()
                .tabItem {
                    Label("Erfolge", systemImage: "trophy.fill")
                }
                .tag(2)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && selectedTab == 0 {
                rescheduleAllReminders()
                // Erst-Tag-Special-Case: Wenn die App ihren aller-
                // ersten Tag nach abgeschlossenem Onboarding sieht → wird
                // eine Achievement-Stufe (days: 0 / Onboarding-Starter)
                // gefeuert. Die eigentliche Konfetti-/Sound-Animation
                // passiert in TodayView.markAsTaken(), wenn der User
                // dort den „Kreatin genommen"-Button drückt.
                _ = store.celebrateOnboardingIfFirstTake()
                Task { @MainActor in
                    await LiveActivityManager.shared.startOrUpdate(
                        streak: store.currentStreak,
                        waterML: waterStore.todayAmount,
                        waterGoalML: waterStore.dailyGoal,
                        creatineTaken: store.takenToday
                    )
                }
            } else if newPhase == .active && selectedTab != 0 {
                Task { @MainActor in
                    await LiveActivityManager.shared.end()
                }
            } else if newPhase == .background {
                Task { @MainActor in
                    await LiveActivityManager.shared.end()
                }
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            // Wenn der User auf den Heute-Tab wechselt UND es noch
            // Nag-Slots in der Zukunft gibt, neu planen (= weiter
            // „angepingt" werden, bis er das Kreatin markiert).
            if newTab == 0 {
                rescheduleAllReminders()
            }
            Task { @MainActor in
                if newTab == 0 {
                    await LiveActivityManager.shared.startOrUpdate(
                        streak: store.currentStreak,
                        waterML: waterStore.todayAmount,
                        waterGoalML: waterStore.dailyGoal,
                        creatineTaken: store.takenToday
                    )
                } else {
                    await LiveActivityManager.shared.end()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(CreatineStore())
        .environment(WaterStore())
}
