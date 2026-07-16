import SwiftUI
import UIKit

// MARK: - Heute-Tab (v16 — Claude Design Port)
//
// Layout matches Creatime.dc.html screens 1a / 1b:
//   1. VacationBanner (conditional pill — preserved from v15)
//   2. HeroStreakBlock (DateSubtitle + PageTitle + 72-pt streak + 3 pills)
//   3. CheckRingCard (Kreatin 92x92 ring + tap-to-mark)
//   4. WaterCard (44-pt amount + cyan progress bar + − / + 50-pt buttons)
//   5. Pause / Freeze Menu (conditional — preserved from v15)
//
// ALL state hooks, store calls, action methods, haptics, sounds,
// notifications, achievements, healthkit, and live-activity pushes
// preserved 1:1 from v15.0. Only the visual surfaces have changed.

struct TodayView: View {
    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var water
    @Environment(SoundsManager.self) private var sounds

    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("healthSyncEnabled") private var healthSyncEnabled = false

    @State private var showVacationSheet = false
    @State private var showSettings = false
    @State private var confettiTrigger = false

    private var dateText: String {
        Date().formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    private var securedToday: Bool {
        store.takenToday || store.skippedToday || store.frozenToday
    }

    private var waterStep: Int { water.quickAmounts.min() ?? 250 }

    var body: some View {
        ZStack {
            DynamicBackground()

            ScrollView {
                VStack(spacing: 12) {
                    if store.vacationEnabled, let until = store.vacationUntil {
                        VacationBanner(until: until) { showVacationSheet = true }
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    HeroStreakBlock(
                        dateText: dateText,
                        title: "Heute",
                        streakDays: store.currentStreak,
                        securedToday: securedToday,
                        freezesRemaining: store.freezesRemainingThisMonth,
                        bestStreak: store.bestStreak
                    )
                    .padding(.top, 24)

                    CheckRingCard(isTaken: store.takenToday, action: markAsTaken)

                    WaterCard(
                        amount: water.todayAmount,
                        goal: water.dailyGoal,
                        hasHealthSync: healthSyncEnabled,
                        onAdd: { addWater(waterStep) },
                        onSubtract: { addWater(-waterStep) },
                        step: waterStep
                    )

                    if store.untouchedToday { pauseMenuSpacer }
                }
                .ctPagePadded()
                .padding(.bottom, 96)
                .animation(.snappy, value: store.vacationEnabled)
            }

            ConfettiView(trigger: confettiTrigger)
        }
        .sheet(isPresented: $showVacationSheet) {
            VacationModeSheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .task { await pushLiveActivityUpdate() }
        .onChange(of: store.currentStreak) { _, _ in
            Task { await pushLiveActivityUpdate() }
        }
        .onChange(of: store.takenToday) { _, _ in
            Task { await pushLiveActivityUpdate() }
        }
        .onChange(of: water.todayAmount) { _, _ in
            Task { await pushLiveActivityUpdate() }
        }
        .onChange(of: water.dailyGoal) { _, _ in
            Task { await pushLiveActivityUpdate() }
        }
    }

    // MARK: - Pause / Freeze Menu (preserved)

    @ViewBuilder
    private var pauseMenuSpacer: some View {
        Menu {
            Button(action: skipToday) {
                Label(
                    store.vacationEnabled
                      ? "Heute pausieren (Urlaub unbegrenzt)"
                      : "Heute pausieren (1× diese Woche)",
                    systemImage: "pause.fill"
                )
            }
            .disabled(!store.canSkipToday)
            if store.canFreezeToday {
                Button(action: freezeToday) {
                    Label(
                        "Streak einfrieren · \(store.freezesRemainingThisMonth) von \(CreatineStore.freezeBudgetPerMonth) übrig",
                        systemImage: "snowflake"
                    )
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "ellipsis.circle")
                Text("Heute pausieren oder einfrieren")
                    .font(.footnote.weight(.medium))
            }
            .foregroundStyle(Color.ctInkSecondary)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.ctInkTertiary.opacity(0.5), in: Capsule())
        }
    }

    // MARK: - Actions (preserved verbatim from v15.0)

    private func markAsTaken() {
        withAnimation {
            if let _ = store.markTodayAsTaken() {
                Haptics.successHeavy()
                sounds.playCreatineMark()
                confettiTrigger = true
                Task { try? await Task.sleep(for: .milliseconds(100)); confettiTrigger = false }
            } else {
                Haptics.success()
                sounds.playCreatineMark()
                confettiTrigger = true
                Task { try? await Task.sleep(for: .milliseconds(100)); confettiTrigger = false }
            }
            if let _ = store.celebrateOnboardingIfFirstTake() {
                Haptics.successHeavy()
                Task { try? await Task.sleep(for: .milliseconds(100)) }
            }
        }
        rescheduleNotifications()
    }

    private func freezeToday() {
        withAnimation {
            if store.useFreeze(for: Date()) {
                Haptics.success()
                sounds.playCreatineMark()
            } else {
                Haptics.error()
            }
        }
        rescheduleNotifications()
    }

    private func skipToday() {
        guard store.canSkipToday else { return }
        withAnimation {
            _ = store.markTodayAsSkipped()
            Haptics.success()
            sounds.playCreatineMark()
        }
    }

    private func addWater(_ ml: Int) {
        withAnimation { water.addToday(ml) }
        sounds.playWaterSplash()
        if healthSyncEnabled {
            HealthKitManager.shared.syncTodayWater(totalML: water.todayAmount)
        }
    }

    private func rescheduleNotifications() {
        NotificationManager.rescheduleSmartReminders(
            takenToday: store.takenToday,
            suggestedHours: store.suggestedReminderHoursToday,
            fallbackHour: reminderHour,
            fallbackMinute: reminderMinute
        )
    }

    @MainActor
    private func pushLiveActivityUpdate() async {
        await LiveActivityManager.shared.startOrUpdate(
            streak: store.currentStreak,
            waterML: water.todayAmount,
            waterGoalML: water.dailyGoal,
            creatineTaken: store.takenToday
        )
    }
}

#Preview {
    TodayView()
        .environment(CreatineStore())
        .environment(WaterStore())
}
