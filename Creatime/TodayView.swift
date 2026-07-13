import SwiftUI
import UIKit

// MARK: - Heute-Tab (Editorial-Hero-Stil)
//
// Layout-Philosophie: ein Hero-Block mit der Streak-Zahl dominiert den
// oberen Bereich. ALLES andere — Mood-Emoji, Wasser, Hauptaktion —
// ordnet sich darunter an, mit großzügigem Abstand statt Karten-Ballung.
//
// Reihenfolge (visuelle Hierarchie, von groß nach klein):
//   1. Vacation-Banner (selten, kompakt)
//   2. HERO-Streak: 🔥 + riesige Zahl + "Tage in Folge"
//   3. Mood-Emoji-Reihe (inline, kein Card-Rahmen)
//   4. Wochenübersicht (kompakt, inline)
//   5. Recovery-Buddy (nur wenn getriggert — soft inline)
//   6. GROSSE Hauptaktion (full-width, prominent)
//   7. Pause / Freeze Link (typografisch klein)
//   8. Wasser kompakt — eine Zeile mit Inline-Aktionen
//   9. Reminder-Footer (sehr klein)
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

    private var reminderTimeText: String {
        String(format: "%02d:%02d", reminderHour, reminderMinute)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Editorial = ruhiger Hintergrund. Kein knalliger Gradient,
                // der mit den Karten konkurriert. Sanftes systemGrouped.
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {

                        vacationBanner

                        // HERO-Streak — das visuelle Zentrum.
                        heroStreak
                            .padding(.top, 12)

                        // Mood-Reihe — kein Card-Rahmen mehr, einfach 5 Emojis.
                        MoodEmojiPicker()
                            .padding(.top, 28)

                        // Wochenübersicht — bleibt kompakt, inline.
                        WeekOverview()
                            .padding(.top, 28)

                        // Recovery-Buddy — nur wenn getriggert.
                        RecoveryBuddyCard(action: markAsTaken)
                            .padding(.top, 8)

                        // Hauptaktion — groß, einheitlich 60pt hoch.
                        mainActionButton
                            .padding(.top, 32)

                        // Pause/Freeze — kleines typografisches Menü.
                        pauseControl
                            .padding(.top, 8)

                        // Wasser — kompakter Strip statt voller Karte.
                        WaterTrackerCard()
                            .padding(.top, 36)

                        // Reminder-Footer.
                        reminderFooter
                            .padding(.top, 28)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity)
                    .animation(.snappy, value: store.vacationEnabled)
                }

                ConfettiView(trigger: confettiTrigger)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Einstellungen öffnen")
                }
            }
            .navigationTitle("Heute")
            .navigationBarTitleDisplayMode(.inline)
            .task { @MainActor in
                await pushLiveActivityUpdate()
            }
            .onChange(of: store.currentStreak) { _, _ in
                Task { @MainActor in await pushLiveActivityUpdate() }
            }
            .onChange(of: store.takenToday) { _, _ in
                Task { @MainActor in await pushLiveActivityUpdate() }
            }
            .onChange(of: water.todayAmount) { _, _ in
                Task { @MainActor in await pushLiveActivityUpdate() }
            }
            .onChange(of: water.dailyGoal) { _, _ in
                Task { @MainActor in await pushLiveActivityUpdate() }
            }
        }
        .sheet(isPresented: $showTimeSheet) {
            ReminderTimeSheet(
                hour: $reminderHour,
                minute: $reminderMinute,
                onSave: rescheduleNotifications
            )
            .presentationDetents([.height(280)])
            .liquidGlassSheet()
        }
        .sheet(isPresented: $showVacationSheet) {
            VacationModeSheet()
                .presentationDetents([.medium, .large])
                .liquidGlassSheet()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Vacation Banner (sehr kompakt, kein Card-Look)

    @ViewBuilder
    private var vacationBanner: some View {
        if store.vacationEnabled, let until = store.vacationUntil {
            Button {
                showVacationSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "palm.tree.fill")
                        .foregroundStyle(.teal)
                        .font(.subheadline)
                    Text("Urlaubsmodus bis \(until, format: .dateTime.day().month(.abbreviated))")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.tertiarySystemFill), in: Capsule())
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - HERO STREAK

    private var heroStreak: some View {
        VStack(spacing: 4) {
            Text("🔥")
                .font(.system(size: 56))
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(store.currentStreak)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .monospacedDigit()
                Text("Tage")
                    .font(.title.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Text("in Folge")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(store.currentStreak) Tage Streak in Folge")
    }

    // MARK: - Hauptaktion (60pt hoch, full-width)

    @ViewBuilder
    private var mainActionButton: some View {
        if store.skippedToday {
            Button {} label: {
                Label("Heute pausiert", systemImage: "pause.circle.fill")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(true)
        } else if store.takenToday {
            Button {} label: {
                Label("Heute erledigt", systemImage: "checkmark.circle.fill")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(true)
        } else {
            Button(action: markAsTaken) {
                Label("Kreatin genommen", systemImage: "checkmark.circle")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
    }

    /// Pause/Freeze — explicit klein, typografisch. Kein zweite Button-Reihe.
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
                    Image(systemName: "pause.circle")
                        .font(.caption)
                    Text("Heute pausieren oder einfrieren")
                        .font(.footnote)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Reminder-Footer

    private var reminderFooter: some View {
        Button {
            showTimeSheet = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bell")
                    .font(.caption2)
                Text("Erinnerung um \(reminderTimeText) Uhr")
                    .font(.caption)
            }
            .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Aktionen

    private func markAsTaken() {
        withAnimation {
            if let achievement = store.markTodayAsTaken() {
                Haptics.successHeavy()
                sounds.playCreatineMark()
                confettiTrigger = true
                Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    confettiTrigger = false
                }
                _ = achievement
            } else {
                Haptics.success()
                sounds.playCreatineMark()
                confettiTrigger = true
                Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    confettiTrigger = false
                }
            }
            if let onboarding = store.celebrateOnboardingIfFirstTake() {
                Haptics.successHeavy()
                confettiOnboardingTrigger.toggle()
                Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    confettiOnboardingTrigger = false
                }
                _ = onboarding
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

    @State private var confettiOnboardingTrigger = false

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

// MARK: - Wochenübersicht (Editorial — klein, inline, dezent)

struct WeekOverview: View {
    @Environment(CreatineStore.self) private var store

    var body: some View {
        // Sehr kompakte Take-Streak Indicators. Kein eigener Card-Rahmen
        // mehr — schweben einfach zwischen Hero und Aktion.
        HStack(spacing: 14) {
            ForEach(0..<7, id: \.self) { index in
                let daysBack = 6 - index
                let day = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
                let taken = store.isTaken(day)
                let skipped = store.isSkipped(day)

                VStack(spacing: 6) {
                    Text(day, format: .dateTime.weekday(.narrow))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ZStack {
                        Circle()
                            .fill(fillColor(taken: taken, skipped: skipped))
                            .frame(width: 26, height: 26)

                        if taken {
                            Image(systemName: "checkmark")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        } else if skipped {
                            Image(systemName: "pause.fill")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }

                        if daysBack == 0 {
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 1.5)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func fillColor(taken: Bool, skipped: Bool) -> Color {
        if taken { return .green }
        if skipped { return .orange }
        return Color(.tertiarySystemFill)
    }
}

// MARK: - Sheet zum Einstellen der Erinnerungszeit

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
