import WidgetKit
import SwiftUI
import AppIntents

// MARK: - CreatimeInteractiveWidget (iOS 17 AppIntentConfiguration)
//
// Dieses Widget unterscheidet sich von `CreatimeWidget` durch die Provider-
// Art: Wir nutzen `AppIntentConfiguration` und damit `Button(intent:)`
// im Widget-View-Body — das erlaubt es, „Kreatin genommen" DIREKT aus
// dem Home-Screen-Widget zu drücken, ohne die App zu öffnen.
//
// Hintergrund: iOS 17 `WidgetConfiguration` hat zwei Geschmacksrichtungen:
//
//   • `StaticConfiguration` (TimelineProvider)        — passt für reine
//                                                        Anzeige. Buttons
//                                                        darin: nur system-
//                                                        genehmigte wie
//                                                        widgetURL/deep-link.
//
//   • `AppIntentConfiguration` (AppIntentTimelineProvider) — die App
//                                                        kann selbst AppIntents
//                                                        aus dem Widget triggern,
//                                                        die im Hintergrund
//                                                        laufen (`openAppWhenRun=false`).
//
// Unser bestehender `MarkCreatineTakenIntent` ist schon genau richtig
// für diesen Use-Case (`openAppWhenRun=false`, schreibt direkt nach
// SharedDefaults, ruft WidgetCenter.reloadAllTimelines()).
//
// Wir registrieren das Widget als ZWEITES Widget im Bundle hinzu —
// der „klassische" CreatimeWidget bleibt für Lock-Screen-Accessory
// Familien erhalten (diese unterstützen KEIN Button(intent:)).

// MARK: - Der Entry ist 1:1 zum alten Widget (gleiche Datenquelle).

struct CreatimeInteractiveEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let takenToday: Bool
    let waterML: Int
    let waterGoalML: Int
}

// MARK: - Provider: AppIntentTimelineProvider

struct CreatimeInteractiveProvider: AppIntentTimelineProvider {
    typealias Intent = MarkCreatineTakenIntent
    typealias Entry = CreatimeInteractiveEntry

    /// Liest den aktuellen Stand aus dem App-Group-Speicher.
    /// Wichtig: frozenDays werden mit eingelesen, damit die Streak-Zahl
    /// mit der App-Logik exakt übereinstimmt.
    private func currentEntry() -> CreatimeInteractiveEntry {
        let defaults = SharedDefaults.store
        let takenDays = Set(defaults.stringArray(forKey: "takenDays") ?? [])
        let skippedDays = Set(defaults.stringArray(forKey: "skippedDays") ?? [])
        let frozenDays = Set(defaults.stringArray(forKey: "frozenDays") ?? [])
        let waterByDay = defaults.dictionary(forKey: "waterByDay") as? [String: Int] ?? [:]
        let goal = defaults.integer(forKey: "waterDailyGoal")

        return CreatimeInteractiveEntry(
            date: Date(),
            streak: StreakCalculator.currentStreak(
                takenDays: takenDays,
                skippedDays: skippedDays,
                frozenDays: frozenDays
            ),
            takenToday: takenDays.contains(DayKey.today),
            waterML: waterByDay[DayKey.today] ?? 0,
            waterGoalML: goal > 0 ? goal : 2500
        )
    }

    func placeholder(in context: Context) -> CreatimeInteractiveEntry {
        CreatimeInteractiveEntry(date: .now, streak: 5, takenToday: false, waterML: 1250, waterGoalML: 2500)
    }

    func snapshot(for configuration: MarkCreatineTakenIntent, in context: Context) async -> CreatimeInteractiveEntry {
        currentEntry()
    }

    func timeline(for configuration: MarkCreatineTakenIntent, in context: Context) async -> Timeline<CreatimeInteractiveEntry> {
        let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
        return Timeline(entries: [currentEntry()], policy: .after(midnight))
    }
}

// MARK: - View

struct CreatimeInteractiveWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CreatimeInteractiveEntry

    private var waterProgress: Double {
        min(1.0, Double(entry.waterML) / Double(entry.waterGoalML))
    }

    private var waterLitersText: String {
        let liters = (Double(entry.waterML) / 1000)
            .formatted(.number.precision(.fractionLength(0...2)))
        return "\(liters) L"
    }

    var body: some View {
        switch family {
        case .systemMedium:  medium
        default:             small
        }
    }

    /// Das kleine Home-Screen-Quadrat. UNTER dem Kreatin-Status ist ein
    /// `Button(intent: MarkCreatineTakenIntent())` — sobald der User
    /// heute noch NICHT bestätigt hat, kann er direkt aus dem Widget
    /// bestätigen, OHNE die App zu öffnen. Das ist der Hauptwert dieses
    /// Widget-Familie.
    private var small: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("🔥").font(.title2)
                Text("\(entry.streak)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
            }

            // Wenn NOCH OFFEN: Button(intent:) = direkter Mark-Button aus
            // dem Widget. Wenn BEREITS ERLEDIGT: kleinere grüne Pill.
            if entry.takenToday {
                Text("Heute erledigt ✓")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            } else {
                Button(intent: MarkCreatineTakenIntent()) {
                    Text("Kreatin markieren")
                        .font(.caption.bold())
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(Color.accentColor.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }

            ProgressView(value: waterProgress)
                .tint(.blue)
            Text("\(waterLitersText) Wasser")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    /// Das mittlere Home-Screen-Widget: links die Streak, rechts eine
    /// Kreatin-Action (mit Button(intent:) wenn noch offen).
    private var medium: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("🔥").font(.largeTitle)
                Text("\(entry.streak)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text("Tage in Folge")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                if entry.takenToday {
                    Label("Kreatin: erledigt", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                } else {
                    Button(intent: MarkCreatineTakenIntent()) {
                        Label("Jetzt markieren", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }

                ProgressView(value: waterProgress)
                    .tint(.blue)
                Label("\(waterLitersText) Wasser", systemImage: "drop.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget-Konfiguration

struct CreatimeInteractiveWidget: Widget {
    let kind = "CreatimeInteractiveWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: MarkCreatineTakenIntent.self,
            provider: CreatimeInteractiveProvider()
        ) { entry in
            CreatimeInteractiveWidgetView(entry: entry)
        }
        .configurationDisplayName("Creatime (interaktiv)")
        .description("Kreatin direkt aus dem Home-Screen-Widget als genommen markieren.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    CreatimeInteractiveWidget()
} timeline: {
    CreatimeInteractiveEntry(date: .now, streak: 12, takenToday: false, waterML: 500, waterGoalML: 2500)
    CreatimeInteractiveEntry(date: .now, streak: 12, takenToday: true, waterML: 1750, waterGoalML: 2500)
}
