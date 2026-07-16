import SwiftUI

// MARK: - Creatime Design Tokens (v16 — Claude Design Port)
//
// Single source of truth for every visual primitive used by the
// redesigned UI. All values are extracted directly from the Claude
// Design export at `/Users/moritz/Downloads/Creatime iOS UI-Prototype/Creatime.dc.html`
// (screens 1a, 1b, 1c, 1d, 1e).
//
// IMPORTANT: This file is *pure*. No behaviour is changed here — only
// constants are introduced. Real screens will read from this file when
// they are ported; until then these tokens sit unused.
//
// Naming convention: `ct` prefix for "Creatime Token" — short, sortable.

extension Color {

    // MARK: - Streak (Orange / Accent)

    /// Primary brand accent. Used for streak counter, active tab
    /// pulse, primary button tints.
    /// Akzentfarbe folgt dem in Settings gewählten Theme. Vorher war hier
    /// Orange hartkodiert — der Theme-Picker sah dadurch aus wie ein
    /// Feature, hat aber nichts verändert. „Sunset" entspricht ungefähr
    /// dem bisherigen Orange.
    static var ctAccent: Color { ThemeManager.shared.tint }

    /// Streak flame icon stroke — slightly brighter for icon use.
    static let ctStreakFlame = Color(lightHex: "#FF9500", darkHex: "#FF9F0A")

    // MARK: - Kreatin (Blue)

    /// Kreatin-toggle ring + "KREATIN" label color.
    static let ctKreatin = Color(lightHex: "#3E86FF", darkHex: "#6FA5FF")

    /// Kreatin deep accent for "Gesichert"-pill text + freeze pills.
    static let ctKreatinDeep = Color(lightHex: "#2F6FE0", darkHex: "#8FB8FF")

    // MARK: - Wasser (Cyan)

    /// Wasser progress-bar + drop-icon stroke. Light mode line color.
    static let ctWasser = Color(lightHex: "#30B0C7", darkHex: "#4FC7DD")

    /// Wasser gradient bright stop (top of bar gradient).
    static let ctWasserBright = Color(lightHex: "#5AC8FA", darkHex: "#5AC8FA")

    /// Wasser ↔ on-tap-Button tint fill (translucent).
    static let ctWasserSurface = Color(lightHex: "#30B0C7", darkHex: "#4FC7DD").opacity(0.22)

    // MARK: - Success / Securing

    /// "Heute gesichert" pill + freeze icon — saturated green check.
    static let ctSuccess = Color(lightHex: "#248A3D", darkHex: "#4CD964")

    /// Success-pill translucent background (HTML light = rgba(52,199,89,0.15),
    /// dark = rgba(48,209,88,0.18)).
    static let ctSuccessSurface = Color(lightHex: "#34C759", darkHex: "#30D158").opacity(0.15)

    // MARK: - Freeze (Blue)

    /// Freeze pill surface (HTML light = rgba(62,134,255,0.12),
    /// dark = rgba(94,158,255,0.18)).
    static let ctFreeze = Color(lightHex: "#3E86FF", darkHex: "#8FB8FF").opacity(0.12)

    // MARK: - Surfaces

    /// Light-mode page background.
    static let ctBackgroundLight = Color(hex: "#F2F2F7")

    /// Dark-mode page background top stop (16,17,28).
    static let ctBackgroundDarkTop = Color(hex: "#16171C")

    /// Dark-mode page background bottom stop (14,15,19).
    static let ctBackgroundDarkBottom = Color(hex: "#0E0F13")

    /// Light-mode card surface.
    static let ctCardSurface = Color(hex: "#FFFFFF")

    /// Dark-mode card surface — approximated solid #26272E at 85 %
    /// opacity (the prototype uses `rgba(38,39,46,0.85)`).
    static let ctCardSurfaceDark = Color(hex: "#26272E").opacity(0.85)

