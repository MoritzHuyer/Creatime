import SwiftUI

// MARK: - Dynamic Background (v11 — Bold Sports-App)
//
// Mode-aware gradient-less background mit Theme-gebundenen Glow-Orbs.
// Ersetzt die matschige LinearGradient(systemIndigo.0.10 → systemTeal.0.06),
// die im Dark-Mode unsichtbar wurde (Color(.systemIndigo).opacity(0.10) über
// einem schwarzen Hintergrund verschwindet praktisch komplett).
//
// LIGHT-MODE: Soft off-white Base (#F7F8FA) + 3 sanfte Theme-Orbs (16% Opacity, 280pt)
// DARK-MODE:  Tiefer Solid-Base (#0F1218) + 3 leuchtende Theme-Orbs (40% Opacity, 320pt)
//
// Performance: 3 statische `.blur(radius: 80)`-Kreise. Bewusst KEINE Animation —
// Animation würde auf Mid-Range-Geräten ruckeln, und der Effekt wirkt auch
// ohne Bewegung „lebendig", weil die Glass-Cards darüber die Orbs „refraktieren".

struct DynamicBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        ZStack {
            // 1) Mode-aware solid base
            baseColor
                .ignoresSafeArea()

            // 2) Three glowing theme-orb circles (Top-Left, Right, Bottom-Center)
            ForEach(OrbPosition.allCases, id: \.self) { position in
                Circle()
                    .fill(themeManager.theme.primary.opacity(orbOpacity))
                    .frame(width: orbDiameter, height: orbDiameter)
                    .blur(radius: 80)
                    .offset(position.offset)
            }
        }
    }

    private var baseColor: Color {
        colorScheme == .dark
            ? Color(hex: "0F1218")
            : Color(hex: "F7F8FA")
    }

    private var orbOpacity: Double {
        // v13-Airy: dark-orb-Opacity reduziert (0.40 → 0.20), damit
        // airySection Content (hairline border + sehr leichte elevation)
        // nicht durch Opaque-Orbs überstrahlt wird.
        colorScheme == .dark ? 0.20 : 0.16
    }

    private var orbDiameter: CGFloat {
        colorScheme == .dark ? 320 : 280
    }
}

/// Position der Glow-Orbs. Drei feste Punkte decken den Screen so ab,
/// dass egal wo der User scrollt, immer mindestens ein Orb in der Nähe
/// ist und das Glass etwas zu brechen hat.
private enum OrbPosition: CaseIterable {
    case topLeft
    case right
    case bottomCenter

    var offset: CGSize {
        switch self {
        case .topLeft:      return CGSize(width: -160, height: -260)
        case .right:        return CGSize(width: 180, height: 200)
        case .bottomCenter: return CGSize(width: 0, height: 480)
        }
    }
}

#Preview {
    DynamicBackground()
        .environment(ThemeManager.shared)
}
