import SwiftUI

// Das Onboarding: drei Seiten beim allerersten App-Start.
// Seite 1: Willkommen  ·  Seite 2: Erinnerungszeit  ·  Seite 3: Wasserziel + Health
// Danach wird "hasCompletedOnboarding" gesetzt und die ContentView
// zeigt ab sofort die normale App.
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
        VStack {
            // TabView im "page"-Stil = seitenweises Wischen wie bei
            // App-Einführungen üblich, mit Punkten unten.
            TabView(selection: $page) {
                welcomePage.tag(0)
                reminderPage.tag(1)
                goalsPage.tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(page < 2 ? "Weiter" : "Los geht's! 🚀") {
                next()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Die drei Seiten

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Text("💪")
                .font(.system(size: 80))
            Text("Willkommen bei Creatime")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Deine tägliche Kreatin-Routine:\nein Tap am Tag, eine wachsende Streak\nund dein Wasserhaushalt im Blick.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var reminderPage: some View {
        VStack(spacing: 20) {
            Text("⏰")
                .font(.system(size: 60))
            Text("Wann nimmst du dein Kreatin?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Wir erinnern dich täglich zu dieser Uhrzeit —\naber nur, wenn du es noch nicht bestätigt hast.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
        }
        .padding(32)
    }

    private var goalsPage: some View {
        VStack(spacing: 20) {
            Text("💧")
                .font(.system(size: 60))
            Text("Dein tägliches Wasserziel")
                .font(.title2.bold())

            Picker("Ziel", selection: $waterGoal) {
                ForEach(Array(stride(from: 1500, through: 4000, by: 250)), id: \.self) { ml in
                    Text("\((Double(ml) / 1000).formatted()) L").tag(ml)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)

            Toggle(isOn: $wantsHealthSync) {
                Label("In Apple Health speichern", systemImage: "heart.fill")
                    .font(.subheadline)
            }
            .padding(.horizontal, 8)
            // Auf Geräten ohne Health (iPad) den Schalter ausblenden:
            .opacity(HealthKitManager.shared.isAvailable ? 1 : 0)
        }
        .padding(32)
    }

    // MARK: - Ablauf

    private func next() {
        withAnimation {
            if page == 1 {
                // Erinnerungszeit übernehmen und um Erlaubnis fragen —
                // genau JETZT, denn der Nutzer hat gerade eine Uhrzeit
                // gewählt und versteht, wofür die Berechtigung gut ist.
                let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                reminderHour = comps.hour ?? 20
                reminderMinute = comps.minute ?? 0
                NotificationManager.requestPermission()
            }

            if page == 2 {
                finish()
            } else {
                page += 1
            }
        }
    }

    private func finish() {
        water.dailyGoal = waterGoal
        healthSyncEnabled = wantsHealthSync
        if wantsHealthSync {
            HealthKitManager.shared.requestAuthorization()
        }
        NotificationManager.rescheduleReminders(
            takenToday: false,
            hour: reminderHour,
            minute: reminderMinute
        )
        // Dieser Schalter lässt die ContentView zur echten App umschalten:
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView()
        .environment(WaterStore())
}
