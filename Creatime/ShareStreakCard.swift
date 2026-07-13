import SwiftUI
import UIKit

// MARK: - Share-Card-Rendering
//
// Renders the current streak as a 1080 × 1080 PNG, suitable for sharing
// on Instagram, WhatsApp, X (Twitter), iMessage. Uses iOS 16+ ImageRenderer.
// Größe ist absichtlich quadratisch, weil:
//   1) Hochformat-Stories (1080 × 1920) croppen dann sauber auf Phone-Breite
//   2) Quadrat-Posts funktionieren auf allen Plattformen ohne Zuschnitt

struct ShareStreakCard: View {
    let streak: Int
    let bestStreak: Int
    let takenToday: Bool
    /// Datum formatiert (z. B. "12. Juli 2026") — gibt der Karte Aktualität.
    let dateText: String

    var body: some View {
        ZStack {
            // 1) Hintergrund-Verlauf in den Creatime-Akzentfarben.
            LinearGradient(
                colors: [
                    Color(red: 0.36, green: 0.49, blue: 1.00),   // indigo
                    Color(red: 0.49, green: 0.43, blue: 0.88),   // lila
                    Color(red: 0.59, green: 0.45, blue: 0.91),   // lavender
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 2) Helle "Sonnenschein"-Schicht oben links.
            RadialGradient(
                colors: [Color.white.opacity(0.30), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 900
            )
            .blendMode(.plusLighter)

            VStack(spacing: 0) {

                // MARK: - Brand-Kopf
                HStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                    Text("Creatime")
                    Text("·")
                    Text(dateText)
                }
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.top, 80)

                Spacer()

                // MARK: - Big-Streak-Block
                VStack(spacing: 12) {
                    Text("🔥")
                        .font(.system(size: 110))
                        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)

                    Text("\(streak)")
                        .font(.system(size: 280, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.22), radius: 14, y: 6)

                    Text(streak == 1 ? "TAG IN FOLGE" : "TAGE IN FOLGE")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.95))
                }

                Spacer()

                // MARK: - Stats-Bar (Beste Streak + Heute-Status)
                HStack(alignment: .center, spacing: 28) {
                    statColumn(value: "\(bestStreak)", label: "Beste Streak")
                    Rectangle()
                        .fill(.white.opacity(0.45))
                        .frame(width: 1.5, height: 56)
                    statColumn(
                        symbol: takenToday ? "checkmark.circle.fill" : "circle",
                        symbolTint: takenToday ? .green : .white.opacity(0.75),
                        label: takenToday ? "Heute erledigt" : "Heute offen"
                    )
                }

                Spacer()

