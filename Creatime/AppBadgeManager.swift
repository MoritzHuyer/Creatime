import UIKit
import UserNotifications

// MARK: - App-Icon-Badge Helper
//
// Setzt das App-Icon-Badge auf den aktuellen Streak-Wert.
// Static-Helper, weil die ganze Komplexität überflüssig ist — wir rufen
// die Funktion nach jeder Streak-Mutation direkt auf.

enum AppBadgeManager {

    /// Setzt das Badge auf den gegebenen Streak-Wert. Respektiert die
    /// Notification-Permission-Einstellung des Users: wenn Badge deaktiviert,
    /// schlägt `setBadgeCount` still fehl — wir ignorieren den Fehler.
    static func setBadge(_ streak: Int) {
        let count = max(0, streak)
        UNUserNotificationCenter.current().setBadgeCount(count) { _ in
            // Fehler bewusst ignorieren — User hat evtl. Badge-Permission entzogen.
        }
    }
}
