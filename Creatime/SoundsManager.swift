import Foundation
import SwiftUI
import AudioToolbox
import AVFoundation
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
// v14.2 (Bugfixes):
//   • Haptics: SINGLETON-Generator retained + `.prepare()` beim init.
//     Vor v14.2 wurde jedes Mal ein NEUER `UINotificationFeedbackGenerator`
//     erzeugt — laut Apple-Doku kann der erste Trigger ohne `prepare()`
//     fehlschlagen oder verzögert sein. Außerdem fliegt der State jedes
//     Mal weg. Jetzt behalten wir eine Instanz, bereiten sie einmal vor
//     und rufen `.prepare()` auch vor jedem Trigger erneut auf (das ist
//     idempotent und reduziert Latency).
//   • Audio: `AVAudioSession` Kategorie auf `.ambient` mit
//     `.mixWithOthers` gesetzt — so spielen die System-Sounds auch
//     im Silent-Mode ab und blockieren nicht andere Audio-Apps.

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

    /// Singleton-retained Haptics-Generator (Apple-Doku: Generator MUSS
    /// retained + `.prepare()`-ed werden, sonst erster Trigger
    /// unzuverlässig). Wir instanziieren genau EINMAL pro SoundsManager.
    private let notificationFeedback = UINotificationFeedbackGenerator()

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
        // Haptics vorbereiten + Audio-Session setzen.
        notificationFeedback.prepare()
        configureAudioSession()
    }

    /// Welcher Sound-/Haptik-Typ gespielt werden soll.
    enum Action {
        case waterSplash, creatineMark, goalReached
    }

    /// EINE Tabelle: (Theme × Action) → SystemSoundID.
    private static func soundID(for theme: SoundTheme, action: Action) -> SystemSoundID? {
        switch (theme, action) {
        case (.wellness, .waterSplash):  return 1108  // JBL_Tock
        case (.wellness, .creatineMark): return 1104  // JBL_Confirm
        case (.wellness, .goalReached):  return 1023  // JBL_Begin (Bell)
        case (.gym,      .waterSplash):  return 1057  // Tweet — scharfer Klick
        case (.gym,      .creatineMark): return 1306  // Heavy Punch
        case (.gym,      .goalReached):  return 1057  // Tweet
        case (.calm,     .waterSplash):  return 1103  // JBL_No_match
        case (.calm,     .creatineMark): return 1109  // JBL_Ambiguous
        case (.calm,     .goalReached):  return 1023  // Bell
        case (.off,      _):             return nil
        }
    }

    private func soundID(for action: Action) -> SystemSoundID? {
        Self.soundID(for: theme, action: action)
    }

    // MARK: - Action-Methoden

    func playWaterSplash() {
        if let id = soundID(for: .waterSplash) {
            AudioServicesPlaySystemSound(id)
        }
        trigger(theme == .gym ? .medium : .light)
    }

    func playCreatineMark() {
        if let id = soundID(for: .creatineMark) {
            AudioServicesPlaySystemSound(id)
        }
        trigger(theme == .gym ? .heavy : .medium)
    }

    /// Wasser-Ziel erreicht! Bell + Confirm-Cascade mit 140 ms Versatz.
    func playGoalReached() {
        if let bellID = soundID(for: .goalReached) {
            AudioServicesPlaySystemSound(bellID)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(140))
                AudioServicesPlaySystemSound(1104)
            }
        }
        trigger(.heavy)
    }

    // MARK: - Vorschau (Settings)

    func previewTheme(_ preview: SoundTheme) {
        guard preview != .off else { return }
        if let id = Self.soundID(for: preview, action: .creatineMark) {
            AudioServicesPlaySystemSound(id)
        }
    }

    // MARK: - Haptics Helfer

    private func trigger(_ intensity: FeedbackIntensity) {
        // Idempotent: vor jedem Trigger erneut `.prepare()` aufrufen,
        // reduziert Trigger-Latency auf den nächsten Tap.
        notificationFeedback.prepare()
        switch intensity {
        case .light:  notificationFeedback.notificationOccurred(.warning)
        case .medium: notificationFeedback.notificationOccurred(.success)
        case .heavy:  notificationFeedback.notificationOccurred(.error)
        }
    }

    // MARK: - Audio-Session

    /// `.ambient` = spielt im Silent-Mode weiter (kein aggressiver
    /// Mix mit anderen Apps, duckt andere Audio-Quellen nicht ab).
    /// `.mixWithOthers` = lässt z. B. Musik-Apps weiterlaufen, wenn
    /// der User Creatime-Sounds hört.
    private nonisolated func configureAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Wenn das scheitert (z. B. weil eine andere App die
            // Session bereits hält), ist das nicht fatal — Sounds
            // werden trotzdem über AudioServicesPlaySystemSound
            // abgespielt, nur ohne unsere Mix-Policy.
            print("SoundsManager: AVAudioSession setzen fehlgeschlagen: \(error)")
        }
        #endif
    }
}

private enum FeedbackIntensity {
    case light, medium, heavy
}