    /// Card hairline border (light mode — barely visible).
    static let ctCardBorderLight = Color.black.opacity(0.04)

    /// Card hairline border (dark mode — 0.5 px white at 7 %).
    static let ctCardBorderDark = Color.white.opacity(0.07)

    // MARK: - Ink (text)

    /// Primary ink (light = #000, dark = #F5F5F7).
    static let ctInk = Color(lightHex: "#000000", darkHex: "#F5F5F7")

    /// Secondary ink — labels, captions. ~60 % opacity in both modes.
    static let ctInkSecondary = Color(lightHex: "#3C3C43", darkHex: "#EBEBF5").opacity(0.6)

    /// Tertiary ink — small hints, dividers. ~30 %.
    static let ctInkTertiary = Color(lightHex: "#3C3C43", darkHex: "#EBEBF5").opacity(0.3)

    /// Inactive tab-bar icon (light = #8E8E93, dark = EBEBF5 @ 55 %).
    static let ctTabInactive = Color(lightHex: "#8E8E93", darkHex: "#EBEBF5").opacity(0.55)

    // MARK: - Floating Tab Bar (glass pill)

    /// Tab-bar pill background, light.
    static let ctTabBarLight = Color.white.opacity(0.75)

    /// Tab-bar pill background, dark (HTML rgba(32,33,38,0.75) →
    /// solid #202126 at 75 % — note: NOT a neutral white; it carries
    /// the slight blue-grey tint the design wants).
    static let ctTabBarDark = Color(hex: "#202126").opacity(0.75)   // rgba(32,33,38,0.75)

    /// Tab-bar pill border, light.
    static let ctTabBarBorderLight = Color.black.opacity(0.05)

    /// Tab-bar pill border, dark.
    static let ctTabBarBorderDark = Color.white.opacity(0.09)

    /// Tab-bar active-item background tint (HTML = rgba(255,122,47,0.14)).
    static let ctTabBarActiveSurface = Color(lightHex: "#FF7A2F", darkHex: "#FF8A47").opacity(0.14)

    // MARK: - Bottom Sheet

    /// Backdrop dim overlay over the calling screen.
    static let ctSheetBackdrop = Color.black.opacity(0.28)
}

// MARK: - Typography

extension Font {

    /// Big screen-title at the top of every tab ("Heute", "Fortschritt",
    /// "Erfolge"). 34 pt Bold.
    static let ctPageTitle = Font.system(size: 34, weight: .bold)

    /// Streak big number on Today — 72 pt Heavy. Apply
    /// `.monospacedDigit().tracking(-2.5)` to the Text when using.
    static let ctStreakHero = Font.system(size: 72, weight: .heavy)

    /// Achievements hero count — 68 pt Heavy.
    static let ctAchievementHero = Font.system(size: 68, weight: .heavy)

    /// Fortschritt 93 % number — 56 pt Heavy.
    static let ctBigNumber = Font.system(size: 56, weight: .heavy)

    /// Wasser current amount — 44 pt Heavy.
    static let ctWaterHero = Font.system(size: 44, weight: .heavy)

    /// Card-title weight — 17 pt Semibold ("Kreatin · 5 g Monohydrat").
    static let ctCardTitle = Font.system(size: 17, weight: .semibold)

    /// Body — 17 pt regular (settings rows).
    static let ctBody = Font.system(size: 17)

    /// Subheadline — 15 pt (caption rows, secondary labels).
    static let ctSubheadline = Font.system(size: 15)

    /// Section label uppercase — 13 pt Semibold with +0.6 tracking
    /// (e.g. "MITTWOCH, 16. JULI"). Apply `.tracking(0.6)` and
    /// `.textCase(.uppercase)` at the call site.
    static let ctSectionLabel = Font.system(size: 13, weight: .semibold)

    /// Caption — 12 pt regular.
    static let ctCaption = Font.system(size: 12)

