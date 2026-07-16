import SwiftUI
import UIKit
import UserNotifications

// MARK: - Einstellungen-Sheet (v16 — Claude Design Port)
//
// Layout matches Creatime.dc.html screen 1e (Einstellungen-Sheet):
//   1. Grabber pill + "Einstellungen" centered header + "Fertig" trailing
//   2. Section: Darstellung — SegmentedControl
//   3. Section: Kreatin — Sounds + Erinnerung ToggleRows + Uhrzeit chevron row
//   4. Section: Wasser — Tagesziel StepperRow + Health-Sync iOSToggleRow
//   5. Footer: "Creatime v1.0 (XX)"
//
// ALL AppStorage keys, NotificationManager reschedule calls, HealthKit
// bindings, water goal calls preserved 1:1 from v15.0.

struct SettingsView: View {

    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var water
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage("remindersEnabled") private var remindersEnabled: Bool = true
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("reminderHour") private var reminderHour: Int = 20
    @AppStorage("reminderMinute") private var reminderMinute: Int = 0
    @AppStorage("healthSyncEnabled") private var healthSyncEnabled: Bool = false
    @AppStorage("soundsEnabled") private var soundsEnabled: Bool = true

    @State private var showVacationSheet = false
    @State private var showReminderTimeSheet = false
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.ctInkSecondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            HStack {
                Spacer().frame(width: 52)
                Text("Einstellungen")
                    .font(.ctCardTitle)
                    .frame(maxWidth: .infinity)
                Button("Fertig") {
                    Haptics.tap()
                    dismiss()
                }
                .font(.ctBody)
                .foregroundStyle(Color.ctAccent)
                .frame(width: 52, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            ScrollView {
                VStack(spacing: 0) {
                    SectionHeader(title: "Darstellung")

                    VStack(spacing: 0) {
                        SegmentedControl(
                            options: AppearanceMode.allCases,
                            label: { $0.displayName },
                            selection: Binding(
                                get: { AppearanceMode(rawValue: appearanceModeRaw) ?? .system },
                                set: { appearanceModeRaw = $0.rawValue }
                            )
                        )
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Color.ctCardSurface, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 16)

                    Text(appearanceDescription)
                        .font(.caption).foregroundStyle(Color.ctInkSecondary)
                        .padding(.horizontal, 32).padding(.top, 6).padding(.bottom, 12)

                    SectionHeader(title: "Kreatin")
                    VStack(spacing: 0) {
                        iOSToggleRow("Sounds", detail: "Knackiger Klick beim Abhaken", isOn: $soundsEnabled.onChange { Haptics.tap() })
                        CardSeparator()
                        iOSToggleRow("Erinnerung", detail: "Push, falls bis \(formatTime(reminderHour, reminderMinute)) nicht abgehakt",
                                     isOn: $remindersEnabled.onChange { reschedule() })
                        CardSeparator()
                        Button { showReminderTimeSheet = true } label: {
                            HStack {
                                Text("Uhrzeit").font(.ctBody)
                                Spacer()
                                Text(formatTime(reminderHour, reminderMinute))
                                    .font(.ctBody).foregroundStyle(Color.ctAccent)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.ctInkTertiary)
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color.ctCardSurface, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 16)

                    SectionHeader(title: "Wasser")
                    VStack(spacing: 0) {
                        StepperRow("Tagesziel", value: water.dailyGoal, step: 250,
                                   onMinus: { adjustWaterGoal(-250) },
                                   onPlus: { adjustWaterGoal(250) })
                        CardSeparator()
                        iOSToggleRow("Mit Health synchronisieren",
                                     detail: "Wasser automatisch in Apple Health",
                                     isOn: $healthSyncEnabled.onChange { toggleHealthKit() })
                    }
                    .background(Color.ctCardSurface, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 16)

                    pushPermissionBlock

                    SectionHeader(title: "Theme")
                    VStack(spacing: 0) {
                        ForEach(AppTheme.allCases) { theme in
                            Button {
                                themeManager.setTheme(theme)
                                Haptics.tap()
                            } label: {
                                HStack {
                                    Circle().fill(theme.primary)
                                        .frame(width: 22, height: 22)
                                        .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1))
                                    Text(theme.displayName).font(.ctBody)
                                    Spacer()
                                    if themeManager.theme == theme {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.ctSuccess)
                                    }
                                }
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if theme != AppTheme.allCases.last { CardSeparator() }
                        }
                    }
                    .background(Color.ctCardSurface, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 16)

                    SectionHeader(title: "Streak-Freeze")
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(store.freezesRemainingThisMonth) von \(CreatineStore.freezeBudgetPerMonth) übrig")
                                    .font(.ctBody)
                                Text("Im Monat bis zu \(CreatineStore.freezeBudgetPerMonth) Eis-Tage.")
                                    .font(.caption)
                                    .foregroundStyle(Color.ctInkSecondary)
                            }
                            Spacer()
                            Image(systemName: "snowflake")
                                .foregroundStyle(Color.ctKreatin)
                        }
                        .padding(16)
                    }
                    .background(Color.ctCardSurface, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 16)

