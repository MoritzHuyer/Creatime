import UIKit
import AppIntents
import WidgetKit

// MARK: - Die 3 Quick-Actions (Long-Press auf das App-Icon)
//
// In iOS 26 heißen sie offiziell "App-Icon Shortcuts" (Apple hat den
// UX-Namen geändert). Die ID ist der gleiche String, den der User in
// der Settings/Siri/Shortcuts als Aktion sieht.

enum QuickActionType: String {
    case markCreatine  = "creatime.shortcut.mark"
    case logWater      = "creatime.shortcut.water"
    case askStreak     = "creatime.shortcut.ask"
}

// MARK: - Builder für UIApplicationShortcutItems (in Info.plist registriert)

enum QuickActions {

    /// Wird in `Info.plist` als `UIApplicationShortcutItems` eingetragen.
    /// IDs müssen mit `QuickActionType.rawValue` matchen.
    static func shortcutItems() -> [UIApplicationShortcutItem] {
        [
            UIApplicationShortcutItem(
                type: QuickActionType.markCreatine.rawValue,
                localizedTitle: "Kreatin markieren",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "checkmark.circle.fill"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickActionType.logWater.rawValue,
                localizedTitle: "Wasser eintragen",
                localizedSubtitle: "+ 250 ml",
                icon: UIApplicationShortcutIcon(systemImageName: "drop.fill"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickActionType.askStreak.rawValue,
                localizedTitle: "Wie ist meine Streak?",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "flame.fill"),
                userInfo: nil
            ),
        ]
    }

    /// Verarbeitet ein ShortcutItem, das iOS beim Long-Press oder beim
    /// Start geliefert hat. Führt die Aktion synchron aus (Intents laufen
    /// in einem eigenen Prozess).
    static func handle(_ item: UIApplicationShortcutItem) {
        guard let type = QuickActionType(rawValue: item.type) else { return }
        switch type {
        case .markCreatine:
            performIntent(MarkCreatineTakenIntent())
        case .logWater:
            performIntent(MarkWaterIntakeIntent())
        case .askStreak:
            performIntent(AskStreakIntent())
        }
    }

    /// Führt ein AppIntent aus, ohne die App zu öffnen. Wir brauchen einen
    /// AppDelegate, um perform() zu starten; der IntentCompletion-Stream
    /// ignoriert das Ergebnis (es kommt eh als Siri-Dialog).
    private static func performIntent<I: AppIntent>(_ intent: I) {
        Task.detached {
            _ = try? await intent.perform()
        }
    }
}

// MARK: - AppDelegate-Adapter
//
// Nur WindowGroup reicht NICHT: SwiftUI hat keinen eingebauten Hook für
// `application(_:performActionFor:completionHandler:)`. Wir brauchen
// einen klassischen UIApplicationDelegate, der das Event empfängt und
// an QuickActions weiterleitet.
//
// Außerdem fängt der Adapter `application(_:didFinishLaunching:)` ab,
// um auch einen Cold-Start aus einem Shortcut zu behandeln (iOS liefert
// `launchOptions[.shortcutItem]` in didFinishLaunching, falls der Long-
// Press beim App-Start kam).

final class CreatimeAppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        // SwiftUI liefert default-config; wir hängen den QuickActionHandler
        // als SceneDelegate an. Der ist nötig für VOR-CONNECTED-Launches.
        config.delegateClass = QuickActionSceneDelegate.self
        return config
    }

    // Cold-Start aus Shortcut → performActionFor wird GARANTIERT
    // NACH didFinishLaunching aufgerufen (wenn der User die App öffnet
    // während sie im Hintergrund ist). Wenn der User die App komplett
    // öffnet (Tip auf das Icon), ist launchOptions[.shortcutItem] gesetzt.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if let item = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            // Verzögerung: SceneDelegate wird gleich überrnehmen. Wir
            // merken uns das Item nur als Fallback:
            QuickActionSceneDelegate.pendingItem = item
        }
        return true
    }
}

final class QuickActionSceneDelegate: NSObject, UIWindowSceneDelegate {
    /// Wird vom AppDelegate bei Cold-Start gesetzt, falls der Shortcut
    /// schon vor dem ersten Scene-Connect verfügbar war.
    static var pendingItem: UIApplicationShortcutItem?

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        QuickActions.handle(shortcutItem)
        completionHandler(true)
    }

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Cold-Start-Shortcut nachträglich ausführen.
        if let item = connectionOptions.shortcutItem ?? Self.pendingItem {
            QuickActions.handle(item)
            Self.pendingItem = nil
        }
    }
}
