import SwiftUI

// MARK: - Wasser-Compact-Strip (Editorial — eine Zeile)
//
// Statt der vorherigen dicken Karte (Header + Progress + 42pt-Hero + 5er-
// Button-Reihe + Customize-Link) liegt das Wasser jetzt auf einer einzigen
// ruhigen Linie:
//
//   💧  1,25 L  ───●─────●───  2,5 L           [−] [+250] [+500] [+1L]
//
// Alles auf einer Höhe. Der Progressbalken liegt UNTER der Linie. Die
// Quick-Buttons sind kleinen iOS-Style-Buttons, kein zweites Hero. Die
// Goal-Anpassung und das Anpassen der Quick-Größen sind nach Settings
// gewandert (siehe SettingsView).

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
        VStack(alignment: .leading, spacing: 10) {
            // Eine ruhige Zeile: Label · BigNumber · Goal · Aktionen
            HStack(alignment: .center, spacing: 12) {
                Label {
                    Text("Wasser")
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(.tertiary)
                } icon: {
                    Image(systemName: water.goalMode.symbol)
                        .foregroundStyle(.blue)
                        .font(.subheadline)
                }
                .labelStyle(.titleAndIcon)

                Spacer()

                Text("\(localizedNumber(water.todayAmountInUnits))/\(localizedNumber(water.dailyGoalInUnits)) \(water.goalMode.displayName)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            // ProgressBar — schmal, dezent.
            WaterProgressBar(
                progress: water.todayProgress,
                tint: water.goalReachedToday ? .green : .blue
            )
            .frame(height: 4)

            // ActionRow: [- step]  [Quick-Buttons ...]
            HStack(spacing: 8) {
                Button {
                    add(-stepAmount)
                } label: {
                    Image(systemName: "minus")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 38, height: 38)
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
                            .frame(minWidth: 56, minHeight: 38)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)
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

                Spacer(minLength: 0)

                if water.goalReachedToday {
                    Label("Ziel erreicht", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .onChange(of: water.goalReachedToday) { _, isReached in
            if isReached {
                sounds.playGoalReached()
            }
        }
    }
}

// MARK: - Wasser-Progressbar (sehr dezent, 4pt hoch)

private struct WaterProgressBar: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                Capsule()
                    .fill(tint)
                    .frame(width: max(4, geo.size.width * progress))
            }
        }
    }
}

// MARK: - Sheet zum Einstellen des Tagesziels
// (Bleibt für die GoalSheet-Kompatibilität, aber wird im neuen Design
// nur noch aus SettingsView aufgerufen.)

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