    /// Badge label inside chips — 11 pt Semibold with letterspacing.
    static let ctChipLabel = Font.system(size: 11, weight: .semibold)

    /// Tab-bar item label — 10.5 pt Semibold.
    static let ctTabLabel = Font.system(size: 10.5, weight: .semibold)
}

// MARK: - Layout Constants

/// All static layout constants extracted from the prototype — corner
/// radii, padding, offsets, dimensions. Use this enum rather than
/// sprinkling magic numbers across screens.
enum CTLayout {

    /// Default card corner radius.
    static let cardRadius: CGFloat = 24

    /// Form-row corner radius (Settings, detail rows).
    static let formRowRadius: CGFloat = 16

    /// Bottom-sheet top corner radius.
    static let sheetRadius: CGFloat = 38

    /// Tab-bar pill is fully rounded.
    static let tabBarRadius: CGFloat = 9999

    /// Compact radius for inline chips + icon backgrounds.
    static let smallRadius: CGFloat = 14

    /// Card inner padding (use `.padding(.ctCardPadding)` extension below).
    static let cardPadding: CGFloat = 18

    /// Form-row min height (single-row).
    static let formRowMin: CGFloat = 56

    /// Detail-list-row min height (no subtitle).
    static let listRowMin: CGFloat = 52

    /// Horizontal safe-area padding inside ContentView.
    static let horizontalPadding: CGFloat = 20

    /// Floating Tab-Bar offset from the bottom screen edge.
    static let tabBarBottomOffset: CGFloat = 18

    /// Width of each tab-bar button container.
    static let tabButtonWidth: CGFloat = 86

    /// Padding inside the tab-bar pill (gap between buttons and edge).
    static let tabBarPadding: CGFloat = 5

    /// Tab-bar button vertical padding.
    static let tabBarButtonPaddingV: CGFloat = 6

    /// Sheet grabber size (wid × hei).
    static let sheetGrabber = CGSize(width: 36, height: 5)

    /// Avatar size for buddy row.
    static let buddyAvatarSize: CGFloat = 36

    /// Calendar cell diameter.
    static let calendarCellSize: CGFloat = 36

    /// Calendar today-ring diameter (cell + 2 pt halo).
    static let calendarTodayRingSize: CGFloat = 40

    /// Badge-circle diameter (achievements + buddy avatars).
    static let badgeDiameter: CGFloat = 58
}

// MARK: - Animation Curves
//
// All timings derived from the prototype's CSS transitions.
// iOS equivalents use `Animation.timingCurve(_, _, _, _, duration:)`
// to match cubic-bezier exactly.

extension Animation {

    /// "ct-pop 0.4s ease" — used for checkmark springs-in, badge
    /// births. Approximated as spring for the slight overshoot.
    static let ctPop = Animation.spring(response: 0.4, dampingFraction: 0.75)

    /// "stroke-dashoffset .8s cubic-bezier(.22,1.2,.36,1)" — Kreatin
    /// ring progress fill (slight overshoot at end).
    static let ctRingFill = Animation.timingCurve(0.22, 1.2, 0.36, 1.0, duration: 0.8)

    /// "width .5s cubic-bezier(.3,1,.4,1)" — Wasser bar.
    static let ctBarFill = Animation.timingCurve(0.3, 1.0, 0.4, 1.0, duration: 0.5)

    /// Tap-press scale animation (very short and crisp).
    static let ctTap = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.12)

    /// Snappy default — same as `Animation.snappy` for consistency.
    static let ctSnappy = Animation.snappy
}

// MARK: - Shadows

/// Static shadow definitions for cards + the floating tab bar.
/// Use as `.shadow(color: CTShadow.cardLight.color, radius:
/// CTShadow.cardLight.radius, y: CTShadow.cardLight.y)`.
enum CTShadow {

    /// Card subtle shadow, light mode (≈ 0 1px 2px rgba(0,0,0,0.04)).
    static let cardLight = ShadowSpec(color: .black.opacity(0.04),
                                       radius: 2,
                                       x: 0,
                                       y: 1)

