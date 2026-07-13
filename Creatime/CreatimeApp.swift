import SwiftUI

// @main markiert den Einstiegspunkt der App — hier startet iOS deine App.
@main
struct CreatimeApp: App {

    // Die Daten-Stores werden genau EINMAL für die ganze App erzeugt.
    // @State hält sie am Leben, solange die App läuft.
    @State private var store = CreatineStore()
    @State private var waterStore = WaterStore()
    @State private var photoStore = PhotoStreakStore()
    @State private var sounds = SoundsManager()
    @State private var buddy = BuddySystem()

    /// ThemeManager als Singleton injiziert. Wir hängen ihn hier als
    /// @State ein, damit SwiftUI beobachtet, wenn der User in Settings
    /// ein neues Theme wählt.
    @State private var theme = ThemeManager.shared

    /// AppDelegate-Adapter — NÖTIG für Long-Press-App-Icon-Quick-Actions.
    /// iOS liefert das ShortcutItem via application(_:performActionFor:completionHandler:)
    /// an den Delegate, NICHT an SwiftUI direkt. Der Adapter leitet es
    /// an unseren QuickAction-Router weiter.
    @UIApplicationDelegateAdaptor(CreatimeAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                // .environment() reicht die Stores an ALLE Views darunter weiter.
                // Jede View kann sie sich mit @Environment(...) holen — kein Durchreichen nötig.
                .environment(store)
                .environment(waterStore)
                .environment(photoStore)
                .environment(sounds)
                .environment(buddy)
                .environment(theme)
                // Theme-Tint: ersetzt Color.accentColor system-weit für
                // ALLE Kinder. .preferredColorScheme würde nur Light/Dark
                // wechseln — wir brauchen ein custom Akzent.
                .tint(theme.tint)
        }
    }
}
