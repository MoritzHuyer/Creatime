import WidgetKit
import SwiftUI

// Das Homescreen-Widget. Wichtig zu verstehen: Ein Widget ist KEINE
// laufende Mini-App, sondern ein „Foto", das iOS zu geplanten Zeitpunkten
// neu aufnimmt. Der TimelineProvider liefert diese Fotos (Entries) und
// sagt iOS, wann das nächste fällig ist. Zusätzlich stupst unsere App das
// Widget bei jeder Datenänderung an (WidgetCenter.reloadAllTimelines).

// MARK: - Ein Entry = der Datenstand für einen Anzeige-Zeitpunkt

struct CreatimeEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let takenToday: Bool
    let waterML: Int
    let waterGoalML: Int
}

// MARK: - Der Provider: liest die Daten aus der App Group

struct CreatimeProvider: TimelineProvider {

    /// Liest den echten Datenstand aus dem gemeinsamen Speicher.
    /// frozenDays werden mit eingelesen, damit die Streak-Zahl mit der
    /// App-Logik exakt übereinstimmt (Pausen-Tage rechnen sich durch).
    private func currentEntry() -> CreatimeEntry {
        let defaults = SharedDefaults.store
        let takenDays = Set(defaults.stringArray(forKey: "takenDays") ?? [])
        let skippedDays = Set(defaults.stringArray(forKey: "skippedDays") ?? [])
        let frozenDays = Set(defaults.stringArray(forKey: "frozenDays") ?? [])
        let waterByDay = defaults.dictionary(forKey: "waterByDay") as? [String: Int] ?? [:]
        let goal = defaults.integer(forKey: "waterDailyGoal")

        return CreatimeEntry(
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

    func placeholder(in context: Context) -> CreatimeEntry {
        CreatimeEntry(date: Date(), streak: 5, takenToday: false, waterML: 1250, waterGoalML: 2500)
    }

    func getSnapshot(in context: Context, completion: @escaping (CreatimeEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CreatimeEntry>) -> Void) {
        let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
        completion(Timeline(entries: [currentEntry()], policy: .after(midnight)))
    }
}

// MARK: - Das Aussehen des Widgets

struct CreatimeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    let entry: CreatimeEntry

    private var waterProgress: Double {
        min(1.0, Double(entry.waterML) / Double(entry.waterGoalML))
    }

    private var waterGoalReached: Bool { entry.waterML >= entry.waterGoalML }

    private var waterPercent: Int { Int((waterProgress * 100).rounded()) }

    /// Akzentfarbe = das in der App gewählte Theme (aus der App Group).
    private var accent: Color {
        ThemeAccent.color(
            forRawValue: SharedDefaults.store.string(forKey: "themeRaw"),
            dark: colorScheme == .dark
        )
    }

    private var waterLitersText: String {
        let liters = (Double(entry.waterML) / 1000)
            .formatted(.number.precision(.fractionLength(0...2)))
        return "\(liters) L"
    }

    var body: some View {
        switch family {
        case .accessoryCircular:  accessoryCircular
        case .accessoryRectangular: accessoryRectangular
        case .accessoryInline:    accessoryInline
        case .systemMedium:       medium
        default:                  small
        }
    }

    /// Das kleine quadratische Home-Screen-Widget (KEIN Button(intent:) —
    /// das macht die interaktive Variante in CreatimeInteractiveWidget).
    private var small: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text("🔥").font(.title2)
                Text("\(entry.streak)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            }
            Text(entry.takenToday ? "Heute erledigt ✓" : "Noch offen!")
                .font(.caption.bold())
                .foregroundStyle(entry.takenToday ? .green : .orange)

            Spacer(minLength: 0)

            HStack {
                Label("\(waterLitersText)", systemImage: "drop.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(waterPercent)%")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(waterGoalReached ? .green : accent)
            }
            ProgressView(value: waterProgress)
                .tint(waterGoalReached ? .green : accent)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    /// Das breite Widget: links Streak, rechts Wasser + Kreatin-Status.
    private var medium: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("🔥").font(.largeTitle)
                Text("\(entry.streak)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                Text(entry.streak == 1 ? "Tag in Folge" : "Tage in Folge")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label(
                    entry.takenToday ? "Kreatin: erledigt" : "Kreatin: noch offen",
                    systemImage: entry.takenToday ? "checkmark.circle.fill" : "circle"
                )
                .font(.subheadline.bold())
                .foregroundStyle(entry.takenToday ? .green : .primary)

                HStack {
                    Label("\(waterLitersText) Wasser", systemImage: "drop.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(waterPercent)%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(waterGoalReached ? .green : accent)
                }
                ProgressView(value: waterProgress)
                    .tint(waterGoalReached ? .green : accent)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    /// Lock-Screen-Accessory-Variante. StandBy rendert diese Layouts groß;
    /// für eine wirklich ruhige StandBy-Optik siehe CreatimeStandByWidget.
    private var accessoryCircular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("🔥")
                    .font(.system(size: 14))
                Text("\(entry.streak)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .widgetAccentable()
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Text("🔥 \(entry.streak)")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .widgetAccentable()
                Text(entry.takenToday ? " · ✓" : " · offen")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
            }
            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ProgressView(value: waterProgress)
                    .widgetAccentable()
                Text("\(waterLitersText)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var accessoryInline: some View {
        Text("🔥 \(entry.streak) · \(waterLitersText)")
    }
}

// MARK: - Registrierung des Widgets

struct CreatimeWidget: Widget {
    let kind = "CreatimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CreatimeProvider()) { entry in
            CreatimeWidgetView(entry: entry)
        }
        .configurationDisplayName("Creatime")
        .description("Deine Streak und dein Wasserstand — auch auf dem Lock-Screen.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// @main: der Einstiegspunkt der Widget-Extension (wie CreatimeApp für die App).
// Ein Bundle kann mehrere Widgets enthalten. Wir registrieren:
//   1) CreatimeWidget              — statisch, alle Familien
//   2) CreatimeInteractiveWidget   — AppIntent-based, nur systemSmall/systemMedium
//                                   mit Button(intent:) für direktes Markieren
//   3) CreatimeStandByWidget       — StandBy-optimierte Lock-Screen-Variante
//   4) CreatimeLiveActivity        — Dynamic Island + Lock-Screen-Banner
@main
struct CreatimeWidgetBundle: WidgetBundle {
    var body: some Widget {
        CreatimeWidget()
        CreatimeInteractiveWidget()
        CreatimeStandByWidget()
        CreatimeLiveActivity()
    }
}

#Preview(as: .systemSmall) {
    CreatimeWidget()
} timeline: {
    CreatimeEntry(date: .now, streak: 12, takenToday: true, waterML: 1750, waterGoalML: 2500)
    CreatimeEntry(date: .now, streak: 12, takenToday: false, waterML: 500, waterGoalML: 2500)
}

#Preview(as: .accessoryCircular) {
    CreatimeWidget()
} timeline: {
    CreatimeEntry(date: .now, streak: 8, takenToday: true, waterML: 1500, waterGoalML: 2500)
}

#Preview(as: .accessoryRectangular) {
    CreatimeWidget()
} timeline: {
    CreatimeEntry(date: .now, streak: 8, takenToday: false, waterML: 800, waterGoalML: 2500)
}
