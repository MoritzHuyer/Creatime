import SwiftUI
import UIKit

// MARK: - Karten-Oberfläche (modus-abhängig)

extension Color {
    /// Oberfläche für Karten (Stat-Kacheln, Kalender, Charts), konsistent
    /// mit `airySection()`. Im Dark Mode ein weiches Dunkelgrau (#1C1F26)
    /// statt Reinschwarz — so heben sich die Karten vom dunklen Hintergrund
    /// ab (genau wie die Buddy-Karte). Im Light Mode schlicht Weiß.
    static let ctCardSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x1C / 255.0, green: 0x1F / 255.0, blue: 0x26 / 255.0, alpha: 1)
            : UIColor.white
    })
}

// MARK: - Airy Section Modifier (v13)
//
// Replaces liquidGlassCard as the default container for content/data sections.
// Drop-in alternative for v13 airy layout: in light mode it's effectively
// free whitespace (no chrome), in dark mode it's an elevation-tinted card
// with a hairline border so orbs underneath don't bleed through.
//
// Keep `.liquidGlassCard()` for truly floating/transient elements:
// banners, sticky pills, share buttons.

struct AirySection: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(scheme == .dark
                          ? Color(hex: "1C1F26")
                          : Color.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04),
                        lineWidth: 0.5
                    )
            }
            .shadow(
                color: scheme == .dark ? Color.clear : Color.black.opacity(0.05),
                radius: scheme == .dark ? 0 : 8,
                y: 2
            )
    }
}

extension View {
    func airySection() -> some View { modifier(AirySection()) }
}
