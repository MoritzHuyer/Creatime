import Foundation

// Ein „Erfolg" (Badge), den man mit einer bestimmten Streak freischaltet.
// Gamification wie diese ist DER Grund, warum Leute bei Habit-Apps dranbleiben.
struct Achievement: Identifiable, Equatable {
    let days: Int      // ab dieser Streak ist der Erfolg freigeschaltet
    let emoji: String
    let title: String
    let subtitle: String

    // Identifiable verlangt eine eindeutige id — die Tageszahl reicht dafür.
    // `id` und `days` sind identisch → Equatable-Vergleich kann auf `days`
    // reduziert werden.
    var id: Int { days }

    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.days == rhs.days
            && lhs.emoji == rhs.emoji
            && lhs.title == rhs.title
            && lhs.subtitle == rhs.subtitle
    }

    static let all: [Achievement] = [
        Achievement(days: 0,   emoji: "🎓", title: "Erste Schritte",
                    subtitle: "Onboarding abgeschlossen + erster Tag getrackt"),
        Achievement(days: 3,   emoji: "🌱", title: "Guter Start",
                    subtitle: "3 Tage in Folge"),
        Achievement(days: 7,   emoji: "⚡️", title: "Eine Woche",
                    subtitle: "7 Tage in Folge"),
        Achievement(days: 14,  emoji: "💪", title: "Zwei Wochen",
                    subtitle: "14 Tage in Folge"),
        Achievement(days: 30,  emoji: "🏅", title: "Ein Monat",
                    subtitle: "30 Tage in Folge"),
        Achievement(days: 60,  emoji: "🦾", title: "Zwei Monate",
                    subtitle: "60 Tage in Folge"),
        Achievement(days: 100, emoji: "🏆", title: "Club der 100",
                    subtitle: "100 Tage in Folge"),
    ]

    /// Spezial-Achievement für das Onboarding — days: 0 weil es NICHTS
    /// mit der Streak-Länge zu tun hat, sondern mit der ersten
    /// bestätigten Einnahme NACHDEM das Onboarding durchgelaufen ist.
    static let onboardingStarter = Achievement(
        days: 0,
        emoji: "🎓",
        title: "Erste Schritte",
        subtitle: "Willkommen in deiner Streak-Reise"
    )
}

// MARK: - Streak-Freeze-Erfolge
//
// Diese Achievements zählen die Frozen-Days-Sammlung, NICHT die Streak.
// Wir registrieren sie separat, damit `CreatineStore.newlyAchieved`
// nicht versehentlich eines davon versehentlich bei Streak-Sprüngen
// feiert.

struct FreezeAchievement: Identifiable {
    let freezesUsed: Int
    let emoji: String
    let title: String
    let subtitle: String

    var id: Int { freezesUsed }

    static let all: [FreezeAchievement] = [
        FreezeAchievement(freezesUsed: 5,  emoji: "❄️", title: "Freeze-Sammler",
                         subtitle: "5 Streak-Schutz-Schilde gebraucht"),
    ]
}
