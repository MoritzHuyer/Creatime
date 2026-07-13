import Foundation
import SwiftUI
import AudioToolbox
import UIKit

// MARK: - Sound-Theme & Manager
//
// Spielt System-Sounds und Haptics für Wasser-Add und Kreatin-Mark.
// Sound-Theme bestimmt, welche Sounds gespielt werden:
//
//   .wellness (Default): weiche Water-Drop Sounds und sanfte Haptics
//   .gym:               knackige Click-Sounds + Heavy-Haptics
//   .calm:              nur leichte Haptics, keine Sounds
//   .off:               nichts
//
// v2-Fix: `previewTheme(_:)` spielt nur den Sound ohne Haptik.
// Grund: vorher rief SettingsView `playCreatineMark()` auf, das SOUND +
// HAPTIC gleichzeitig feuerte — User nahmen das als "Sound ÜBER dem
// ausgewählten" wahr, weil das Gehirn den Haptik-Impuls nicht klar
// von der Audio-Welle trennen konnte.
//
// v3-Cleanup: ID-Tabelle ist in EINEM statischen Helper konzentriert.
// `previewTheme` und `soundID(for:)` greifen beide auf dieselbe
// Tabelle zu — keine duplizierten switch-Konstrukte mehr.

enum SoundTheme: String, CaseIterable, Identifiable, Codable {
    case wellness, gym, calm, off
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wellness: return "Wellness"
        case .gym:      return "Gym"
        case .calm:     return "Ruhig"
        case .off:      return "Aus"
        }
    }

    var iconName: String {
        switch self {
        case .wellness: return "drop.fill"
        case .gym:      return "bolt.fill"
        case .calm:     return "leaf.fill"
        case .off:      return "speaker.slash.fill"
        }
    }
}

@MainActor
@Observable
final class SoundsManager {

    /// Eine Quelle der Wahrheit: dasselbe Standard-`UserDefaults`,
    /// das auch `@AppStorage("soundTheme")` benutzt.
    private let defaults: UserDefaults

    var theme: SoundTheme {
        didSet {
            guard oldValue != theme else { return }
            defaults.set(theme.rawValue, forKey: Self.storageKey)
        }
    }

    static let storageKey = "soundTheme"

    init(theme: SoundTheme = .wellness, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Self.storageKey),
           let restored = SoundTheme(rawValue: raw) {
            self.theme = restored
        } else {
            self.theme = theme
        }
    }

    /// Welcher Sound-/Haptik-Typ gespielt werden soll.
    enum Action {
        case waterSplash, creatineMark, goalReached
    }

    /// EINE Tabelle: (Theme × Action) → SystemSoundID. Wird sowohl von
    /// `soundID(for:)` (aktives Theme) als auch von `previewTheme(_:)`
    /// (Vorschau-Theme) genutzt — keine doppelten switch-Konstrukte.
    private static func soundID(for theme: SoundTheme, action: Action) -> SystemSoundID? {
        switch (theme, action) {
        case (.wellness, .waterSplash):  return 1108  // JBL_Tock — Wassertropfen
        case (.wellness, .creatineMark): return 1104  // JBL_Confirm — soft
        case (.wellness, .goalReached):  return 1023  // JBL_Begin — Bell
        case (.gym,      .waterSplash):  return 1057  // Tweet — scharfkurzer Klick
        case (.gym,      .creatineMark): return 1306  // Heavy Punch — fester Klick
        case (.gym,      .goalReached):  return 1057  // Tweet — gleicher Punch wie Wasser
        case (.calm,     .waterSplash):  return 1103  // JBL_No_match — sehr leise
        case (.calm,     .creatineMark): return 1109  // JBL_Ambiguous — sanft
        case (.calm,     .goalReached):  return 1023  // Bell
        case (.off,      _):             return nil
        }
    }

    private func soundID(for action: Action) -> SystemSoundID? {
        Self.soundID(for: theme, action: action)
    }

    // MARK: - Action-Methoden (für TodayView / WaterTrackerCard)

    /// Splash-Sound bei Wasser-Tap. Nicht im `.off`-Theme.
    func playWaterSplash() {
        if let id = soundID(for: .waterSplash) {
            AudioServicesPlaySystemSound(id)
        }
        trigger(theme == .gym ? .medium : .light)
    }

    /// Click-Sound bei Kreatin-Bestätigung.
    func playCreatineMark() {
        if let id = soundID(for: .creatineMark) {
            AudioServicesPlaySystemSound(id)
        }
        trigger(theme == .gym ? .heavy : .medium)
    }

    /// Wasser-Ziel erreicht! v2: Chime-Cascade statt einsamer Bell.
    ///
    /// Vorher: einzelner 1023-Bell, den User als "Zug-Geräusch" empfanden.
    /// Jetzt: kurzer Bell (1023) gefolgt von einem weichen Confirm-Ton
    /// (1104) mit 140 ms Versatz → klingt wie ein kleines Feuerwerk und
    /// ist klar VON anderen Sounds unterscheidbar.
    func playGoalReached() {
        if let bellID = soundID(for: .goalReached) {
            AudioServicesPlaySystemSound(bellID)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(140))
                AudioServicesPlaySystemSound(1104)
            }
        }
        UINotificationFeedbackGeneratorWrapper.success()
    }

    // MARK: - Vorschau (für SettingsView)

    /// Pure-Audio-Preview eines Sound-Themes OHNE Haptik. Bewusst kein
    /// `trigger(...)`, denn das gleichzeitige Sound+Haptik-Feuer wurde
    /// von Usern als "Sound ÜBER dem ausgewählten" wahrgenommen.
    ///
    /// Nutzt die gleiche SoundID-Tabelle wie das aktive Theme —
    /// kein doppelter Switch mehr.
    func previewTheme(_ preview: SoundTheme) {
        guard preview != .off else { return }
        if let id = Self.soundID(for: preview, action: .creatineMark) {
            AudioServicesPlaySystemSound(id)
        }
    }

    private func trigger(_ intensity: FeedbackIntensity) {
        UINotificationFeedbackGeneratorWrapper.notify(intensity)
    }
}

private enum FeedbackIntensity {
    case light, medium, heavy
}

private enum UINotificationFeedbackGeneratorWrapper {
    static func notify(_ intensity: FeedbackIntensity) {
        let generator = UINotificationFeedbackGenerator()
        switch intensity {
        case .light: generator.notificationOccurred(.warning)
        case .medium: generator.notificationOccurred(.success)
        case .heavy: generator.notificationOccurred(.error)
        }
    }
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
