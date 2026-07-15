import SwiftUI
import UIKit

// MARK: - Heute-Tab (v13 — Airy / inline)
//
// Layout-Philosophie: freier Weißraum statt Card-Chrome. Jeder Bereich
// atmet für sich, Glass nur noch in der RecoveryBuddy-Ausnahme
// (wenn Streak gebrochen und Best-Streak >= 7).
//
// Reihenfolge (8 Sections, 28pt Spacing zwischen):
//   1. Vacation-Banner (subtle Pill, conditional)
//   2. Streak-Hero (🔥 + 64pt + "Tage in Folge" — INLINE)
//   3. Mood-Emoji-Reihe (5 Emojis + Labels — INLINE)
//   4. Wochenübersicht (T F S S M D M + 7 Kreise — INLINE)
//   5. "Heute erledigt / Jetzt markieren" kleine Text-Button (NICHT 60pt!)
//   6. Wasser-Hero ("1,8 Liter" + horizontaler Pill-Row — INLINE)
//   7. Pause/Freeze Menu (subtle Capsule, conditional)
//   8. Recovery-Buddy (subtle Card, conditional, nur wenn Streak gebrochen)
//   9. Tip-of-the-Day (GELBER STRIP statt Glass-Card)
//  10. Reminder-Footer-Chip mit Glocken-Icon

struct TodayView: View {
    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var water
    @Environment(SoundsManager.self) private var sounds

    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var showTimeSheet = false
    @State private var showVacationSheet = false
    @State private var showSettings = false
    @State private var confettiTrigger = false
    @State private var confettiOnboardingTrigger = false

    private var reminderTimeText: String {
        String(format: "%02d:%02d", reminderHour, reminderMinute)
    }

