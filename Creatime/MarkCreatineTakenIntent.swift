import AppIntents
import Foundation
import WidgetKit

// MARK: - App-only App-Intents
//
// Diese Datei enthält AppIntent-Definitionen, die NUR in der App-Target
// verwendet werden (Siri/Shortcuts): die MarkCreatineTakenIntent-Variante
// liegt in `Shared/CreatineMarkIntent.swift`, weil iOS 17 das Intent auch
// im Widget-Compilation-Context braucht (AppIntentConfiguration mit Button(intent:)).

// MARK: - App-Intent: Wasser eintragen (mit ml-Parameter)

struct MarkWaterIntakeIntent: AppIntent {

    static var title: LocalizedStringResource = "Wasser eintragen"

    static var description: IntentDescription = IntentDescription(
        "Trägt eine Trinkmenge dem heutigen Wasserzähler hinzu. Funktioniert aus dem Sperrbildschirm und über die Apple-Watch.",
        categoryName: "Tracking"
    )

    static var openAppWhenRun: Bool = false

    /// Standard 250 ml (Glas). Siri kann aber auch „500 ml" parsen.
    @Parameter(
        title: "Menge in ml",
        description: "Wieviel du gerade getrunken hast",
        default: 250
    )
    var amountML: Int

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = SharedDefaults.store
        var waterByDay = defaults.dictionary(forKey: "waterByDay") as? [String: Int] ?? [:]
        let key = DayKey.today
        let before = waterByDay[key] ?? 0
        let after = max(0, before + amountML)
        waterByDay[key] = after
        defaults.set(waterByDay, forKey: "waterByDay")

        WidgetCenter.shared.reloadAllTimelines()

        return .result(dialog: IntentDialog(stringLiteral:
            "Wasser eingetragen: plus \(amountML) Milliliter. Heute insgesamt \(after) Milliliter."))
    }
}

// MARK: - App-Intent: aktuelle Streak ansagen lassen

struct AskStreakIntent: AppIntent {

    static var title: LocalizedStringResource = "Wie ist meine Creatime-Streak?"

    static var description: IntentDescription = IntentDescription(
        "Siri liest dir deine aktuelle Creatime-Streak vor.",
        categoryName: "Abfrage"
    )

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = SharedDefaults.store
        let takenDays = Set(defaults.stringArray(forKey: "takenDays") ?? [])
        let skippedDays = Set(defaults.stringArray(forKey: "skippedDays") ?? [])
        let frozenDays = Set(defaults.stringArray(forKey: "frozenDays") ?? [])

        let streak = StreakCalculator.currentStreak(
            takenDays: takenDays,
            skippedDays: skippedDays,
            frozenDays: frozenDays
        )
        let takenToday = takenDays.contains(DayKey.today)
        let spoken: String = {
            if takenToday {
                return "Deine Creatime-Streak ist \(streak) Tage. Heute hast du schon eingetragen — gut gemacht."
            } else {
                return "Deine Creatime-Streak ist \(streak) Tage. Heute steht noch aus."
            }
        }()
        return .result(dialog: IntentDialog(stringLiteral: spoken))
    }
}

// MARK: - AppShortcutsProvider
//
// Stellt diese Intents der Shortcuts-App zur Verfügung, sodass Siri die
// Aktivierungs-Phrasen direkt lernt, ohne dass der User sie selbst
// einrichten muss. In iOS 17 ist das die übliche Art, ein Intent
// zu „publishen".

struct CreatimeShortcutsProvider: AppShortcutsProvider {

    /// App-Farbe für Siri-Background (passt zum Liquid-Glass-Look).
    static var shortcutTileColor: ShortcutTileColor = .orange

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: MarkCreatineTakenIntent(),
            phrases: [
                "Ich habe heute Kreatin genommen in \(.applicationName)",
                "Markiere mein Kreatin als genommen in \(.applicationName)",
                "\(.applicationName) Kreatin eingenommen",
                "Kreatin für heute eintragen in \(.applicationName)",
            ],
            shortTitle: "Kreatin markieren",
            systemImageName: "checkmark.circle.fill"
        )
        AppShortcut(
            intent: MarkWaterIntakeIntent(),
            phrases: [
                "Trink \(.applicationName) Wasser",
                "Ich habe Wasser getrunken in \(.applicationName)",
                "\(.applicationName) Wasser eintragen",
            ],
            shortTitle: "Wasser eintragen",
            systemImageName: "drop.fill"
        )
        AppShortcut(
            intent: AskStreakIntent(),
            phrases: [
                "Wie ist meine \(.applicationName) Streak",
                "\(.applicationName) Streak vorlesen",
            ],
            shortTitle: "Streak vorlesen",
            systemImageName: "flame.fill"
        )
    }
}
