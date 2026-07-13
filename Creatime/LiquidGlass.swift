import SwiftUI

// MARK: - Liquid Glass Effect Helpers
//
// Baut den "Liquid Glass"-Look aus iOS 26 mit rein iOS-17-APIs nach
// (`.regularMaterial`, `.thinMaterial`, `LinearGradient` + Thin-Border).
// Vorteil: kompiliert sofort und sieht auf jedem iOS-17+-Gerät gleich aus.
// Wenn Apple später die echte `.glassEffect(_:)`-API in iOS 26 verfügbar
// macht, kann die Implementation hier geswapt werden — die Aufrufe in den
// Views ändern sich nicht.

// MARK: - Karten-Surface (Wassertracker, StatCards, Tip, Achievements, Kalender)

struct LiquidGlassCard: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                LiquidGlassShape(cornerRadius: cornerRadius, thickness: .regular)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Banner-Surface (Vacation-Banner, Todos etc.)

struct LiquidGlassBanner: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                LiquidGlassShape(cornerRadius: cornerRadius, thickness: .thick)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Sheet-Background

extension View {
    /// Wendet den "Sheet-Glass"-Effekt als `presentationBackground` an.
    /// Aufruf erfolgt in `.sheet { … }`-closures.
    func liquidGlassSheet() -> some View {
        modifier(LiquidGlassSheetBackground())
    }
}

private struct LiquidGlassSheetBackground: ViewModifier {
    func body(content: Content) -> some View {
        // `.presentationBackground` setzt den Hintergrund hinter dem Sheet-
        // Inhalt — so scheint der aufrufende Screen durch.
        content.presentationBackground(.ultraThinMaterial)
    }
}

// MARK: - Der eigentliche Glass-Painter

private struct LiquidGlassShape: View {
    let cornerRadius: CGFloat
    let thickness: Thickness

    @Environment(\.colorScheme) private var colorScheme

    enum Thickness {
        case regular   // Standard-Karten
        case thick     // Hervorhebungen (Banner, Rating-Pills)
    }

    private var material: AnyShapeStyle {
        switch thickness {
        case .regular: return AnyShapeStyle(.regularMaterial)
        case .thick:   return AnyShapeStyle(.thinMaterial)
        }
    }

    private var topHighlightOpacity: Double {
        switch thickness {
        case .regular: return colorScheme == .dark ? 0.22 : 0.35
        case .thick:   return colorScheme == .dark ? 0.32 : 0.55
        }
    }

    private var strokeOpacity: Double {
        switch thickness {
        case .regular: return colorScheme == .dark ? 0.14 : 0.22
        case .thick:   return colorScheme == .dark ? 0.20 : 0.32
        }
    }

    var body: some View {
        ZStack {
            // 1) Basis: Apple-Material (echtes Blur des Hintergrunds)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(material)

            // 2) Heller Reflexions-Streifen oben — gibt dem Glas den
            //    charakteristischen 3D-Glanz.
            LinearGradient(
                colors: [.white.opacity(topHighlightOpacity), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            // 3) Tint-Verlauf diagonal für Tiefe
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.06), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // 4) Edge-Highlight (sehr dünne, helle Linie)
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(.white.opacity(strokeOpacity), lineWidth: 0.6)
        }
    }
}

// MARK: - Convenience-Extensions

extension View {

    /// Glass-Card-Surface für "schwebende" Inhalts-Kacheln.
    /// Ersetzt das alte `Color(.secondarySystemBackground)`
    /// + `RoundedRectangle(cornerRadius: 16)`.
    func liquidGlassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(LiquidGlassCard(cornerRadius: cornerRadius))
    }

    /// Stärkeres Glass für Banner / Hero-Surfaces (Capsule-Optik).
    func liquidGlassBanner(cornerRadius: CGFloat = 100) -> some View {
        modifier(LiquidGlassBanner(cornerRadius: cornerRadius))
    }
}
