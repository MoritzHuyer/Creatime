import SwiftUI

// MARK: - WasserTrackerCard (v7 — volle Glass-Card)
//
// Volle Karte mit allen 5 UI-Sektionen:
//   1. Header "Wasser heute" + Tropfen-Icon + CustomizeLink
//   2. Goal-Row Text "X von Y ml"
//   3. Progress-Bar (dick)
//   4. HeroNumber "1,7 L" (groß)
//   5. Action-Row: − step / +250 / +500 / +1L

struct WaterTrackerCard: View {
    @Environment(WaterStore.self) private var water
    @Environment(SoundsManager.self) private var sounds

    /// Long-Press-Boost-Task: hält den Repeater am Leben, bis der Finger
    /// vom Button geht.
    @State private var boostTask: Task<Void, Never>?
    @State private var boostingAmount: Int? = nil

    /// Wurde im Onboarding gesetzt — wenn an, spiegeln wir jede Änderung
    /// nach Apple Health.
    @AppStorage("healthSyncEnabled") private var healthSyncEnabled = false

    /// Kleinste Quick-Größe = „Schritt" für den Minus-Button.
    private var stepAmount: Int {
        water.quickAmounts.min() ?? 250
    }

    /// ml → hübscher Deutscher Liter-Text (z. B. 1250 → „1,25").
    private func localizedNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
            .replacingOccurrences(of: ".", with: ",")
    }

    private func add(_ ml: Int) {
        withAnimation {
            water.addToday(ml)
        }
        sounds.playWaterSplash()
        if healthSyncEnabled {
            HealthKitManager.shared.syncTodayWater(totalML: water.todayAmount)
        }
    }

    private func startBoost(_ amount: Int) {
        boostTask?.cancel()
        boostingAmount = amount
        boostTask = Task { @MainActor in
            let target = amount
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled, boostingAmount == target else { return }
                add(amount)
            }
        }
    }

    private func stopBoost() {
        boostTask?.cancel()
        boostTask = nil
        boostingAmount = nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1) Header
            HStack {
                Label("Wasser heute", systemImage: "drop.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                NavigationLink {
                    WaterGoalSheet()
                        .presentationDetents([.medium])
                } label: {
                    Label("Anpassen", systemImage: "slider.horizontal.3")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }

            // 2) Goal-Row
            HStack(alignment: .firstTextBaseline) {
                Text("\(water.todayAmount)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                Text("von \(water.dailyGoal) ml")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if water.goalReachedToday {
                    Label("Ziel erreicht", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            // 3) Progress-Bar (dicker)
            ProgressView(value: min(1.0, water.todayProgress))
                .progressViewStyle(.linear)
                .tint(water.goalReachedToday ? .green : .blue)
                .scaleEffect(x: 1, y: 1.6, anchor: .center)

            // 4) HeroNumber
            Text("\(localizedNumber(Double(water.todayAmount) / 1000)) L")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.numericText())

            // 5) Action-Row
            HStack(spacing: 8) {
                Button {
                    add(-stepAmount)
                } label: {
                    Image(systemName: "minus")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .clipShape(Circle())
                .disabled(water.todayAmount == 0)
                .accessibilityLabel("\(stepAmount) ml weniger")

                ForEach(water.quickAmounts, id: \.self) { amount in
                    Button {
                        add(amount)
                    } label: {
                        Text("+\(amount)")
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.regular)
                    .accessibilityLabel("\(amount) ml hinzufügen")
                    .accessibilityHint("Halte gedrückt, um mehrere Portionen schnell zu addieren.")
                    .onLongPressGesture(
                        minimumDuration: 0.4,
                        perform: { startBoost(amount) },
                        onPressingChanged: { isPressing in
                            if !isPressing { stopBoost() }
                        }
                    )
                }

                Button {
                    add(1000)
                } label: {
                    Text("+1 L")
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .controlSize(.regular)
                .accessibilityLabel("1000 ml hinzufügen")
                .onLongPressGesture(
                    minimumDuration: 0.4,
                    perform: { startBoost(1000) },
                    onPressingChanged: { isPressing in
                        if !isPressing { stopBoost() }
                    }
                )
            }
        }
        .padding(16)
        .liquidGlassCard()
        .onChange(of: water.goalReachedToday) { _, isReached in
            if isReached {
                sounds.playGoalReached()
            }
        }
    }
}

// MARK: - Sheet zum Einstellen des Tagesziels

struct WaterGoalSheet: View {
    @Environment(WaterStore.self) private var water
    @Environment(\.dismiss) private var dismiss

    @State private var goal = 2500

    var body: some View {
        VStack(spacing: 16) {
            Text("Dein tägliches Wasserziel")
                .font(.headline)
                .padding(.top, 24)

            Picker("Ziel", selection: $goal) {
                ForEach(Array(stride(from: 1500, through: 4000, by: 250)), id: \.self) { ml in
                    Text(((Double(ml) / 1000).formatted(.number.precision(.fractionLength(0...2))))
                        .replacingOccurrences(of: ".", with: ",") + " L").tag(ml)
                }
            }
            .pickerStyle(.wheel)

            Button("Speichern") {
                water.dailyGoal = goal
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            goal = water.dailyGoal
        }
    }
}

#Preview {
    WaterTrackerCard()
        .environment(WaterStore())
        .padding()
}