    private var dailyTip: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return Self.tips[dayOfYear % Self.tips.count]
    }

    private static let tips: [String] = [
        "Konstanz schlägt Timing: Die Uhrzeit ist fast egal, Hauptsache jeden Tag.",
        "Kreatin braucht 2–4 Wochen, bis der Speicher voll ist.",
        "3–5 g pro Tag reichen völlig aus — mehr bringt keinen zusätzlichen Effekt.",
        "Trink genügend Wasser — Kreatin zieht Wasser in die Muskelzellen.",
        "Verbinde Kreatin mit einer festen Routine, z. B. direkt zum Frühstück.",
    ]

    private let moods: [(emoji: String, label: String, key: String)] = [
        ("😐", "Schlecht", "neutral"),
        ("😊", "OK",       "good"),
        ("🤩", "Gut",      "great"),
        ("🥵", "Stress",   "stressed"),
        ("😴", "Erledigt", "tired"),
    ]

    private var selectedMood: String? { store.moodByDay[DayKey.today] }

    private var shouldShowRecovery: Bool {
        store.bestStreak >= 7 &&
        store.currentStreak <= 1 &&
        !store.takenToday &&
        !store.skippedToday &&
        !store.frozenToday
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DynamicBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {

                        if store.vacationEnabled, let until = store.vacationUntil {
                            VacationBanner(until: until) { showVacationSheet = true }
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // 1. Streak-Hero
                        streakHero

                        // 2. Mood-Emojis
                        moodSection

                        // 3. Week overview
                        WeekOverviewInline()

                        // 4. Hauptaktion (small button)
                        hauptaktionRow

                        // 5. Wasser-Hero
                        WasserHeroInline()

                        // 6. Pause/Freeze menu
                        pauseControl

                        // 7. RecoveryBuddy (conditional, subtle)
                        if shouldShowRecovery {
                            RecoveryBuddyInline(action: markAsTaken)
                        }

                        // 8. Tip-of-the-Day (yellow strip)
                        tipStrip

                        // 9. Reminder-Footer
                        reminderFooter
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .animation(.snappy, value: store.vacationEnabled)
                }

                ConfettiView(trigger: confettiTrigger)
            }
            .navigationTitle("Heute")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Einstellungen öffnen")
                }
            }
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
        .sheet(isPresented: $showTimeSheet) {
            ReminderTimeSheet(
                hour: $reminderHour,
                minute: $reminderMinute,
                onSave: rescheduleNotifications
            )
            .presentationDetents([.height(280)])
        }
        .sheet(isPresented: $showVacationSheet) {
            VacationModeSheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    // MARK: - Inline Sections

    private var streakHero: some View {
        VStack(spacing: 8) {
            Text("🔥")
                .font(.system(size: 48))
            Text("\(store.currentStreak)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .monospacedDigit()
                .foregroundStyle(.primary)
            Text("Tage in Folge")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(store.currentStreak) Tage Streak in Folge")
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wie fühlst du dich heute?")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(moods, id: \.key) { mood in
                    Button {
                        Haptics.tap()
                        store.setMoodToday(mood.key)
                    } label: {
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.system(size: 32))
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(selectedMood == mood.key
                                              ? Color.cyan.opacity(0.20)
                                              : Color.clear)
                                )
                            Text(mood.label)
                                .font(.caption2)
                                .foregroundStyle(selectedMood == mood.key ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .scaleEffect(selectedMood == mood.key ? 1.05 : 1.0)
                        .animation(.snappy, value: selectedMood)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(mood.label), Stimmung")
                }
            }
        }
    }

    private var hauptaktionRow: some View {
        HStack(spacing: 12) {
            Image(systemName: store.takenToday
                  ? "checkmark.circle.fill"
                  : (store.skippedToday ? "pause.circle.fill" : "circle"))
                .foregroundStyle(store.takenToday ? .green
                                 : (store.skippedToday ? .orange : .secondary))
                .font(.title3)
            Text(store.takenToday
                 ? "Heute erledigt"
                 : (store.skippedToday ? "Heute pausiert" : "Heute offen"))
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if !store.takenToday && !store.skippedToday {
                Button(action: markAsTaken) {
                    Label("Jetzt markieren", systemImage: "checkmark.circle")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
            }
        }
        .padding(.horizontal, 4)
    }

    private var tipStrip: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("Tipp des Tages")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(dailyTip)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.yellow.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 14))
    }

    private var reminderFooter: some View {
        Button { showTimeSheet = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.caption2)
                Text("Erinnerung um \(reminderTimeText) Uhr")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemFill), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Erinnerungszeit ändern, aktuell \(reminderTimeText) Uhr")
    }

    @ViewBuilder
    private var pauseControl: some View {
        if store.untouchedToday {
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
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemFill), in: Capsule())
            }
        }
    }

    // MARK: - Actions

    private func markAsTaken() {
        withAnimation {
            if let _ = store.markTodayAsTaken() {
                Haptics.successHeavy()
                sounds.playCreatineMark()
                confettiTrigger = true
                Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    confettiTrigger = false
                }
            } else {
                Haptics.success()
                sounds.playCreatineMark()
                confettiTrigger = true
                Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    confettiTrigger = false
                }
            }
            if let _ = store.celebrateOnboardingIfFirstTake() {
                Haptics.successHeavy()
                confettiOnboardingTrigger = true
                Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    confettiOnboardingTrigger = false
                }
            }
        }
        rescheduleNotifications()
    }

    private func freezeToday() {
        withAnimation {
            if store.useFreeze(for: Date()) {
                Haptics.success()
                sounds.previewTheme(sounds.theme)
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

// MARK: - Inline Week Overview (v13 — INLINE, no card wrapper)

struct WeekOverviewInline: View {
    @Environment(CreatineStore.self) private var store

    private let dayLabels = ["T", "F", "S", "S", "M", "D", "M"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                let daysBack = 6 - i
                let day = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
                let taken = store.isTaken(day)
                let skipped = store.isSkipped(day)
                let frozen = store.isFrozen(day)
                VStack(spacing: 4) {
                    Text(dayLabels[i])
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ZStack {
                        Circle()
                            .fill(fillColor(taken: taken, skipped: skipped, frozen: frozen))
                            .frame(width: 30, height: 30)
                        if taken {
                            Image(systemName: "checkmark")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        } else if skipped {
                            Image(systemName: "pause.fill")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        } else if frozen {
                            Image(systemName: "snowflake")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                        if daysBack == 0 {
                            Circle()
                                .strokeBorder(Color.accentColor, lineWidth: 1.5)
                                .frame(width: 34, height: 34)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func fillColor(taken: Bool, skipped: Bool, frozen: Bool) -> Color {
        if taken { return .green }
        if frozen { return .cyan }
        if skipped { return .orange }
        return Color(.tertiarySystemFill)
    }
}

// MARK: - Wasser-Hero (v13 — INLINE, big number + horizontal pill-row)

struct WasserHeroInline: View {
    @Environment(WaterStore.self) private var water
    @Environment(SoundsManager.self) private var sounds
    @AppStorage("healthSyncEnabled") private var healthSyncEnabled = false

    private var stepAmount: Int { water.quickAmounts.min() ?? 250 }

    private func add(_ ml: Int) {
        withAnimation { water.addToday(ml) }
        sounds.playWaterSplash()
        if healthSyncEnabled {
            HealthKitManager.shared.syncTodayWater(totalML: water.todayAmount)
        }
    }

    private func litersText(_ ml: Int) -> String {
        let v = Double(ml) / 1000
        let s = v.formatted(.number.precision(.fractionLength(0...2)))
        return s.replacingOccurrences(of: ".", with: ",") + "L"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Wasser", systemImage: "drop.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.cyan)
                Spacer()
                Text("Ziel: \(litersText(water.dailyGoal))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(litersText(water.todayAmount))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                    .contentTransition(.numericText())
                Text("von \(litersText(water.dailyGoal))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 8) {
                Button { add(-stepAmount) } label: {
                    Image(systemName: "minus")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .clipShape(Circle())
                .disabled(water.todayAmount == 0)

                ForEach(water.quickAmounts, id: \.self) { amount in
                    Button { add(amount) } label: {
                        Text("+\(amount)")
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }

            if water.goalReachedToday {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Ziel erreicht")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
    }
}

// MARK: - Recovery-Buddy (v13 — subtle airySection card)

struct RecoveryBuddyInline: View {
    @Environment(CreatineStore.self) private var store
    var action: () -> Void = {}

    private let motivationalQuotes = [
        "Jeder Neustart ist ein neuer Anfang.",
        "Die längste Reise beginnt mit einem einzigen Schritt.",
        "Du warst schon über 7 Tage am Stück dran — das bleibt in dir.",
        "Eine Pause ist kein Scheitern, sondern Atemholen.",
        "Zurückkommen ist die stärkste Übung.",
    ]

    private var quote: String {
        let burst = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return motivationalQuotes[burst % motivationalQuotes.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title2)
                    .foregroundStyle(.pink)
                Text("Streak-Neustart willkommen")
                    .font(.headline)
            }
            Text("Deine beste Streak war \(store.bestStreak) Tage.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(quote)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Haptics.tapMedium()
                action()
            } label: {
                Label("Heute Kreatin nehmen", systemImage: "checkmark.circle")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
        .airySection()
    }
}

// MARK: - Reminder Time Sheet

struct ReminderTimeSheet: View {
    @Binding var hour: Int
    @Binding var minute: Int
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTime = Date()

    var body: some View {
        VStack(spacing: 16) {
            Text("Wann sollen wir dich erinnern?")
                .font(.headline)
                .padding(.top, 24)

            DatePicker(
                "Uhrzeit",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()

            Button("Speichern") {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                hour = comps.hour ?? 20
                minute = comps.minute ?? 0
                onSave()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            selectedTime = Calendar.current.date(
                bySettingHour: hour, minute: minute, second: 0, of: Date()
            ) ?? Date()
        }
    }
}

#Preview {
    TodayView()
        .environment(CreatineStore())
        .environment(WaterStore())
}
