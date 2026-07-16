import SwiftUI

// MARK: - Onboarding (v16 — Claude Design Port)
//
// Same 3 pages as v15 (Willkommen · Erinnerungszeit · Wasserziel/Health)
// with new visual surfaces + CLAUDE-style HeroStreakBlock-style page
// titles + BaseCard where appropriate.
//
// All state hooks + finish() logic preserved 1:1 from v15.0.

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("healthSyncEnabled") private var healthSyncEnabled = false

    @Environment(WaterStore.self) private var water

    @State private var page = 0
    @State private var reminderTime = Calendar.current.date(
        bySettingHour: 20, minute: 0, second: 0, of: Date()
    ) ?? Date()
    @State private var waterGoal = 2500
    @State private var wantsHealthSync = false

    var body: some View {
        ZStack {
            DynamicBackground()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    reminderPage.tag(1)
                    goalsPage.tag(2)
                }
                .tabViewStyle(.page).indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(page < 2 ? "Weiter" : "Los geht's! 🚀", action: next)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom, 32)
                    .padding(.horizontal, 32)
            }
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Text("💪").font(.system(size: 80))
            Text("Willkommen bei Creatime")
                .font(.ctPageTitle)
                .multilineTextAlignment(.center)
            Text("Deine tägliche Kreatin-Routine: ein Tap am Tag, eine wachsende Streak und dein Wasserhaushalt im Blick.")
                .font(.ctSubheadline)
                .foregroundStyle(Color.ctInkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var reminderPage: some View {
        VStack(spacing: 20) {
            Text("⏰").font(.system(size: 60))
            Text("Wann nimmst du dein Kreatin?")
                .font(.ctCardTitle)
                .multilineTextAlignment(.center)
            Text("Wir erinnern dich täglich zu dieser Uhrzeit — aber nur, wenn du es noch nicht bestätigt hast.")
                .font(.ctSubheadline)
                .foregroundStyle(Color.ctInkSecondary)
                .multilineTextAlignment(.center)

            DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel).labelsHidden()
        }
        .padding(32)
    }

    private var goalsPage: some View {
        VStack(spacing: 20) {
            Text("💧").font(.system(size: 60))
            Text("Dein tägliches Wasserziel")
                .font(.ctCardTitle)

            Picker("Ziel", selection: $waterGoal) {
                ForEach(Array(stride(from: 1500, through: 4000, by: 250)), id: \.self) { ml in
                    Text("\((Double(ml) / 1000).formatted()) L").tag(ml)
                }
            }
            .pickerStyle(.wheel).frame(height: 120)

            Toggle(isOn: $wantsHealthSync) {
                Label("In Apple Health speichern", systemImage: "heart.fill")
                    .font(.ctSubheadline)
            }
            .padding(.horizontal, 8)
            .opacity(HealthKitManager.shared.isAvailable ? 1 : 0)
        }
        .padding(32)
    }

    private func next() {
        withAnimation {
            if page == 1 {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                reminderHour = comps.hour ?? 20
                reminderMinute = comps.minute ?? 0
                NotificationManager.requestPermission()
            }
            if page == 2 { finish() } else { page += 1 }
        }
    }

    private func finish() {
        water.dailyGoal = waterGoal
        healthSyncEnabled = wantsHealthSync
        if wantsHealthSync { HealthKitManager.shared.requestAuthorization() }
        NotificationManager.rescheduleReminders(
            takenToday: false,
            hour: reminderHour,
            minute: reminderMinute
        )
        Haptics.successHeavy()
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView().environment(WaterStore())
}