    /// Card subtle shadow, dark mode — none (replaced by hairline border).
    static let cardDark = ShadowSpec(color: .clear,
                                     radius: 0,
                                     x: 0,
                                     y: 0)

    /// Floating tab-bar shadow, light mode (≈ 0 10px 30px rgba(0,0,0,0.12)).
    static let tabBarLight = ShadowSpec(color: .black.opacity(0.12),
                                         radius: 30,
                                         x: 0,
                                         y: 10)

    /// Floating tab-bar shadow, dark mode — stronger drop.
    static let tabBarDark = ShadowSpec(color: .black.opacity(0.4),
                                       radius: 30,
                                       x: 0,
                                       y: 10)
}

/// Lightweight struct so shadow params can be passed as a tuple.
struct ShadowSpec {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Convenience Padding Extensions
//
// So views can write `.padding(.ctCard)` instead of magic `.padding(18)`.

extension EdgeInsets {
    static let ctCard = EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)

    /// Coordinate-space safe padding used at the top-level of every
    /// tab (20 pt horizontal, matching prototype's `padding:70px 20px`).
    static let ctPage = EdgeInsets(top: 16, leading: 20, bottom: 110, trailing: 20)
}

extension View {
    /// Apply the prototype's card padding + corner-radius in one go.
    func ctCardSurface(radius: CGFloat = CTLayout.cardRadius) -> some View {
        self
            .padding(EdgeInsets.ctCard)
            .background(Color.ctCardSurface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// Light-mode sizing helper: capture the prototype's default
    /// horizontal page padding as a Stack-level modifier.
    func ctPagePadded() -> some View {
        self.padding(.horizontal, CTLayout.horizontalPadding)
    }
}

// MARK: - Reusable badge / chip surface
//
// Used for "Heute gesichert", "1 Freeze übrig", "Best: 21" pills.
// Kept here as a primitive so screens don't reinvent it.

struct CTChipSurface: View {
    enum Tint {
        case success, freeze, neutral

        var fill: Color {
            switch self {
            case .success: return .ctSuccessSurface
            case .freeze:  return .ctFreeze
            case .neutral:
                // HTML neutral-pill surface is rgba(118,118,128,0.12);
                // translating to grayscale (118/255 ≈ 0.46) at the same
                // 12 % opacity gives the design's neutral pill.
                return Color(white: 0.46).opacity(0.12)
            }
        }

        var foreground: Color {
            switch self {
            case .success: return .ctSuccess
            case .freeze:  return .ctKreatinDeep
            case .neutral: return .ctInkSecondary
            }
        }
    }

    let label: String
    let tint: Tint
    let symbol: String?

    init(_ label: String, tint: Tint = .neutral, symbol: String? = nil) {
        self.label = label
        self.tint = tint
        self.symbol = symbol
    }

    var body: some View {
        HStack(spacing: 5) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .bold))
            }
            Text(label)
                .font(.ctChipLabel)
                .tracking(0.4)
        }
        .foregroundStyle(tint.foreground)
        .padding(.horizontal, 11)
        .padding(.vertical, 5)
        .background(tint.fill, in: Capsule())
        .accessibilityLabel(label)
    }
}

// MARK: - Design tokens preview has been intentionally deferred.
//
// Earlier Draft: a `#if DEBUG` `DesignTokensPreview` view rendered
// the tokens against SwiftUI's preview canvas to verify they match
// the Claude Design HTML. It caused SwiftUI's @ViewBuilder type
// inference to fail (the compiler falls back to unrelated TableColumn
// overloads it cannot resolve).
//
// We'll rebuild the preview once at least one of the real screens
// (TodayView, HistoryView, AchievementsView) is ported to consume
// these tokens — at that point the type signature of the consumers
// will guide a clean preview that compiles.
