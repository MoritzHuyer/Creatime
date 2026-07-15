import Foundation
import UserNotifications

// NotificationManager — kümmert sich um alles rund um lokale Erinnerungen.
// „Lokal" heißt: direkt auf dem iPhone geplant — kein Server, kein Net.
//
// v14 (NEU): Nag-Reminders — wenn die Erinnerungs-Zeit vorbei ist und
// heute noch nicht bestätigt wurde, schickt die App zusätzlich
// 3 zufällig verteilte Erinnerungen bis 22 Uhr. Sobald der User
/// das Kreatin markiert (TodayView.markAsTaken), werden ALLE
/// pending Notifications entfernt (inkl. Nags).
struct NotificationManager {

    // MARK: - Permission

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error {
                print("Fehler bei der Berechtigungsanfrage: \(error)")
            }
        }
    }

    /// Liefert den aktuellen Push-Authorization-Status. Wird vom
    /// SettingsView genutzt, um „Berechtigung anfragen" vs. „Berechtigung
    /// abgelehnt — in iOS-Einstellungen aktivieren" zu unterscheiden.
    static func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current()
            .notificationSettings()
            .authorizationStatus
    }

    // MARK: - Compat Single Reminder

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

    // MARK: - Smart Reminders + Nag-Reminders (v14)

    /// Plant ALLE Kreatin-Reminders in einem Rutsch:
    ///   1) Foto-Wochen-Reminder (immer, unabhängig vom Toggle)
    ///   2) PRIMARY pro Tag (typische Stunde) + BACKUP-Slots (Median ± 2h)
    ///   3) NAG-Reminders — 3 zufällige „Stupser" zwischen der primären
    ///      Reminder-Zeit und 22:00, NUR wenn `takenToday=false`.
    ///      Jeder Nag hat einen eigenen eindeutigen Identifier pro Tag
    ///      (= „creatime-nag-{dayKey}-{i}"), damit er beim nächsten
    ///      reschedule-Aufruf sauber ersetzt wird.
    ///
    /// - Parameter:
    ///   - remindersEnabled: false → nur Foto-Reminder, **kein** Kreatin-Scheduling.
    static func rescheduleSmartReminders(
        takenToday: Bool,
        suggestedHours: [Int]?,
        fallbackHour: Int = 20,
        fallbackMinute: Int = 0,
        remindersEnabled: Bool = true
    ) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        scheduleWeeklyPhotoReminder()

        guard remindersEnabled else { return }

        let calendar = Calendar.current
        let now = Date()

        let primaryHour: Int
        let backupHours: [Int]
        if let hours = suggestedHours, !hours.isEmpty {
            primaryHour = hours.first ?? fallbackHour
            backupHours = Array(hours.dropFirst())
        } else {
            primaryHour = fallbackHour
            backupHours = []
        }

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

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

        // Nag-Reminders NUR für heute und NUR wenn noch nicht genommen.
        if !takenToday {
            scheduleNagReminders(primeHour: primaryHour, untilHour: 22)
        }
    }

    /// 3 zufällig verteilte „Nag"-Erinnerungen zwischen der primären
    /// Reminder-Stunde und `untilHour` (Default 22 Uhr).
    /// Verwendet KEINE UNCalendarNotificationTrigger.repeats — die Nags
    /// sind einmal pro Tag, mit eindeutigem dayKey-Identifier, damit
    /// rescheduleSmartReminders sie bei einer späteren Einnahme sauber
    /// entfernen kann.
    ///
    /// - Es muss mindestens ein ~10-min-Fenster zwischen `startDate` und
    ///   `endDate` geben, sonst wird nichts geplant (sonst würden alle
    ///   3 Nags auf den gleichen Zeitpunkt fallen).
    static func scheduleNagReminders(
        primeHour: Int,
        untilHour: Int = 22,
        today: Date = Date()
    ) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let now = Date()
        let todayKey = DayKey.string(for: today)

        // Start = max(now, primeHour:00)
        var primeComps = calendar.dateComponents([.year, .month, .day], from: today)
        primeComps.hour = primeHour
        primeComps.minute = 0
        guard let primeFireDate = calendar.date(from: primeComps) else { return }
        let startDate = max(now, primeFireDate)

        // Ende = today at untilHour:00
        var endComps = calendar.dateComponents([.year, .month, .day], from: today)
        endComps.hour = untilHour
        endComps.minute = 0
        guard let endDate = calendar.date(from: endComps),
              endDate > startDate else { return }

        let windowSeconds = endDate.timeIntervalSince(startDate)
        guard windowSeconds > 600 else { return } // < 10 min — skip nag

        // Drei ~gleichmäßig verteilte Positionen im Fenster + Random-Jitter.
        // Wir rotieren durch leicht variierende Texte, damit es nicht
        // „dieselbe Nachricht 3×" wirkt.
        let positions: [Double] = [0.30, 0.60, 0.85]
        let nagVariants: [(title: String, body: String)] = [
            ("💊 Kurz checken?", "Hast du dein Kreatin heute schon genommen? Lass die Streak nicht abreißen."),
            ("⏰ Sanfter Stupser", "Eine kleine Erinnerung — dein Tagesziel wartet."),
            ("🔔 Letzte Chance heute", "Vor dem Schlafengehen — noch nicht eingenommen?"),
        ]

        for (i, fraction) in positions.enumerated() {
            // ±10 Min Jitter, damit die Uhrzeiten bei mehreren Tagen nicht
            // exakt identisch wirken.
            let jitter = TimeInterval.random(in: -600 ... 600)
            let fireDate = startDate.addingTimeInterval(windowSeconds * fraction + jitter)
            guard fireDate > now, fireDate <= endDate else { continue }

            let comps = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate
            )

            let content = UNMutableNotificationContent()
            let variant = nagVariants[i % nagVariants.count]
            content.title = variant.title
            content.body = variant.body
            content.sound = .default
            content.threadIdentifier = "creatime-nags"

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(
                identifier: "creatime-nag-\(todayKey)-\(i)",
                content: content,
                trigger: trigger
            ))
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
