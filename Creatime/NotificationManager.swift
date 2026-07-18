import Foundation
import UserNotifications

// NotificationManager — kümmert sich um alles rund um lokale Erinnerungen.
// „Lokal" heißt: direkt auf dem iPhone geplant — kein Server, kein Net.
struct NotificationManager {

    /// Fragt den Nutzer um Erlaubnis.
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error {
                print("Fehler bei der Berechtigungsanfrage: \(error)")
            }
        }
    }

    /// Alte Single-Reminder-Logik (Compatibility).
    static func rescheduleReminders(takenToday: Bool, hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        let now = Date()

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = hour
            components.minute = minute
            guard let fireDate = calendar.date(from: components) else { continue }

            if dayOffset == 0 && (takenToday || fireDate <= now) { continue }

            let content = UNMutableNotificationContent()
            content.title = "Kreatin nicht vergessen! 💪"
            content.body = "Du hast heute noch nicht bestätigt. Jetzt nehmen und die Streak retten!"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "creatime-reminder-\(dayOffset)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }

        scheduleWeeklyPhotoReminder()
    }

    /// SMART REMINDERS — neu in v3.
    ///
    /// Pro Tag: ein PRIMARY-Reminder (typische Stunde) + N-1 BACKUP-Reminder
    /// (Median ± 2 h). Jedes Reminder hat seinen EIGENEN Past-Skip-Check,
    /// damit Slots, deren Uhrzeit noch in der Zukunft liegt, IMMER geplant
    /// werden, auch wenn primary-Stunde bereits vorbei ist.
    /// Wichtig: Foto-Wochen-Reminder wird synchron wieder hinzugefügt
    /// direkt nach `removeAllPendingNotificationRequests()` — kein async
    /// Race mehr.
    static func rescheduleSmartReminders(
        takenToday: Bool,
        suggestedHours: [Int]?,
        fallbackHour: Int = 20,
        fallbackMinute: Int = 0
    ) {
        let center = UNUserNotificationCenter.current()

        // 1) ALLES löschen (auch Foto-Reminder — wir fügen ihn unten wieder hinzu).
        center.removeAllPendingNotificationRequests()

        // 2) Foto-Reminder SOFORT wieder hinzufügen (idempotent — gleicher
        // Identifier wird im NotificationCenter ersetzt, nicht dupliziert).
        scheduleWeeklyPhotoReminder()

        // 3) Wenn keine Heuristik da → klassischer Single-Reminder.
        guard let hours = suggestedHours, !hours.isEmpty else {
            rescheduleReminders(
                takenToday: takenToday,
                hour: fallbackHour,
                minute: fallbackMinute
            )
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let primaryHour = hours.first ?? fallbackHour
        let backupHours = Array(hours.dropFirst())

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            // 1) PRIMARY-Reminder — eigener Past-Skip.
            var priComps = calendar.dateComponents([.year, .month, .day], from: day)
            priComps.hour = primaryHour
            priComps.minute = 0
            guard let priFireDate = calendar.date(from: priComps) else { continue }

            if !(dayOffset == 0 && (takenToday || priFireDate <= now)) {
                let pri = UNMutableNotificationContent()
                pri.title = "Kreatin nicht vergessen! 💪"
                pri.body = "Deine übliche Einnahme-Zeit — kurz bestätigen und Streak retten."
                pri.sound = .default
                pri.threadIdentifier = "creatime-reminders"
                center.add(UNNotificationRequest(
                    identifier: "creatime-reminder-\(dayOffset)-primary",
                    content: pri,
                    trigger: UNCalendarNotificationTrigger(dateMatching: priComps, repeats: false)
                ))
            }

            // 2) BACKUP-Reminder — jeder eigene Past-Skip (KRITISCH).
            for (i, hour) in backupHours.enumerated() {
                var backupComps = calendar.dateComponents([.year, .month, .day], from: day)
                backupComps.hour = hour
                backupComps.minute = 0
                guard let backupFireDate = calendar.date(from: backupComps) else { continue }
                if dayOffset == 0 && (takenToday || backupFireDate <= now) { continue }

                let backup = UNMutableNotificationContent()
                backup.title = "Noch nichts passiert? 🌱"
                backup.body = "Eine kurze Erinnerung — dein Kreatin wartet."
                backup.sound = .default
                backup.threadIdentifier = "creatime-reminders"
                center.add(UNNotificationRequest(
                    identifier: "creatime-reminder-\(dayOffset)-backup-\(i)",
                    content: backup,
                    trigger: UNCalendarNotificationTrigger(dateMatching: backupComps, repeats: false)
                ))
            }
        }
    }

    /// Liefert die Stunden zurück, die aktuell als Reminder gesetzt sind.
    static func getScheduledReminderHours() async -> [Int] {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let cal = Calendar.current
        let today = cal.dateComponents([.year, .month, .day], from: Date())
        return requests
            .filter { $0.identifier.contains("creatime-reminder-") }
            .compactMap { req -> Int? in
                guard let trigger = req.trigger as? UNCalendarNotificationTrigger else { return nil }
                let comps = trigger.dateComponents
                guard comps.year == today.year,
                      comps.month == today.month,
                      comps.day == today.day
                else { return nil }
                return comps.hour
            }
            .sorted()
    }

    /// Foto-Streak-Wochen-Reminder (jeden Samstag 10 Uhr).
    static func scheduleWeeklyPhotoReminder(hour: Int = 10, weekday: Int = 7) {
        let content = UNMutableNotificationContent()
        content.title = "Foto-Streak! 📸"
        content.body = "Heute ist ein guter Tag für ein Foto deines Kreatin-Shakes oder deines Trainings — dokumentiere deine Streak!"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.weekday = weekday

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "creatime-photo-reminder",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
