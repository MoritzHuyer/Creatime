import Foundation
import WidgetKit
import Observation

// MARK: - Buddy Streak Battle (v1 — minimal implementation)
//
// OHNE CloudKit oder Server-Sync: zwei Creatime-User können sich per
// AirDrop/iMessage einen Invite-Code schicken, den jeweils andere tippt
// ein, und beide tracken ihre eigene Streak + ihre manuelle Eingabe der
// Buddy-Streak.
//
// Diese v1 ist eine „competitive journaling"-Lösung — KEIN Live-Sync.
// Die App liest die Buddy-Streak-Werte aus UserDefaults (oder
// App-Group). Der User kann die Streak seines Buddys manuell aktualisieren
// oder die App benachrichtigt ihn per Reminder („Frag deinen Buddy nach
// seiner heutigen Streak").
//
// PHASE 2: Echte Sync via CKShare, CloudKit Public Database oder
// MultipeerConnectivity. Bis dahin: genug Scaffolding, damit das
// Feature sichtbar und erlebbar ist.

@Observable
@MainActor
final class BuddySystem {

    /// Mein eigener 6-stelliger Invite-Code. Wird beim ersten Erzeugen
    /// einmal generiert.
    let myInviteCode: String

    /// Optional — der Name meines Buddys, oder leer.
    var buddyName: String

    /// Optional — die letzte vom User manuell eingetragene Streak des Buddys.
    var buddyStreak: Int

    /// Wann hat der User zuletzt die Buddy-Streak aktualisiert? Wir
    /// verwenden das, um eine sanfte Erinnerung zu zeigen („Update dein
    /// Buddy's Streak").
    var lastBuddyUpdate: Date?

    private let defaults = SharedDefaults.store

    init() {
        // Alphabet ohne leicht verwechselbare Zeichen (kein 0/O, 1/I/L);
        // Crockford-ähnlich.
        let alphabet = "0123456789ABCDEFGHJKLMNPQRSTUVWXYZ"
        let chars = (0..<6).map { _ in alphabet.randomElement()! }
        self.myInviteCode = String(chars)
        self.buddyName = defaults.string(forKey: "buddyName") ?? ""
        self.buddyStreak = defaults.integer(forKey: "buddyStreak")
        let ts = defaults.object(forKey: "lastBuddyUpdate") as? Double
        self.lastBuddyUpdate = ts.map { Date(timeIntervalSince1970: $0) }
    }

    /// Setzt den Buddy-Namen + Streak. Schreibt zurück in SharedDefaults
    /// damit Widget (z. B. StandBy / Home-Screen) den Buddy-Wert ebenfalls
    /// rendern könnte.
    func updateBuddy(name: String, streak: Int) {
        buddyName = name
        buddyStreak = streak
        lastBuddyUpdate = Date()
        defaults.set(name, forKey: "buddyName")
        defaults.set(streak, forKey: "buddyStreak")
        defaults.set(Date().timeIntervalSince1970, forKey: "lastBuddyUpdate")
        WidgetCenter.shared.reloadAllTimelines()
        Haptics.success()
    }

    /// Setzt den Buddy zurück (z. B. wenn die Freundschaft endet).
    func clearBuddy() {
        buddyName = ""
        buddyStreak = 0
        lastBuddyUpdate = nil
        defaults.removeObject(forKey: "buddyName")
        defaults.removeObject(forKey: "buddyStreak")
        defaults.removeObject(forKey: "lastBuddyUpdate")
        Haptics.tap()
    }

    /// Text, den der User via AirDrop/iMessage sharen kann. Enthält den
    /// Invite-Code; Empfänger tippt ihn in der App ein.
    var shareText: String {
        let url = URL(string: "creatime://buddy=\(myInviteCode)")!
        return """
        Ich nutze Creatime und lade dich zur Streak-Battle ein! 🔥

        Dein Invite-Code: \(myInviteCode)
        Tippe ihn in der Creatime-App unter „Buddy" ein: \(url.absoluteString)

        Wer hat länger durchgehalten? 😏
        """
    }

    /// Soll der User an die manuelle Sync erinnert werden? (>7 Tage her
    /// ODER noch nie.)
    var staleReminderNeeded: Bool {
        guard let last = lastBuddyUpdate else { return true }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return days >= 7
    }
}