                    SectionHeader(title: "Urlaubsmodus")
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "palm.tree.fill")
                                .foregroundStyle(Color.ctWasser)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.vacationEnabled ? "Aktiv" : "Inaktiv")
                                    .font(.ctBody)
                                if let until = store.vacationUntil, until > Date() {
                                    Text("Bis \(until.formatted(.dateTime.day().month(.wide)))")
                                        .font(.caption).foregroundStyle(Color.ctInkSecondary)
                                } else {
                                    Text("Im Urlaub unlimited Pausen.")
                                        .font(.caption).foregroundStyle(Color.ctInkSecondary)
                                }
                            }
                            Spacer()
                            Button("Bearbeiten") { showVacationSheet = true }
                                .font(.ctSubheadline.weight(.semibold))
                                .foregroundStyle(Color.ctAccent)
                        }
                        .padding(16)
                    }
                    .background(Color.ctCardSurface, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 16)

                    Spacer(minLength: 24)

                    Text("Creatime v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (Beta)")
                        .font(.caption)
                        .foregroundStyle(Color.ctInkTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
            }
        }
        .background(Color.ctBackgroundLight)
        .presentationCornerRadius(CTLayout.sheetRadius)
        .sheet(isPresented: $showVacationSheet) {
            VacationModeSheet().presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showReminderTimeSheet) {
            ReminderTimeEditSheet(hour: $reminderHour, minute: $reminderMinute) {
                reschedule()
            }
            .presentationDetents([.height(280)])
        }
        .task {
            permissionStatus = await NotificationManager.currentAuthorizationStatus()
        }
    }

    @ViewBuilder
    private var pushPermissionBlock: some View {
        switch permissionStatus {
        case .denied:
            SectionHeader(title: "")
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Push-Berechtigung abgelehnt — aktiviere sie in den iOS-Einstellungen, damit wir dich erinnern dürfen.")
                        .font(.caption).foregroundStyle(Color.ctInkSecondary)
                }
                .padding(16)
            }
            .background(Color.ctCardSurface, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 16)
        case .notDetermined:
            SectionHeader(title: "Push")
            VStack(spacing: 0) {
                Button {
                    NotificationManager.requestPermission()
                    Task {
                        try? await Task.sleep(for: .milliseconds(600))
                        permissionStatus = await NotificationManager.currentAuthorizationStatus()
                    }
                } label: {
                    Label("Push-Berechtigung anfragen", systemImage: "bell.badge")
                }
                .buttonStyle(.plain)
                .padding(16)
            }
            .background(Color.ctCardSurface, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 16)
        default:
            EmptyView()
        }
    }

    // MARK: - Helpers (preserved verbatim from v15.0)

    private var appearanceDescription: String {
        switch AppearanceMode(rawValue: appearanceModeRaw) ?? .system {
        case .system: return "Folgt der Einstellung deines iPhones — tagsüber hell, abends dunkel."
        case .light:  return "Immer helles Design, unabhängig von der Tageszeit oder iOS-Einstellung."
        case .dark:   return "Immer dunkles Design, augenschonend bei wenig Umgebungslicht."
        }
    }

    private func reschedule() {
        NotificationManager.rescheduleSmartReminders(
            takenToday: store.takenToday,
            suggestedHours: store.suggestedReminderHoursToday,
            fallbackHour: reminderHour,
            fallbackMinute: reminderMinute,
            remindersEnabled: remindersEnabled
        )
    }

    private func toggleHealthKit() {
        if healthSyncEnabled {
            HealthKitManager.shared.requestAuthorization()
        }
    }

    private func adjustWaterGoal(_ delta: Int) {
        let new = max(500, min(6000, water.dailyGoal + delta))
        water.dailyGoal = new
        Haptics.tap()
    }

    private func formatTime(_ h: Int, _ m: Int) -> String {
        String(format: "%02d:%02d", h, m)
    }
}

// MARK: - Helper subviews

private struct SectionHeader: View {
    let title: String
    var body: some View {
        if title.isEmpty { Color.clear.frame(height: 16) }
        else {
            Text(title)
                .font(.ctSectionLabel).tracking(0.2)
                .textCase(.uppercase)
                .foregroundStyle(Color.ctInkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.top, 18)
                .padding(.bottom, 6)
        }
    }
}

private struct CardSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color.ctInkTertiary)
            .frame(height: 0.5)
            .padding(.leading, 16)
    }
}

private struct ReminderTimeEditSheet: View {
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

            DatePicker("Uhrzeit", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel).labelsHidden()

            Button("Speichern") {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                hour = comps.hour ?? 20
                minute = comps.minute ?? 0
                onSave()
                Haptics.success()
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

// MARK: - Binding helper for invoking onChange

private extension Binding where Value: Equatable {
    func onChange(_ handler: @escaping () -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { new in
                let old = self.wrappedValue
                self.wrappedValue = new
                if old != new { handler() }
            }
        )
    }
}

#Preview {
    SettingsView()
        .environment(CreatineStore())
        .environment(WaterStore())
        .environment(ThemeManager.shared)
}