                // MARK: - Footer
                Text("creatime.app")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.bottom, 80)
            }
            .padding(.horizontal, 60)
        }
        // Feste 1080×1080 — `ImageRenderer` rastert das so 1:1.
        .frame(width: 1080, height: 1080)
    }

    @ViewBuilder
    private func statColumn(
        value: String? = nil,
        symbol: String? = nil,
        symbolTint: Color = .white,
        label: String
    ) -> some View {
        VStack(spacing: 6) {
            if let value {
                Text(value)
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            } else if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 56))
                    .foregroundStyle(symbolTint)
            }
            Text(label.uppercased())
                .font(.system(size: 18, weight: .semibold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

// MARK: - Share-Sheet-Wrapper
//
// `UIActivityViewController` ist die UIKit-Urmutter jeder
// Share-Funktion. Sie ist robust, kennt alle Ziele (Messages,
// WhatsApp, Instagram, Mail, AirDrop, …) und braucht KEINEN
// Transferable-typ-Tanz — wir übergeben einfach das UIImage.
//
// Wir wrappen sie als `UIViewControllerRepresentable`, damit
// SwiftUI sie als Sheet presentieren kann.

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Keine `applicationActivities` — wir wollen nur die geteilten
        // Items, keine extra "Save to Files"-Buttons o. ä. (das macht
        // die Sheet bei Bild-Shares übersichtlicher).
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {
        // Nichts zu aktualisieren; das Sheet zeigt sich nach dem ersten
        // Present automatisch und lebt dann autonom.
    }
}

// MARK: - Streak-Share-Banner (im Body von HistoryView)
//
// v5: Aus der Toolbar in den Body gewandert. Grund: der Toolbar-Punkt
// verursachte ein Misreading-Pattern ("es gibt 2 für Settings") —
// weil der Share-Button neben dem Gear-Button saß und sich visuell
// ähnlich verhielt. Außerdem kam eine Paperplane-Iteration nicht
// gut an ("passt nicht richtig hinein"). Hier ist die Lösung:
//
//   1) Prominente Glass-Karte mit EXPLICITEN Text-Labels
//      ("Streak teilen" / "Deine N-Tage-Streak als Bild verschicken")
//      → kann niemand mehr mit Settings verwechseln.
//
//   2) Klassisches `square.and.arrow.up`-Symbol → universell
//      verständlich, kein Mode-Wechsel nötig.
//
//   3) Der linke Avatar-Kreis (Indigo→Lavender Gradient + weißes
//      Share-Symbol) gibt der Karte einen klaren "Action"-Charakter,
//      der sich vom Gear-Icon der Nav-Toolbar abhebt.

struct StreakShareBanner: View {
    @Environment(CreatineStore.self) private var store

    /// Das gerenderte PNG als UIImage. Solange nil, lassen wir das
    /// Sheet nicht aufgehen (sonst zeigt UIActivityViewController einen
    /// leeren Slot).
    @State private var renderedUIImage: UIImage?

    /// Steuert die Anzeige des Activity-Share-Sheets.
    @State private var showShareSheet = false

    var body: some View {
        Button {
            renderNow()
            if renderedUIImage != nil { showShareSheet = true }
        } label: {
            HStack(alignment: .center, spacing: 14) {

                // Linker Action-Avatar (Gradient + Share-Symbol). Bewusst
                // nicht das gleiche Material-Circle-Design wie das
                // Gear-Icon in der Toolbar → klare Unterscheidung.
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [
                                Color(red: 0.36, green: 0.49, blue: 1.00),  // indigo
                                Color(red: 0.59, green: 0.45, blue: 0.91),  // lavender
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 48, height: 48)
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Streak teilen")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Deine \(store.currentStreak)-Tage-Streak als Bild verschicken.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // v5-FIX-Reviewer: Glass-Surface rundherum, damit die Karte als
        // abgesetzte Section wirkt (statt loser Text-Block) — konsistent
        // mit InsightsSection / MonthCalendar / AchievementsSection, die
        // ebenfalls `liquidGlassCard()` wrappen.
        .liquidGlassCard()
        // Accessibility: Streak-Zahl MIT in das Label, damit VoiceOver
        // weiß welcher Wert geteilt wird (sonst steht da nur "Streak-Karte
        // teilen" ohne Kontext).
        .accessibilityLabel("Streak-Karte teilen, \(store.currentStreak) Tage in Folge")
        .accessibilityHint("Öffnet das Teilen-Menü mit der aktuellen Streak als Bild.")
        .sheet(isPresented: $showShareSheet) {
            if let img = renderedUIImage {
                ActivityShareSheet(items: [
                    img,
                    "Meine Creatime-Streak: \(store.currentStreak) Tage 🔥",
                ])
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        // Beim Mounten rendern und auf Daten-Änderungen reagieren.
        .task { renderNow() }
        .onChange(of: store.currentStreak) { _, _ in renderNow() }
        .onChange(of: store.takenToday)  { _, _ in renderNow() }
    }

    @MainActor
    private func renderNow() {
        let card = ShareStreakCard(
            streak: store.currentStreak,
            bestStreak: store.bestStreak,
            takenToday: store.takenToday,
            dateText: Self.todayLong()
        )
        let renderer = ImageRenderer(content: card)
        // ImageRenderer.scale ist standardmäßig die aktuelle displayScale
        // (3× auf ProMotion-IPhones). Explizit setzen ist nur nötig, wenn
        // man von diesem Default abweicht — wir brauchen es nicht.
        renderedUIImage = renderer.uiImage
    }

    /// Langes deutsches Datum (z. B. "12. Juli 2026") für die Karte.
    private static func todayLong() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMMM yyyy"
        return formatter.string(from: Date())
    }
}

#Preview("Share-Streak-Card") {
    ShareStreakCard(streak: 42, bestStreak: 89, takenToday: true, dateText: "12. Juli 2026")
        .scaleEffect(0.3)
        .frame(width: 320, height: 320)
}
