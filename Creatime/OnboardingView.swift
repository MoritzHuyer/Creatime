import SwiftUI

// MARK: - Onboarding (v17 — Creatime-eigener Quiz-Funnel)
//
// Mehrstufiges „Quiz"-Onboarding im Stil moderner Health-Apps, aber
// BEWUSST in Creatime-Optik (heller Airy-Look, Theme-Indigo) und mit
// Creatime-eigenen Schritten — inkl. Wasserziel, das reine Kreatin-Apps
// nicht haben. Kein 1:1-Klon der Konkurrenz.
//
// Schritte:
//   0 Willkommen · 1 Ziel · 2 Gewicht→Dosis · 3 Training ·
//   4 Erinnerung · 5 Wasserziel · 6 Plan-Zusammenfassung
struct OnboardingView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("healthSyncEnabled") private var healthSyncEnabled = false
    /// Personalisierte Tagesdosis (aus dem Gewicht berechnet) — wird auf
    /// dem Heute-Tab als dezente Zeile angezeigt.
    @AppStorage("creatineDoseGrams") private var creatineDoseGrams = 5

    @Environment(WaterStore.self) private var water
    @Environment(ThemeManager.self) private var theme

    /// Akzentfarbe = aktives Theme (Indigo als Default) — konsistent mit
    /// den Buttons; `Color.accentColor` wäre hier System-Blau.
    private var tint: Color { theme.tint }

    private let stepCount = 7
    @State private var step = 0

    // Eingaben
    @State private var goals: Set<String> = []
    @State private var weightText = ""
    @State private var unitKg = true
    @State private var training: String? = nil
    @State private var reminderTime = Calendar.current.date(
        bySettingHour: 20, minute: 0, second: 0, of: Date()
    ) ?? Date()
    @State private var waterGoal = 2500
    @State private var wantsHealthSync = false

    // MARK: - Berechnete Werte

    private var weightKg: Double {
        let v = Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0
        return unitKg ? v : v * 0.4536   // lbs → kg
    }

    /// Empfohlene Tagesdosis in g. Orientiert an der gängigen Erhaltungs-
    /// Empfehlung (~0,03 g/kg), sicher gedeckelt auf 3–5 g. Kein
    /// medizinischer Rat — nur ein Richtwert.
    private var recommendedDose: Int {
        guard weightKg > 0 else { return 5 }
        return min(5, max(3, Int((weightKg / 20).rounded())))
    }

    /// Kann der aktuelle Schritt verlassen werden?
    private var canAdvance: Bool {
        switch step {
        case 1:  return !goals.isEmpty
        case 2:  return weightKg > 0
        case 3:  return training != nil
        default: return true
        }
    }

    private var primaryTitle: String {
        switch step {
        case 0:  return "Los geht's"
        case 6:  return "Plan starten 🚀"
        default: return "Weiter"
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            DynamicBackground()

            VStack(spacing: 0) {
                header

                // Inhalt
                ScrollView {
                    content
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .frame(maxWidth: .infinity)
                }

                // Primär-Button
                Button(action: next) {
                    Text(primaryTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canAdvance)
                .opacity(canAdvance ? 1 : 0.5)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        #if DEBUG
        // Nur Debug: Sprung zu einem Schritt via -onboardingStep N (für Screenshots).
        .onAppear {
            if let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-onboardingStep"),
               i + 1 < ProcessInfo.processInfo.arguments.count,
               let n = Int(ProcessInfo.processInfo.arguments[i + 1]) {
                step = min(max(0, n), stepCount - 1)
                if step >= 2 { weightText = "75" }
                if step >= 3 { goals = ["muscle"] }
                if step >= 3 { training = "mid" }
            }
        }
        #endif
    }

    // MARK: - Header (Zurück-Pfeil + Fortschrittsbalken)

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy) { if step > 0 { step -= 1 } }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .opacity(step == 0 ? 0 : 1)
            }
            .disabled(step == 0)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule().fill(tint)
                        .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(stepCount))
                        .animation(.snappy, value: step)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    // MARK: - Inhalt je Schritt

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0: welcomeStep
        case 1: goalStep
        case 2: weightStep
        case 3: trainingStep
        case 4: reminderStep
        case 5: waterStep
        default: planStep
        }
    }

    // 0 · Willkommen
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Text("💪").font(.system(size: 76)).padding(.top, 24)
            Text("Willkommen bei Creatime")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Deine tägliche Kreatin-Routine — mit Streak, Wasserhaushalt und Erinnerungen, die dich dranbleiben lassen.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 14) {
                FeatureRow(icon: "flame.fill", tint: .orange,
                           title: "Streak-Tracking",
                           subtitle: "Sieh deine Serie wachsen & feiere Meilensteine")
                FeatureRow(icon: "drop.fill", tint: .blue,
                           title: "Wasser im Blick",
                           subtitle: "Kreatin zieht Wasser in die Muskeln — wir tracken beides")
                FeatureRow(icon: "bell.fill", tint: .indigo,
                           title: "Smarte Erinnerungen",
                           subtitle: "Ein sanfter Stups pro Tag, bis du bestätigt hast")
            }
            .padding(.top, 8)
        }
    }

    // 1 · Ziel (Mehrfachauswahl)
    private var goalStep: some View {
        VStack(spacing: 16) {
            StepTitle("Was ist dein Ziel?", subtitle: "Wähle alles, was passt")
            ChoiceCard(icon: "dumbbell.fill", title: "Muskel & Kraft",
                       subtitle: "Kraft, Power und Muskelmasse",
                       selected: goals.contains("muscle")) { toggleGoal("muscle") }
            ChoiceCard(icon: "brain.head.profile", title: "Fokus & Kognition",
                       subtitle: "Konzentration und geistige Klarheit",
                       selected: goals.contains("focus")) { toggleGoal("focus") }
            ChoiceCard(icon: "bolt.fill", title: "Erholung",
                       subtitle: "Schnellere Regeneration nach dem Training",
                       selected: goals.contains("recovery")) { toggleGoal("recovery") }
            ChoiceCard(icon: "leaf.fill", title: "Allgemeine Gesundheit",
                       subtitle: "Langfristiges Wohlbefinden",
                       selected: goals.contains("health")) { toggleGoal("health") }
        }
    }

    // 2 · Gewicht → Dosis
    private var weightStep: some View {
        VStack(spacing: 16) {
            StepTitle("Personalisieren wir deinen Plan",
                      subtitle: "Aus deinem Gewicht berechnen wir deine Tagesdosis")

            HStack(spacing: 12) {
                TextField("z. B. 75", text: $weightText)
                    .keyboardType(.decimalPad)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
                    .background(Color.ctCardSurface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(tint.opacity(0.3), lineWidth: 1))

                // kg / lbs Umschalter
                HStack(spacing: 0) {
                    unitButton("kg", isKg: true)
                    unitButton("lbs", isKg: false)
                }
                .background(Color.ctCardSurface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5))
            }

            if weightKg > 0 {
                VStack(spacing: 4) {
                    Text("Deine empfohlene Tagesdosis")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("\(recommendedDose) g Monohydrat")
                        .font(.title.bold())
                        .foregroundStyle(tint)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                .transition(.opacity)
            }

            Text("Richtwert nach gängiger Erhaltungs-Empfehlung (~0,03 g/kg), gedeckelt auf 3–5 g. Kein medizinischer Rat.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .animation(.snappy, value: weightKg > 0)
    }

    // 3 · Trainingsfrequenz
    private var trainingStep: some View {
        VStack(spacing: 16) {
            StepTitle("Wie oft trainierst du?",
                      subtitle: "Hilft uns, deine Erinnerungen anzupassen")
            ChoiceCard(icon: "figure.walk", title: "1–2× / Woche",
                       subtitle: "Leichtes oder gelegentliches Training",
                       selected: training == "low") { training = "low" }
            ChoiceCard(icon: "figure.run", title: "3–4× / Woche",
                       subtitle: "Moderater Trainingsplan",
                       selected: training == "mid") { training = "mid" }
            ChoiceCard(icon: "figure.strengthtraining.traditional", title: "5–6× / Woche",
                       subtitle: "Ernsthaftes Training",
                       selected: training == "high") { training = "high" }
            ChoiceCard(icon: "flame.fill", title: "Täglich",
                       subtitle: "Training ist tägliche Gewohnheit",
                       selected: training == "daily") { training = "daily" }

            Text("Übrigens: Kreatin wirkt auch an Ruhetagen — tägliche Konstanz ist wichtiger als nur an Trainingstagen.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    // 4 · Erinnerung
    private var reminderStep: some View {
        VStack(spacing: 16) {
            Text("⏰").font(.system(size: 56)).padding(.top, 16)
            StepTitle("Wann sollen wir dich erinnern?",
                      subtitle: "Täglich zu dieser Zeit — nur, wenn du noch nicht bestätigt hast")
            DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
        }
    }

    // 5 · Wasserziel (Creatime-eigen)
    private var waterStep: some View {
        VStack(spacing: 16) {
            Text("💧").font(.system(size: 56)).padding(.top, 16)
            StepTitle("Dein tägliches Wasserziel",
                      subtitle: "Kreatin braucht Wasser — wir tracken es gleich mit")
            Picker("Ziel", selection: $waterGoal) {
                ForEach(Array(stride(from: 1500, through: 4000, by: 250)), id: \.self) { ml in
                    Text("\((Double(ml) / 1000).formatted()) L").tag(ml)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)

            if HealthKitManager.shared.isAvailable {
                Toggle(isOn: $wantsHealthSync) {
                    Label("In Apple Health speichern", systemImage: "heart.fill")
                        .font(.subheadline)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // 6 · Plan-Zusammenfassung
    private var planStep: some View {
        VStack(spacing: 18) {
            Text("🎯").font(.system(size: 64)).padding(.top, 20)
            Text("Dein Plan steht!")
                .font(.largeTitle.bold())
            Text("Alles startklar — los geht deine Streak.")
                .font(.subheadline).foregroundStyle(.secondary)

            VStack(spacing: 0) {
                PlanRow(icon: "pills.fill", tint: tint,
                        label: "Tagesdosis", value: "\(recommendedDose) g Monohydrat")
                Divider().padding(.leading, 52)
                PlanRow(icon: "bell.fill", tint: .indigo,
                        label: "Erinnerung", value: reminderTimeText)
                Divider().padding(.leading, 52)
                PlanRow(icon: "drop.fill", tint: .blue,
                        label: "Wasserziel", value: "\((Double(waterGoal) / 1000).formatted()) L")
            }
            .padding(.horizontal, 16)
            .background(Color.ctCardSurface, in: RoundedRectangle(cornerRadius: 16))
            .padding(.top, 8)
        }
    }

    private var reminderTimeText: String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        return String(format: "%02d:%02d Uhr", c.hour ?? 20, c.minute ?? 0)
    }

    // MARK: - Aktionen

    private func toggleGoal(_ key: String) {
        Haptics.tap()
        if goals.contains(key) { goals.remove(key) } else { goals.insert(key) }
    }

    private func unitButton(_ label: String, isKg: Bool) -> some View {
        Button {
            Haptics.tap()
            unitKg = isKg
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(unitKg == isKg ? .white : .secondary)
                .frame(width: 52, height: 52)
                .background(unitKg == isKg ? tint : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private func next() {
        guard canAdvance else { return }
        Haptics.tapMedium()

        // Beim Verlassen des Erinnerungs-Schritts direkt um Erlaubnis fragen
        // (der Nutzer versteht gerade, wofür sie ist → höhere Zusage-Rate).
        if step == 4 {
            let c = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            reminderHour = c.hour ?? 20
            reminderMinute = c.minute ?? 0
            NotificationManager.requestPermission()
        }

        if step == stepCount - 1 {
            finish()
        } else {
            withAnimation(.snappy) { step += 1 }
        }
    }

    private func finish() {
        creatineDoseGrams = recommendedDose
        water.dailyGoal = waterGoal
        healthSyncEnabled = wantsHealthSync
        if wantsHealthSync { HealthKitManager.shared.requestAuthorization() }
        NotificationManager.rescheduleReminders(
            takenToday: false, hour: reminderHour, minute: reminderMinute
        )
        Haptics.successHeavy()
        withAnimation { hasCompletedOnboarding = true }
    }
}

// MARK: - Bausteine

private struct StepTitle: View {
    let title: String
    let subtitle: String
    init(_ title: String, subtitle: String) { self.title = title; self.subtitle = subtitle }
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
}

private struct FeatureRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct ChoiceCard: View {
    @Environment(ThemeManager.self) private var theme
    let icon: String
    let title: String
    let subtitle: String
    let selected: Bool
    var action: () -> Void
    private var tint: Color { theme.tint }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(selected ? tint : .secondary)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body.weight(.semibold)).foregroundStyle(.primary)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? tint : Color(.tertiaryLabel))
            }
            .padding(16)
            .background(Color.ctCardSurface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(selected ? tint : Color.black.opacity(0.06),
                                  lineWidth: selected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PlanRow: View {
    let icon: String
    let tint: Color
    let label: String
    let value: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundStyle(tint).frame(width: 38)
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.body.weight(.semibold))
        }
        .padding(.vertical, 14)
    }
}

#Preview {
    OnboardingView()
        .environment(WaterStore())
}
