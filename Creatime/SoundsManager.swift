import Foundation
import SwiftUI
import AudioToolbox
import AVFoundation
import UIKit

// MARK: - Sound-System (v14.3 — Single Gym-Sound)
//
// v14.3 SIMPLIFIZIERUNG: User wollte nur EINEN Sound (Gym) — kein
// Wellness/Calm/Off mehr. Der SoundTheme-Enum bleibt als API-Stub für
// zukünftige Erweiterungen, hat aber nur noch den einen Case `.gym`. Im
// UI gibt es keinen Sound-Theme-Picker mehr.
//
// Sound-IDs (Apple System-Sounds):
//   • mark   = 1306 (Heavy Punch — knackiger Click)
//   • splash = 1057 (Tweet — scharfer Klick)
//   • goal   = 1057 (Tweet — gleicher Punch wie Splash)
//
// Haptics:
//   • mark   = .heavy  (Error-Notification — fester Tact)
//   • splash = .medium (Success — sanft)
//   • goal   = .heavy  (mit Bell-Sound, fester Tact)
//
// Audio-Session: `.ambient` + `.mixWithOthers` → spielt im Silent-Mode
// und blockt andere Audio-Apps nicht.

enum SoundTheme: String, CaseIterable, Identifiable, Codable {
    case gym

    var id: String { rawValue }
    var displayName: String { "Gym" }
    var iconName: String { "bolt.fill" }
}

@MainActor
@Observable
final class SoundsManager {

    /// Singleton-retained Haptics-Generator mit `.prepare()`-Warmhalten.
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private let defaults: UserDefaults

    /// Aktives Theme — read-only (immer .gym). legacy `@AppStorage`
    /// für SoundTheme wird gespiegelt, falls alte Daten in UserDefaults
    /// liegen, aber NICHT mehr für User-Auswahl benutzt.
    private(set) var theme: SoundTheme = .gym

    static let storageKey = "soundTheme"

    init(theme: SoundTheme = .gym, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        notificationFeedback.prepare()
        configureAudioSession()
    }

    enum Action {
        case waterSplash, creatineMark, goalReached
    }

    /// Single-Source-of-Truth: (Theme × Action) → SystemSoundID.
    /// Aktuell nur .gym — wenn jemals ein neues Theme dazukommt,
    /// einfach hier erweitern.
    private static func soundID(for theme: SoundTheme, action: Action) -> SystemSoundID? {
        switch (theme, action) {
        case (.gym, .waterSplash):  return 1057  // Tweet — scharfer Klick
        case (.gym, .creatineMark): return 1306  // Heavy Punch — knackig
        case (.gym, .goalReached):  return 1057  // Tweet-Punch-Cascade
        }
    }

    private func soundID(for action: Action) -> SystemSoundID? {
        Self.soundID(for: .gym, action: action)
    }

    // MARK: - Action-Methoden

    func playWaterSplash() {
        if let id = soundID(for: .waterSplash) {
            AudioServicesPlaySystemSound(id)
        }
        trigger(.medium)
    }

    func playCreatineMark() {
        if let id = soundID(for: .creatineMark) {
            AudioServicesPlaySystemSound(id)
        }
        trigger(.heavy)
    }

    /// Wasser-Ziel erreicht! Bell + Punch mit 140 ms Versatz.
    /// Da es nur noch Gym gibt, fallen die 4 Varianten weg — immer
    /// der gleiche kraftvolle Double-Punch + Heavy-Haptic.
    func playGoalReached() {
        if let bellID = soundID(for: .goalReached) {
            AudioServicesPlaySystemSound(bellID)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(140))
                AudioServicesPlaySystemSound(1057)
            }
        }
        trigger(.heavy)
    }

    // MARK: - Haptics Helfer

    private func trigger(_ intensity: FeedbackIntensity) {
        notificationFeedback.prepare()
        switch intensity {
        case .light:  notificationFeedback.notificationOccurred(.warning)
        case .medium: notificationFeedback.notificationOccurred(.success)
        case .heavy:  notificationFeedback.notificationOccurred(.error)
        }
    }

    // MARK: - Audio-Session

    private nonisolated func configureAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("SoundsManager: AVAudioSession setzen fehlgeschlagen: \(error)")
        }
        #endif
    }
}

private enum FeedbackIntensity {
    case light, medium, heavy
}
