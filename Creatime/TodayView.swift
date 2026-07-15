import SwiftUI
import UIKit

// MARK: - Heute-Tab (v14 — Compact Hero + Big CTA + Progress Bar)
//
// Layout-Philosophie (unverändert): freier Weißraum statt Card-Chrome.
// v14-Änderungen ggü. v13:
//   • Mood-Sektion ENTFERNT — wird nicht mehr auf der Home angezeigt
//     (Mood-Daten bleiben im Store; Logging/Visualisierung im HistoryTab).
//   • Streak-Hero COMPACT (🔥 + Zahl + Caption in einer Zeile).
//   • Hauptaktion = prominenter BIG CTA (56 pt, state-aware).
//   • Wasser-Hero hat jetzt eine sichtbare Progress-Bar mit
//     Gradient-Tint, das nach Roh-Verhältnis Farben shiftet
//     (orange → cyan → blue → green bei Überschreiten des Ziels).
//   • Reminder-Footer-Chip unten ENTFERNT — Umzug in die Settings
//     (ganz oben, neuer „Kreatin-Erinnerung"-Block).
//
// Reihenfolge (8 Sections, 28pt Spacing zwischen):
//   1. Vacation-Banner (subtle Pill, conditional)
//   2. Streak-Hero — COMPACT horizontal (🔥 + Zahl + Caption)
//   3. Wochenübersicht (T F S S M D M + 7 Kreise — inline)
//   4. Hauptaktion als BIG primary CTA (56pt, prominent, state-aware)
//   5. Wasser-Hero mit Gradient-ProgressBar
//   6. Pause/Freeze Menu (subtle Capsule, conditional)
//   7. Recovery-Buddy (subtle airy Section, conditional)
//   8. Tip-of-the-Day (GELBER STRIP, kein Glass)

struct TodayView: View {
    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var water
    @Environment(SoundsManager.self) private var sounds

    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var showVacationSheet = false
    @State private var showSettings = false
    @State private var confettiTrigger = false
    @State private var confettiOnboardingTrigger = false

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

                        streakHero
                        WeekOverviewInline()
                        primaryCTA
                        WasserHeroInline()
                        pauseControl

                        if shouldShowRecovery {
                            RecoveryBuddyInline(action: markAsTaken)
                        }

                        tipStrip
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
        .sheet(isPresented: $showVacationSheet) {
            VacationModeSheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    // MARK: - Streak Hero (compact, horizontal)

    private var streakHero: some View {
        HStack(spacing: 12) {
            Text("🔥")
                .font(.system(size: 32))
            VStack(alignment: .leading, spacing: 0) {
                Text("\(store.currentStreak)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(.primary)
                Text("Tage in Folge")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if store.bestStreak > store.currentStreak && store.bestStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text("Beste: \(store.bestStreak)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.12), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(store.currentStreak) Tage Streak in Folge")
    }

    // MARK: - Primary CTA (BIG, prominent, state-aware)

    private var primaryCTA: some View {
        Button(action: markAsTaken) {
            HStack(spacing: 10) {
                Image(systemName: ctaIcon)
                    .font(.title3)
                Text(ctaTitle)
                    .font(.body.weight(.bold))
            }
            .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(ctaTint)
        .disabled(store.takenToday || store.skippedToday || store.frozenToday)
        .accessibilityLabel("Kreatin-Tagesstatus: \(ctaTitle)")
    }

    private var ctaIcon: String {
        if store.takenToday   { return "checkmark.circle.fill" }
        if store.skippedToday { return "pause.circle.fill" }
        if store.frozenToday  { return "snowflake" }
        return "pills.fill"
    }

    private var ctaTitle: String {
        if store.takenToday   { return "Heute erledigt" }
        if store.skippedToday { return "Heute pausiert" }
        if store.frozenToday  { return "Heute gefroren" }
        return "Jetzt Kreatin markieren"
    }

    private var ctaTint: Color {
        if store.takenToday   { return .green }
        if store.skippedToday { return .orange }
        if store.frozenToday  { return .cyan }
        return .accentColor
    }

    // MARK: - Tip Strip

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

    // MARK: - Pause / Freeze Control

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

// MARK: - Wasser-Hero (v14 — INLINE mit Gradient ProgressBar)

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

    /// Roh-Verhältnis 0.0…N (nicht capped) — damit wir den Balken visuell
    /// auf 100% deckeln, aber den Tint trotzdem auf GREEN umschalten,
    /// sobald das Ziel überschritten ist.
    private var rawRatio: Double {
        guard water.dailyGoal > 0 else { return 0 }
        return Double(water.todayAmount) / Double(water.dailyGoal)
    }

    /// Tint-Farbe für Bar UND Big-Number. Shiftet mit raw ratio:
    ///   < 0.25 → orange (fast nichts getrunken)
    ///   0.25…0.75 → cyan (im Plan)
    ///   0.75…1.0 → blue (kurz vor Ziel)
    ///   ≥ 1.0 → green (Ziel erreicht / überschritten)
    private var progressTint: Color {
        let p = rawRatio
        if p >= 1.0 { return .green }
        if p >= 0.75 { return .blue }
        if p >= 0.25 { return .cyan }
        return .orange
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
                    .foregroundStyle(progressTint)
                    .contentTransition(.numericText())
                Text("von \(litersText(water.dailyGoal))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            // NEU v14 — Gradient ProgressBar
            WasserProgressBar(progress: min(1.0, rawRatio), tint: progressTint)

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

            HStack(spacing: 6) {
                if water.goalReachedToday {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(rawRatio > 1.05
                         ? "Ziel erreicht · \(litersText(water.todayAmount - water.dailyGoal)) über Ziel"
                         : "Ziel erreicht")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                } else {
                    let remaining = max(0, water.dailyGoal - water.todayAmount)
                    Text("Noch \(litersText(remaining)) bis zum Ziel")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Wasser ProgressBar (v14 — eigenständige Sub-Component)

/// Capsule-förmige Progress-Bar mit Horizontal-Linear-Gradient.
/// Breite ist `progress` (0–1, gecapped), Tint-Farbe ist extern gesteuert
/// (kommt aus `WasserHeroInline.progressTint`).
struct WasserProgressBar: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.55), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, geo.size.width * CGFloat(progress)))
            }
        }
        .frame(height: 12)
        .animation(.snappy, value: progress)
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

#Preview {
    TodayView()
        .environment(CreatineStore())
        .environment(WaterStore())
}
