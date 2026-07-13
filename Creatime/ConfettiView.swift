import SwiftUI

/// Konfetti-Regen, ausgelöst durch einen Bool-Trigger.
///
/// Nutzung:
/// ```swift
/// @State private var celebrate = false
/// ConfettiView(trigger: celebrate)
/// // Wenn der Nutzer etwas feiert:
/// celebrate = true
/// Task { try? await Task.sleep(for: .seconds(3)); celebrate = false }
/// ```
///
/// Implementiert mit `Canvas` + `TimelineView(.animation)` für eine
/// flüssige Animation, ohne dass hunderte einzelne SwiftUI-Views
/// gleichzeitig animiert werden müssen.
struct ConfettiView: View {

    /// Bei true wird ein neuer Schub Partikel erzeugt. Partikel
    /// verschwinden automatisch nach ihrer `lifetime` — kein
    /// Stoppen nötig.
    let trigger: Bool

    @State private var particles: [Particle] = []
    @State private var reduceMotionShow = false

    /// `accessibilityReduceMotion` ist true, wenn der User in den Settings
    /// „Bewegung reduzieren" aktiviert hat. Statt 80 bunten Partikeln
    /// zeigen wir dann nur ein zentriertes ✅-Badge.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if reduceMotion {
                // Accessibility-Modus: kein Bewegungs-Overload, nur ein
                // kurzes Bestätigungs-Badge.
                if reduceMotionShow {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                        .shadow(color: .green.opacity(0.4), radius: 12)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel("Bestätigt")
                }
            } else {
                // Innerer ZStack mit `topTrailing`-Alignment:
                //  • Layer 1 (TimelineView + Canvas): füllt den ganzen
                //    Bereich mit den Partikeln. WICHTIG:
                //    `allowsHitTesting(false)` — sonst fängt die Fläche
                //    Pan-Gesten ab und blockiert das Scrollen der
                //    TodayView darunter (Bug v2).
                //  • Layer 2 (kleiner „✕"-Button oben rechts): nur sichtbar,
                //    wenn particles leben. Außerhalb dieser kleinen Region
                //    bleibt das Konfetti berührungslos, sodass Scrollen
                //    und Button-Klicks darunter weiter funktionieren.
                ZStack(alignment: .topTrailing) {
                    TimelineView(.animation) { context in
                        Canvas { ctx, size in
                            for p in particles {
                                let elapsed = context.date.timeIntervalSince(p.birth)
                                let progress = min(1, elapsed / p.lifetime)
                                guard progress < 1 else { continue }

                                // Position: nach oben raus, mit Schwerkraft nach unten.
                                let x = size.width  * p.originXFraction
                                      + p.dxFraction * size.width  * elapsed
                                let y = size.height * 0.45
                                      + p.dyFraction * size.height * elapsed
                                      + 0.5 * p.gravity * size.height * elapsed * elapsed

                                let rotation = p.rotationStart + p.rotationSpeed * elapsed

                                ctx.translateBy(x: x, y: y)
                                ctx.rotate(by: .degrees(rotation))

                                let rect = CGRect(
                                    x: -p.size.width / 2,
                                    y: -p.size.height / 2,
                                    width: p.size.width,
                                    height: p.size.height
                                )
                                ctx.fill(
                                    Path(roundedRect: rect, cornerRadius: 2),
                                    with: .color(p.color)
                                )
                            }
                        }
                    }
                    .allowsHitTesting(false)
                    .transition(.opacity)

                    if !particles.isEmpty {
                        Button {
                            dismissImmediately()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color.black.opacity(0.45))
                                .padding(8)
                                .contentShape(Circle())
                                // Material-Hintergrund garantiert Sichtbarkeit
                                // auf jedem Parent-Background (Glass, Gradient,
                                // reines Schwarz …) — sonst kann das Icon auf
                                // einem dunklen Verlauf unsichtbar werden.
                                .background(.regularMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                        .padding(.trailing, 12)
                        .transition(.opacity.combined(with: .scale))
                        .accessibilityLabel("Konfetti wegtippen")
                    }
                }
            }
        }
        // Animation-Tracking auf BEIDE State-Variablen, damit Button-Appear
        // und Badge-Appear die gleiche snappy-Curve bekommen.
        .animation(.snappy, value: reduceMotionShow)
        .animation(.snappy, value: particles.isEmpty)
        .onChange(of: trigger) { _, newValue in
            if newValue {
                if reduceMotion { showReduceMotionBadge() }
                else { burst(count: 80) }
            }
        }
    }

    // MARK: - Reduce-Motion-Pfad

    private func showReduceMotionBadge() {
        reduceMotionShow = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            reduceMotionShow = false
        }
    }

    // MARK: - Tap-to-Dismiss

    private func dismissImmediately() {
        particles.removeAll()
    }

    private func burst(count: Int) {
        let now = Date()
        let palette: [Color] = [
            .red, .orange, .yellow, .green, .mint,
            .blue, .purple, .pink
        ]
        let new = (0..<count).map { _ in
            Particle(
                originXFraction: CGFloat.random(in: 0.15...0.85),
                dxFraction: CGFloat.random(in: -0.7...0.7),
                dyFraction: CGFloat.random(in: -2.2 ... -1.4),
                gravity: 1.4,
                rotationStart: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -720...720),
                color: palette.randomElement() ?? .blue,
                size: CGSize(
                    width: CGFloat.random(in: 6...14),
                    height: CGFloat.random(in: 4...10)
                ),
                birth: now,
                lifetime: Double.random(in: 1.8...2.8)
            )
        }
        particles.append(contentsOf: new)

        // Einmaliger Cleanup nach der längsten Partikel-Lebenszeit — danach
        // sind alle Partikel garantiert `progress >= 1` und der Canvas
        // zeichnet sie ohnehin nicht mehr.
        let maxLifetime = new.map(\.lifetime).max() ?? 3.0
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(maxLifetime + 0.2))
            particles.removeAll { Date().timeIntervalSince($0.birth) >= $0.lifetime }
        }
    }

    // MARK: - Ein einzelnes Partikel

    private struct Particle: Identifiable {
        let id = UUID()
        let originXFraction: CGFloat        // 0...1 = horizontaler Start
        let dxFraction: CGFloat             // horizontale Geschwindigkeit (Bruchteil Breite/s)
        let dyFraction: CGFloat             // vertikale Geschwindigkeit   (Bruchteil Höhe/s, negativ = nach oben)
        let gravity: CGFloat                // Schwerkraft                 (Bruchteil Höhe/s²)
        let rotationStart: Double           // Anfangsdrehung in Grad
        let rotationSpeed: Double           // °/Sekunde
        let color: Color
        let size: CGSize
        let birth: Date
        let lifetime: TimeInterval
    }
}

#Preview {
    @Previewable @State var trigger = false
    ZStack {
        Color.black.opacity(0.8)
        VStack {
            Button("🎉") { trigger.toggle() }
                .font(.largeTitle)
        }
    }
    .overlay(ConfettiView(trigger: trigger))
}
