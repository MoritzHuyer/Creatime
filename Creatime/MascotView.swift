import SwiftUI

// MARK: - Krea · Creatime-Maskottchen
//
// „Krea" sitzt unten rechts auf dem Fortschritt-Tab. Es ist KEIN Chat-Bot
// und keine zusätzliche Notification-Quelle — Charm und Kontext-Begleiter.
//
// v·Update: Der speech-Pool liegt jetzt in `Shared/KreaFace.swift`
// (App + Widget). Die Auswahl läuft über `KreaSpeechProvider`, mit
// Anti-Repetition gegen die letzten 4 gezeigten Zeilen.
//
// Bewusste Designentscheidungen:
//   • Erscheint NUR auf HistoryView (TodayView ist tabu).
//   • Erstkontakt: am Ende des Onboardings.
//   • KEIN Auto-Popup (würde scrollen + Layout-Berechnungen stören).
//   • 1–2 Zeilen pro Spruch, KEIN Coach-Ton.

struct MascotView: View {
    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var water
    @Environment(ThemeManager.self) private var themeManager

    @State private var showBubble: Bool = false
    @State private var line: KreaSpeech = .neutralSteady

    private var tint: Color { themeManager.tint }

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if showBubble {
                KreaBubble(line: line, tint: tint) {
                    withAnimation(.snappy) { showBubble = false }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Button(action: tapKrea) {
                KreaFaceView(
                    tint: tint,
                    size: 56,
                    mood: line.mood,
                    breathes: true,
                    // v19 — reaktive Krea-Reaction: Wird automatisch
                    // vom CreatineStore befüllt, sobald markTodayAsTaken
                    // gefeuert oder in reload() eine Compassion-Detection
                    // stattgefunden hat. KreaFaceView.task(id:) cleared
                    // nach 3.2 s über den Callback — siehe unten.
                    reaction: store.lastKreaReaction,
                    reactionDate: store.lastKreaReactionDate,
                    onCelebrateComplete: { store.clearKreaReaction() }
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Krea, dein Creatime-Maskottchen")
            .accessibilityHint("Tippen für eine kontextuelle Nachricht")
        }
        .padding(.trailing, 12)
        .padding(.bottom, 16)
    }

    /// Tap -> Provider-Output anzeigen + in RecentList aufnehmen.
    private func tapKrea() {
        Haptics.tap()
        let ctx = KreaContextBuilder.fromStores(
            takenToday: store.takenToday,
            streak: store.currentStreak,
            saturation: store.creatineSaturation,
            daysUntilSaturated: store.daysUntilSaturated,
            moodByDay: store.moodByDay,
            waterProgress: water.todayProgress,
            waterProgressRaw: water.todayProgressRaw,
            waterGoalReached: water.goalReachedToday,
            hadStreakMilestone: store.currentMilestoneDescription != nil
        )
        let speech = KreaSpeechProvider.speak(for: ctx)
        KreaSpeechProvider.recordShown(speech)
        line = speech
        withAnimation(.snappy) { showBubble = true }
        Task {
            try? await Task.sleep(for: .seconds(6))
            withAnimation(.snappy) { showBubble = false }
        }
    }
}

// MARK: - Sprechblase (Floating Tooltip)
//
// Bewusst schlank: ein Airy-Rounded-Card mit Krea-Label + Inhalt + Close.
// Tail nach unten-rechts wie ein Chat-Bubble.

struct KreaBubble: View {
    let line: KreaSpeech
    let tint: Color
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("Krea")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                Spacer()
                Button {
                    Haptics.tap()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sprechblase schließen")
            }
            // Sanfter Typewriter-Effekt: Zeichen-für-Zeichen-Render über
            // 0.4 s. Wirkt wie Krea spricht — klein, aber menschlich.
            KreaTypedText(text: line.text, tint: tint)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: 280, alignment: .leading)
        .background(
        // Card-Surface — bewusst konsistent mit den übrigen BaseCards
        // der HistoryView (PhotoStreakView, HistoryCharts nutzen ebenfalls
        // `Color.ctCardSurface`). Das Token ist im Creatime-Target global
        // verfügbar (Definition in SubtleCard.swift) und adaptiert Light/
        // Dark automatisch via UIColor-Trait-Init. Voll deckend.
            Color.ctCardSurface,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.2), radius: 8, x: 0, y: 4)
        // „Schwanz" der Sprechblase nach unten-rechts.
        .overlay(alignment: .bottomTrailing) {
            bubbleTail(tint: tint)
                .offset(x: -10, y: 6)
        }
    }

    @ViewBuilder
    private func bubbleTail(tint: Color) -> some View {
        let shape = Path { p in
            p.move(to: CGPoint(x: 24, y: 0))
            p.addLine(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: 12, y: 12))
            p.closeSubpath()
        }
        ZStack {
            shape.fill(Color.primary.opacity(0.05))
            shape.stroke(tint.opacity(0.3), lineWidth: 1)
        }
        .frame(width: 14, height: 12)
    }
}

// MARK: - Typewriter-Effekt für die Sprechblase
//
// Bewusst NICHT in Shared/, weil es UI-Spezifika hat (Text-Update
// Intervall). Krea "tippt" 1 Zeichen pro Frame ~28 ms — bei 60 Zeichen
// ist das nach ~1.7 s fertig. Wirkt ruhig, nicht hektisch.

private struct KreaTypedText: View {
    let text: String
    let tint: Color
    @State private var visibleCount: Int = 0

    var body: some View {
        Text(String(text.prefix(visibleCount)))
            .onAppear { animate() }
            .accessibilityLabel(text)
    }

    private func animate() {
        visibleCount = 0
        Task {
            for i in 1...text.count {
                visibleCount = i
                try? await Task.sleep(for: .milliseconds(28))
            }
        }
    }
}
