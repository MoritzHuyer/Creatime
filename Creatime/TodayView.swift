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
    @Environment(SupplementStore.self) private var supplements

    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var showVacationSheet = false
    @State private var showSettings = false
    @State private var confettiTrigger = false
    /// Aktuell gefeierter Meilenstein (zeigt das Feier-Overlay), nil = keins.
    @State private var milestone: Achievement?

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
                    VStack(alignment: .leading, spacing: 24) {

                        if store.vacationEnabled, let until = store.vacationUntil {
                            VacationBanner(until: until) { showVacationSheet = true }
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // 1. Streak-Hero
                        streakHero

                        // 2. Hauptbutton „Kreatin genommen" — groß, prominent, ganz oben
                        mainActionButton

                        // 3. Mood-Emojis (kompakt)
                        moodSection

                        // 4. Week overview
                        WeekOverviewInline()

                        // 5. Wasser-Hero (mit Ziel-Leiste)
                        WasserHeroInline()

                        // 6. Weitere Supplements (optionale Checkliste)
                        SupplementChecklist()

                        // 7. Pause/Freeze menu
                        pauseControl

                        // 7. RecoveryBuddy (conditional, subtle)
                        if shouldShowRecovery {
                            RecoveryBuddyInline(action: markAsTaken)
                        }

                        // 8. Tip-of-the-Day (yellow strip)
                        tipStrip
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .animation(.snappy, value: store.vacationEnabled)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                #if DEBUG
                .defaultScrollAnchor(
                    ProcessInfo.processInfo.arguments.contains("-scrollBottom") ? .bottom : .top
                )
                #endif

                ConfettiView(trigger: confettiTrigger)

                // Meilenstein-Feier: großes Overlay bei 3/7/14/30/60/100 Tagen
                if let milestone {
                    MilestoneCelebrationOverlay(achievement: milestone) {
                        withAnimation(.snappy) { self.milestone = nil }
                        store.acknowledgeLatestMilestone()
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
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
            #if DEBUG
            // Nur Debug: per Launch-Argument Feier-Overlay bzw. Einstellungen
            // zeigen (für automatisierte Screenshots ohne Button-Tap).
            .onAppear {
                let args = ProcessInfo.processInfo.arguments
                if args.contains("-showMilestone") {
                    milestone = Achievement.all.first { $0.days == 7 }
                }
                if args.contains("-openSettings") {
                    showSettings = true
                }
            }
            #endif
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

    // Kompaktes Moodboard: nur noch die Emojis in einer Reihe (kleiner),
    // Labels weggelassen, dezenter Titel als Caption.
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wie fühlst du dich heute?")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(moods, id: \.key) { mood in
                    Button {
                        Haptics.tap()
                        store.setMoodToday(mood.key)
                    } label: {
                        Text(mood.emoji)
                            .font(.system(size: 24))
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(selectedMood == mood.key
                                          ? Color.accentColor.opacity(0.18)
                                          : Color(.tertiarySystemFill).opacity(0.5))
                            )
                            .overlay(
                                Circle().strokeBorder(
                                    selectedMood == mood.key ? Color.accentColor : .clear,
                                    lineWidth: 1.5)
                            )
                            .frame(maxWidth: .infinity)
                            .scaleEffect(selectedMood == mood.key ? 1.08 : 1.0)
                            .animation(.snappy, value: selectedMood)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(mood.label), Stimmung")
                }
            }
        }
    }

    // Der große Haupt-Button. Drei Zustände:
    //  • offen      → prominent Akzentfarbe, "Kreatin genommen"
    //  • erledigt   → grün, deaktiviert, "Heute erledigt ✓"
    //  • pausiert   → orange getönt, deaktiviert, "Heute pausiert"
    private var mainActionButton: some View {
        Button(action: markAsTaken) {
            HStack(spacing: 10) {
                Image(systemName: store.takenToday
                      ? "checkmark.circle.fill"
                      : (store.skippedToday ? "pause.circle.fill" : "checkmark.circle"))
                    .font(.title2.weight(.semibold))
                Text(store.takenToday
                     ? "Heute erledigt"
                     : (store.skippedToday ? "Heute pausiert" : "Kreatin genommen"))
                    .font(.title3.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
        }
        .buttonStyle(.borderedProminent)
        .tint(store.takenToday ? .green : (store.skippedToday ? .orange : .accentColor))
        .disabled(store.takenToday || store.skippedToday)
        .controlSize(.large)
        .accessibilityLabel(store.takenToday ? "Heute bereits erledigt" : "Kreatin als genommen markieren")
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
        // Streak-Meilenstein (3/7/…/100) ODER Onboarding-Erfolg abgreifen.
        let streakMilestone = store.markTodayAsTaken()
        let onboardingMilestone = store.celebrateOnboardingIfFirstTake()
        let achieved = streakMilestone ?? onboardingMilestone

        withAnimation { }  // takenToday-Zustand animieren

        // Konfetti gibt es bei jedem Abhaken.
        confettiTrigger = true
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            confettiTrigger = false
        }

        if let achieved {
            // Meilenstein! Kräftigere Feier: Chime + Overlay.
            Haptics.successHeavy()
            sounds.playGoalReached()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                milestone = achieved
            }
        } else {
            // Normales Abhaken: dezenter, weicher Confirm.
            Haptics.success()
            sounds.playCreatineMark()
        }
        rescheduleNotifications()
    }

    private func freezeToday() {
        withAnimation {
            if store.useFreeze(for: Date()) {
                Haptics.success()
                sounds.playFreeze()
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

    // Deutsche Wochentags-Kürzel, dynamisch aus dem echten Datum berechnet
    // (statt fester Buchstaben) — so stimmt die Reihe immer mit heute überein.
    private static let germanCalendar: Calendar = {
        var cal = Calendar.current
        cal.locale = Locale(identifier: "de_DE")
        return cal
    }()

    private func weekdayLabel(for date: Date) -> String {
        let symbols = Self.germanCalendar.veryShortStandaloneWeekdaySymbols
        let weekday = Self.germanCalendar.component(.weekday, from: date) // 1 = Sonntag
        return symbols[weekday - 1]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                let daysBack = 6 - i
                let day = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
                let taken = store.isTaken(day)
                let skipped = store.isSkipped(day)
                let frozen = store.isFrozen(day)
                VStack(spacing: 4) {
                    Text(weekdayLabel(for: day))
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
        let wasReached = water.goalReachedToday
        withAnimation { water.addToday(ml) }
        // Ziel gerade frisch erreicht → freundlicher Chime statt nur Splash.
        if !wasReached && water.goalReachedToday {
            sounds.playGoalReached()
        } else {
            sounds.playWaterSplash()
        }
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
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                    .contentTransition(.numericText())
                Text("von \(litersText(water.dailyGoal))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int((water.todayProgress * 100).rounded()))%")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(water.goalReachedToday ? .green : .blue)
                    .contentTransition(.numericText())
            }

            // Ziel-Leiste: füllt sich blau; bei 100 % komplett voll & grün.
            WaterGoalBar(progress: water.todayProgress, reached: water.goalReachedToday)

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

            // Mengen-Tipp
            Text("Tipp: 1 Glas ≈ 250 ml · 1 Flasche ≈ 500 ml")
                .font(.caption2)
                .foregroundStyle(.secondary)

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

// MARK: - Wasser-Ziel-Leiste
//
// Horizontale Leiste, die sich proportional zum Tagesziel blau füllt.
// Bei 100 % ist die ganze Leiste voll und wechselt auf Grün — der
// Nutzer sieht auf einen Blick "geschafft".
struct WaterGoalBar: View {
    let progress: Double   // 0.0 … 1.0
    let reached: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                Capsule()
                    .fill(reached ? Color.green : Color.blue)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
                    .animation(.snappy, value: progress)
            }
        }
        .frame(height: 12)
        .accessibilityLabel("Wasser-Fortschritt \(Int((progress * 100).rounded())) Prozent")
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

// MARK: - Supplement-Checkliste (optionale Zusatz-Supplements)
//
// Zeigt die in den Einstellungen aktivierten Zusatz-Supplements als
// Tages-Checkliste. Kreatin bleibt der große Haupt-Button oben — das
// hier ist die dezente Ergänzung darunter.
struct SupplementChecklist: View {
    @Environment(SupplementStore.self) private var supplements
    @Environment(SoundsManager.self) private var sounds

    var body: some View {
        let items = supplements.enabledSupplements
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Weitere Supplements")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(supplements.takenTodayCount)/\(items.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        let taken = supplements.isTakenToday(item.id)
                        Button {
                            Haptics.tap()
                            supplements.toggleToday(item.id)
                            sounds.playWaterSplash()
                        } label: {
                            HStack(spacing: 12) {
                                Text(item.emoji)
                                    .font(.title3)
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("\(supplements.takenCountThisWeek(item.id))/7 diese Woche")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: taken ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(taken ? .green : .secondary)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < items.count - 1 {
                            Divider().padding(.leading, 42)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .background(Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

// MARK: - Meilenstein-Feier-Overlay
//
// Vollflächiges Overlay, das bei einem neu erreichten Streak-Meilenstein
// (3/7/14/30/60/100 Tage) erscheint: abgedunkelter Hintergrund + eine
// hereinfedernde Karte mit großem Emoji, Titel und motivierender Zeile.
struct MilestoneCelebrationOverlay: View {
    let achievement: Achievement
    var onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 16) {
                Text(achievement.emoji)
                    .font(.system(size: 84))
                    .scaleEffect(appeared ? 1 : 0.4)
                    .rotationEffect(.degrees(appeared ? 0 : -12))

                VStack(spacing: 6) {
                    Text("Meilenstein erreicht!")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(achievement.title)
                        .font(.title.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text(achievement.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: onDismiss) {
                    Text("Weiter 🎉")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 4)
            }
            .padding(28)
            .frame(maxWidth: 320)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.25), radius: 30, y: 10)
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) {
                appeared = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Meilenstein erreicht: \(achievement.title), \(achievement.subtitle)")
    }
}

#Preview {
    TodayView()
        .environment(CreatineStore())
        .environment(WaterStore())
        .environment(SoundsManager())
        .environment(SupplementStore())
}

#Preview("Meilenstein") {
    MilestoneCelebrationOverlay(achievement: Achievement.all[2]) {}
}
