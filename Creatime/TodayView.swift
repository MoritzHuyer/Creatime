import SwiftUI
import UIKit

// MARK: - Heute-Tab (v7 — Glass-Card-Stil)
//
// Layout-Philosophie: klare Gliederung in 7–8 Karten mit großzügigem
// Abstand (22pt). Jede Karte nutzt `.liquidGlassCard()` als Hintergrund.
//
// Reihenfolge (von oben nach unten):
//   1. Vacation-Banner (nur wenn aktiv)
//   2. Streak-Karte (🔥 + 64pt-Zahl + "Tage in Folge")
//   3. Mood-Emoji-Reihe (5 Emojis + Labels in Glass-Card)
//   4. Wochenübersicht (7 Kreise für letzte 7 Tage)
//   5. Recovery-Buddy-Card (nur wenn getriggert, pink Glass)
//   6. Großer Hauptbutton ("Kreatin genommen", 60pt)
//   7. Pause/Freeze Menu (typografisch klein)
//   8. WasserTrackerCard (volle Glass-Karte)
//   9. Tip-of-the-Day Card
//  10. Reminder-Zeit-Chip (klein, am Foot)

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

    /// Ein Tipp pro Tag: Die Nummer des Tages im Jahr (1–366) bestimmt,
    /// welcher Tipp dran ist — so wechselt er automatisch täglich.
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

    var body: some View {
        NavigationStack {
            ZStack {
                DynamicBackground()

                ScrollView {
                    VStack(spacing: 22) {

                        if store.vacationEnabled, let until = store.vacationUntil {
                            VacationBanner(until: until) {
                                showVacationSheet = true
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        streakCard

                        MoodEmojiPicker()
                            .liquidGlassCard()

                        WeekOverview()
                            .liquidGlassCard()

                        RecoveryBuddyCard(action: markAsTaken)
                            .liquidGlassCard()

                        mainActionButton

                        pauseControl

                        WaterTrackerCard()

                        TipCard(tip: dailyTip)
                            .liquidGlassCard()

                        reminderFooter
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity)
                    .animation(.snappy, value: store.vacationEnabled)
                }

                ConfettiView(trigger: confettiTrigger)
            }
            .navigationTitle("Heute")
            .navigationBarTitleDisplayMode(.large)
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

    // MARK: - Streak-Karte (Glass-Card)

    private var streakCard: some View {
        VStack(spacing: 6) {
            Text("🔥")
                .font(.system(size: 48))
            Text("\(store.currentStreak)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .monospacedDigit()
            Text("Tage in Folge")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .liquidGlassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(store.currentStreak) Tage Streak in Folge")
    }

    // MARK: - Hauptaktion (60pt hoch, full-width)

    @ViewBuilder
    private var mainActionButton: some View {
        if store.skippedToday {
            Button {} label: {
                Label("Heute pausiert", systemImage: "pause.circle.fill")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(true)
        } else if store.takenToday {
            Button {} label: {
                Label("Heute erledigt ✓", systemImage: "checkmark.circle.fill")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(true)
        } else {
            Button(action: markAsTaken) {
                Label("Kreatin genommen", systemImage: "checkmark.circle")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
    }

    // MARK: - Pause/Freeze Menu

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

    // MARK: - Reminder-Footer-Chip

    private var reminderFooter: some View {
        Button {
            showTimeSheet = true
        } label: {
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

    // MARK: - Aktionen

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

// MARK: - Wochenübersicht (Glass-Card-Inhalt)

struct WeekOverview: View {
    @Environment(CreatineStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Diese Woche", systemImage: "calendar")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(0..<7, id: \.self) { index in
                    let daysBack = 6 - index
                    let day = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
                    let taken = store.isTaken(day)
                    let skipped = store.isSkipped(day)
                    let frozen = store.isFrozen(day)

                    VStack(spacing: 6) {
                        Text(day, format: .dateTime.weekday(.narrow))
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ZStack {
                            Circle()
                                .fill(fillColor(taken: taken, skipped: skipped, frozen: frozen))
                                .frame(width: 30, height: 30)

                            if taken {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            } else if skipped {
                                Image(systemName: "pause.fill")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            } else if frozen {
                                Image(systemName: "snowflake")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }

                            if daysBack == 0 {
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 1.5)
                                    .frame(width: 34, height: 34)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
    }

    private func fillColor(taken: Bool, skipped: Bool, frozen: Bool) -> Color {
        if taken { return .green }
        if frozen { return .cyan }
        if skipped { return .orange }
        return Color(.tertiarySystemFill)
    }
}

// MARK: - Tip-of-the-Day (Glass-Card-Inhalt)

struct TipCard: View {
    let tip: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("Tipp des Tages")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(tip)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
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
