import SwiftUI

// MARK: - ContentView (v16 — Claude Design Port)
//
// Wurzelschicht der App: entscheidet zuerst Onboarding vs. Hauptansicht
// und hostet jetzt eine schwebende Glass-Pill-Tab-Bar (FloatingTabBar)
// statt des nativen SwiftUI-TabItem-Bars.
//
// Preserve verbatim from v15:
//   • @AppStorage keys (hasCompletedOnboarding, selectedTab, all
//     reminder / appearance / sound keys)
//   • scenePhase-Handler (live-activity start/end on active/background)
//   • selectedTab.onChange-Handler (reschedule auf Heute-Tab + LA update)
//   • rescheduleAllReminders identity
//   • preferredColorScheme hookup

struct ContentView: View {
    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var waterStore
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("remindersEnabled") private var remindersEnabled: Bool = true
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("selectedTab") private var selectedTab = 0

    private var preferredColorScheme: ColorScheme? {
        AppearanceMode(rawValue: appearanceModeRaw)?.preferredColorSchemeOverride
    }

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
            if hasCompletedOnboarding { mainApp }
            else { OnboardingView() }
        }
        .animation(.default, value: hasCompletedOnboarding)
    }

    private var mainApp: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .toolbar(.hidden, for: .tabBar)
                .ignoresSafeArea(.container, edges: .bottom)
                .padding(.bottom, 56)

            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 12)
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhase(newPhase)
        }
        .onChange(of: selectedTab) { _, newTab in
            handleTabSwitch(to: newTab)
        }
        .preferredColorScheme(preferredColorScheme)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0: TodayView()
        case 1: HistoryView()
        case 2: AchievementsView()
        default: TodayView()
        }
    }

    // MARK: - scenePhase + tabSwitch (preserved from v15)

    private func handleScenePhase(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            if selectedTab == 0 {
                rescheduleAllReminders()
                _ = store.celebrateOnboardingIfFirstTake()
                Task { @MainActor in
                    await LiveActivityManager.shared.startOrUpdate(
                        streak: store.currentStreak,
                        waterML: waterStore.todayAmount,
                        waterGoalML: waterStore.dailyGoal,
                        creatineTaken: store.takenToday
                    )
                }
            } else {
                Task { @MainActor in await LiveActivityManager.shared.end() }
            }
        case .background:
            Task { @MainActor in await LiveActivityManager.shared.end() }
        default:
            break
        }
    }

    private func handleTabSwitch(to newTab: Int) {
        if newTab == 0 { rescheduleAllReminders() }
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

#Preview {
    ContentView()
        .environment(CreatineStore())
        .environment(WaterStore())
}
