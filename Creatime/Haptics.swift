import UIKit

// MARK: - Zentraler Haptik-Helper
//
// iOS HIG empfiehlt Mikro-Haptics für Aktions-Bestätigung. Wir haben
// die bisher über UI-NavigationFeedbackGenerator (notificationOccurred)
// gefeuert — das ist OK, aber zu grob. Hier eine konsolidierte Sammlung:
//
//   • `success(_:)`   — Bestätigung „hat geklappt" (Creatine, Wasser-Ziel erreicht)
//   • `error(_:)`     — „hat nicht geklappt" (Foto-Streak-Budget aufgebraucht)
//   • `tap(_:)`       — Mikro-Feedback bei einem normalen Tap (Mood-Emoji)
//   • `select(_:)`    — Selektion (Theme-Wechsel in Settings)
//   • `boost(_:)`     — Long-Press-Boost wiederholt (Wasser-Long-Press)
//
// UIImpactFeedbackGenerator vorbereiten (`prepare()`) reduziert Latenz
// beim ersten Fire — wir machen das im Init einmalig.

@MainActor
enum Haptics {

    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private static let selectionGen = UISelectionFeedbackGenerator()
    private static let notificationGen = UINotificationFeedbackGenerator()

    static func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selectionGen.prepare()
        notificationGen.prepare()
    }

    /// „Hat geklappt"-Feedback — Creatine markiert, Wasserziel erreicht,
    /// Streak-Freeze gebucht, Buddy-Code kopiert.
    static func success() {
        notificationGen.notificationOccurred(.success)
    }

    /// „Hat nicht geklappt" — Foto-Streak-Budget aufgebraucht, Buddy-Code ungültig.
    static func error() {
        notificationGen.notificationOccurred(.error)
    }

    /// Mikro-Feedback bei einem normalen Tap (Mood-Emoji-Auswahl,
    /// Theme-Auswahl in Picker, Streak-Share-Tap, Konfetti-Dismiss).
    static func tap() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    /// Etwas stärkerer Tap als `tap()` — für die großen Aktionen
    /// (Mark-Creatine, Skip-Today).
    static func tapMedium() {
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }

    /// Selection-Change — Theme-Wechsel, Goal-Mode-Wechsel.
    static func select() {
        selectionGen.selectionChanged()
        selectionGen.prepare()
    }

    /// Long-Press-Boost wiederholt — alle 0,5 s einmal für den „Wasser-Tick".
    static func boost() {
        lightImpact.impactOccurred()
    }

    /// Heavy — Achievement freigeschaltet. Selten und nur als „großes Lob".
    static func successHeavy() {
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
        // Plus zusätzlich eine Notification, damit der Heavy-Modus vom
        // System deutlicher dargestellt wird.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            notificationGen.notificationOccurred(.success)
        }
    }
}
