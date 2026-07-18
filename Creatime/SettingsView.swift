import SwiftUI
import UIKit

// Der SettingsSheet, geöffnet über den Gear-Button oben rechts in
// TodayView und HistoryView. Inhalt:
//   • App-Icon (jetzt nur noch Info-Karte — adaptive Icons laufen)
//   • Theme (NEU in v3)
//   • Sound-Thema
//   • Smart-Reminder-Erkennung (NEU in v3)
//   • Streak-Freeze-Info (NEU in v3)
//   • Erinnerungen / Push-Permission
//   • Urlaubsmodus
//   • Hilfe
//   • Footer mit Version & Credits

struct SettingsView: View {

    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var water
    @Environment(SupplementStore.self) private var supplements
    @Environment(ThemeManager.self) private var themeManager

    @Environment(\.dismiss) private var dismiss

    // Erinnerungszeit — Ausgangspunkt der Smart-Reminder-Heuristik und
    // manueller Fallback. Wird jetzt hier in den Settings eingestellt
    // (vorher als Footer-Chip auf dem Heute-Tab).
    @AppStorage("reminderHour") private var reminderHour: Int = 20
    @AppStorage("reminderMinute") private var reminderMinute: Int = 0

    @State private var showVacationSheet = false
    @State private var showSupplementManager = false
    @State private var scheduledHours: [Int] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {

                    // MARK: App-Icon (Info, nicht einstellbar)
                    SettingsCard(title: "App-Icon", systemImage: "app.badge.fill") {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "wand.and.stars")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 26)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Passt sich automatisch an")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                Text("Dein Creatime-Icon richtet sich nach deinem Home-Screen-Stil — Hell, Dunkel oder Getönt. Tipp: Halte das App-Icon auf dem Home-Screen lange gedrückt, um den Stil zu wechseln.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                    }

                    // MARK: Theme (NEU in v3)
                    SettingsCard(title: "Theme", systemImage: "paintbrush.fill") {
                        VStack(spacing: 8) {
                            ForEach(AppTheme.allCases) { theme in
                                Button {
                                    themeManager.setTheme(theme)
                                } label: {
                                    HStack {
                                        // Vorschau-Swatch
                                        Circle()
                                            .fill(theme.primary)
                                            .frame(width: 22, height: 22)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(.white.opacity(0.6), lineWidth: 1)
                                            )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(theme.displayName)
                                                .foregroundStyle(.primary)
                                            Text(symbolicName(theme))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if themeManager.theme == theme {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.green)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                if theme != AppTheme.allCases.last {
                                    Divider()
                                }
                            }
                        }
                    }

                    // MARK: Smart-Reminder (NEU in v3)
                    SettingsCard(title: "Smart-Reminder", systemImage: "bell.badge.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "brain.head.profile")
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 26)
                                VStack(alignment: .leading, spacing: 3) {
                                    if let typical = store.typicalIntakeHour {
                                        Text("Ich lerne deine Einnahme-Zeit")
                                            .font(.subheadline.bold())
                                        Text("Basierend auf deinen letzten Tracker-Einträgen melde ich mich bevorzugt um \(formatHour(typical)) Uhr — plus Backup-Slots 2 h vorher und nachher.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    } else {
                                        Text("Sammle noch Daten")
                                            .font(.subheadline.bold())
                                        Text("Ich lerne deine typische Einnahme-Zeit über deine nächsten 3–14 Tage. Bis dahin nutze ich deinen Standard-Reminder um 20:00 Uhr.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            if !scheduledHours.isEmpty {
                                Label(
                                    "Heute aktiv: " + scheduledHours.map(formatHour).joined(separator: " · "),
                                    systemImage: "clock.fill"
                                )
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                            }
                            Button {
                                NotificationManager.rescheduleSmartReminders(
                                    takenToday: store.takenToday,
                                    suggestedHours: store.suggestedReminderHoursToday,
                                    fallbackHour: reminderHour,
                                    fallbackMinute: reminderMinute
                                )
                                Task { await refreshScheduledHours() }
                            } label: {
                                Label("Jetzt neu planen", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }

                    // MARK: Wasser-Ziel & -Einheit
                    SettingsCard(title: "Wasser-Ziel", systemImage: "drop.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            // Tagesziel per Stepper einstellbar (in ml, 250er-Schritte)
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tägliches Ziel")
                                        .font(.subheadline.weight(.semibold))
                                    Text(waterGoalText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Stepper("",
                                        value: waterGoalBinding,
                                        in: 500...5000,
                                        step: 250)
                                    .labelsHidden()
                            }

                            Divider()

                            Text("Wähle, wie du dein Wasserziel ablesen möchtest.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Picker("Einheit", selection: waterGoalModeBinding) {
                                ForEach(WaterStore.GoalMode.allCases) { mode in
                                    Label(mode.displayName, systemImage: mode.symbol).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text("Tipp: 1 Glas ≈ 250 ml · 1 Flasche ≈ 500 ml")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // MARK: Weitere Supplements
                    SettingsCard(title: "Weitere Supplements", systemImage: "pills.fill") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Neben Kreatin kannst du weitere Supplements in deiner „Heute\u{201C}-Liste abhaken.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            // Kompakte Vorschau der aktiven Supplements
                            if supplements.enabledSupplements.isEmpty {
                                Text("Noch keine ausgewählt.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(supplements.enabledSupplements
                                        .map { "\($0.emoji) \($0.name)" }
                                        .joined(separator: "   "))
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Button {
                                showSupplementManager = true
                            } label: {
                                Label("Supplements verwalten", systemImage: "slider.horizontal.3")
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    // MARK: Streak-Freeze (NEU in v3)
                    SettingsCard(title: "Streak-Freeze", systemImage: "snowflake") {
                        HStack(spacing: 12) {
                            Image(systemName: "snowflake")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 26)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(store.freezesRemainingThisMonth) von \(CreatineStore.freezeBudgetPerMonth) übrig")
                                    .font(.subheadline.bold())
                                Text("Du kannst pro Monat bis zu \(CreatineStore.freezeBudgetPerMonth) Eis-Tage einlösen — die Streak bleibt erhalten, ohne dass es als \u{201E}Pause\u{201C} gewertet wird.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                    }

                    // MARK: Erinnerungen (inkl. Uhrzeit — aus dem Heute-Tab hierher verschoben)
                    SettingsCard(title: "Erinnerungen", systemImage: "bell.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            DatePicker(
                                "Erinnerungszeit",
                                selection: reminderTimeBinding,
                                displayedComponents: .hourAndMinute
                            )
                            .font(.subheadline.weight(.semibold))

                            Text("Creatime erinnert dich täglich zu dieser Zeit, falls du noch nicht bestätigt hast. Die Smart-Reminder-Logik nutzt sie als Ausgangspunkt.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Divider()

                            Button {
                                NotificationManager.requestPermission()
                            } label: {
                                Label("Push-Berechtigung anfragen", systemImage: "bell.badge")
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    // MARK: Urlaubsmodus
                    SettingsCard(title: "Urlaubsmodus", systemImage: "palm.tree.fill") {
                        HStack {
                            Image(systemName: "palm.tree.fill").foregroundStyle(.teal)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.vacationEnabled ? "Aktiv" : "Inaktiv")
                                    .font(.subheadline.bold())
                                if let until = store.vacationUntil, until > Date() {
                                    Text("Bis \(until, format: .dateTime.day().month(.wide))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Im Urlaub unlimited Pausen.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button("Bearbeiten") { showVacationSheet = true }
                                .buttonStyle(.bordered)
                        }
                    }

                    // MARK: Hilfe-Sektion
                    SettingsCard(title: "Hilfe", systemImage: "lightbulb.fill") {
                        Text("Sprache: Deutsch. Englische Übersetzung folgt — wenn du helfen willst, sag Bescheid.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // MARK: Footer
                    VStack(spacing: 4) {
                        Text("Creatime v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (Beta)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text("Made with ❤️ by Moritz")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(DynamicBackground())
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .accessibilityLabel("Einstellungen schließen")
                }
            }
        }
        .sheet(isPresented: $showVacationSheet) {
            VacationModeSheet()
                .presentationDetents([.medium, .large])
                .liquidGlassSheet()
        }
        .sheet(isPresented: $showSupplementManager) {
            SupplementManagerSheet()
        }
        .task {
            await refreshScheduledHours()
        }
    }

    /// Liest aktuell geplante Reminder-Stunden aus dem Notification-Center.
    private func refreshScheduledHours() async {
        scheduledHours = await NotificationManager.getScheduledReminderHours()
    }

    /// Stunde → Menschen-lesbar („20:00 Uhr").
    private func formatHour(_ h: Int) -> String {
        String(format: "%02d:00 Uhr", h)
    }

    /// Formatierter Wert passend zur aktuellen Wasser-Einheit (z. B.
    /// „3.5" für „3,5 Gläser"). Eine Nachkommastelle reicht hier.
    private func formatValue(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
            .replacingOccurrences(of: ".", with: ",")
    }

    /// Binding-Helfer für den GoalMode-Picker: liest aus dem Store,
    /// schreibt zurück in den Store bei Auswahl.
    private var waterGoalModeBinding: Binding<WaterStore.GoalMode> {
        Binding(
            get: { water.goalMode },
            set: { water.goalMode = $0 }
        )
    }

    /// Binding auf das Wasser-Tagesziel in ml (für den Stepper).
    private var waterGoalBinding: Binding<Int> {
        Binding(
            get: { water.dailyGoal },
            set: { water.dailyGoal = $0 }
        )
    }

    /// Menschen-lesbarer Zieltext, z. B. „2,5 L (10 Gläser)".
    private var waterGoalText: String {
        let liters = (Double(water.dailyGoal) / 1000)
            .formatted(.number.precision(.fractionLength(0...2)))
            .replacingOccurrences(of: ".", with: ",")
        return "\(liters) L"
    }

    /// Binding auf die Erinnerungszeit als Date. Beim Ändern werden die
    /// Notifications sofort neu geplant.
    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: Date()
                ) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderHour = comps.hour ?? 20
                reminderMinute = comps.minute ?? 0
                NotificationManager.rescheduleSmartReminders(
                    takenToday: store.takenToday,
                    suggestedHours: store.suggestedReminderHoursToday,
                    fallbackHour: reminderHour,
                    fallbackMinute: reminderMinute
                )
            }
        )
    }

    /// Symbolischer Beiname für die ThemePicker-Reihen.
    private func symbolicName(_ theme: AppTheme) -> String {
        switch theme {
        case .indigo:  return "Tiefer Indigo-Sweep"
        case .teal:    return "Frisches Teal-Laub"
        case .magenta: return "Pulsierendes Magenta"
        case .sunset:  return "Warmer Sonnenuntergang"
        case .ocean:   return "Kühler Ozean-Strom"
        }
    }
}

// MARK: - Eine Einstellungs-Karte (Glass-Surface mit Section-Titel)

private struct SettingsCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.bold())
                .foregroundStyle(Color.accentColor)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .liquidGlassCard()
    }
}

#Preview {
    SettingsView()
        .environment(CreatineStore())
        .environment(WaterStore())
        .environment(SoundsManager())
        .environment(SupplementStore())
        .environment(ThemeManager.shared)
}
