import WidgetKit
import SwiftUI

// MARK: - CreatimeStandByWidget
//
// StandBy-Modus ist iOS 17+: iPhones am Ladegerät zeigen ihn großflächig
// an. Die `accessoryCircular` und `accessoryRectangular` Lock-Screen-
// Widget-Familien werden dort automatisch vergrößert gerendert, OHNE
// dass wir etwas Spezielles machen müssen.
//
// HIER erstellen wir EIN eigenes Widget mit ruhigerem, größerem Layout,
// das speziell für die StandBy-Darstellung schön ist (große, zentrierte
// Streak-Zahl + Flame in einer ruhigen Optik ohne Mini-Wasserbalken, der
// in 200 pt Umfang visuell stören würde).
//
// Datenstruktur 1:1 zu CreatimeInteractiveEntry.

struct CreatimeStandByEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let takenToday: Bool
}

struct CreatimeStandByProvider: TimelineProvider {
    private func currentEntry() -> CreatimeStandByEntry {
        let defaults = SharedDefaults.store
        let takenDays = Set(defaults.stringArray(forKey: "takenDays") ?? [])
        let skippedDays = Set(defaults.stringArray(forKey: "skippedDays") ?? [])
        let frozenDays = Set(defaults.stringArray(forKey: "frozenDays") ?? [])
        return CreatimeStandByEntry(
            date: Date(),
            streak: StreakCalculator.currentStreak(
                takenDays: takenDays,
                skippedDays: skippedDays,
                frozenDays: frozenDays
            ),
            takenToday: takenDays.contains(DayKey.today)
        )
    }

    func placeholder(in context: Context) -> CreatimeStandByEntry {
        CreatimeStandByEntry(date: .now, streak: 12, takenToday: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (CreatimeStandByEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CreatimeStandByEntry>) -> Void) {
        let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
        completion(Timeline(entries: [currentEntry()], policy: .after(midnight)))
    }
}

struct CreatimeStandByWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CreatimeStandByEntry

    var body: some View {
        switch family {
        case .accessoryRectangular: rectangular
        default:                    circular  // accessoryCircular & Fallback
        }
    }

    /// StandBy-Hauptlayout: riesige Streak-Zahl mit Flame-ⓘ daneben.
    /// Wird IM StandBy groß dargestellt — wir setzen LinearGradient + Glow
    /// um der Zahl visuelle Tiefe zu geben.
    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Text("🔥")
                    .font(.system(size: 18))
                Text("\(entry.streak)")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .widgetAccentable()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    /// Rechteckiges StandBy-Layout: kompakte zwei-Zeilen Pill mit Streak
    /// und Tagesstatus. Wird auch im regulären Lock-Screen angezeigt.
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Creatime")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            Text("🔥 \(entry.streak)")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .widgetAccentable()
            Text(entry.takenToday ? "Heute erledigt ✓" : "Heute noch offen")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct CreatimeStandByWidget: Widget {
    let kind = "CreatimeStandByWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CreatimeStandByProvider()) { entry in
            CreatimeStandByWidgetView(entry: entry)
        }
        .configurationDisplayName("Creatime für StandBy")
        .description("Zeigt deine Streak groß im StandBy-Modus und am Lock-Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

#Preview(as: .accessoryCircular) {
    CreatimeStandByWidget()
} timeline: {
    CreatimeStandByEntry(date: .now, streak: 14, takenToday: true)
    CreatimeStandByEntry(date: .now, streak: 14, takenToday: false)
}

#Preview(as: .accessoryRectangular) {
    CreatimeStandByWidget()
} timeline: {
    CreatimeStandByEntry(date: .now, streak: 7, takenToday: false)
}
