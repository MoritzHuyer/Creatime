import SwiftUI

// MARK: - Fortschritts-Tab (v13 — Airy / inline)
//
// Layout-Philosophie: 8 Sections mit 28pt Atmung statt 22pt Card-Spacing.
// Inline-Komponenten ohne Glass-Card-Wrapper, eigene Subtle-Tiles für
// Stat-Rows. Genau EINE inline StreakShareBanner-Definition.
//
// Reihenfolge:
//   1. 6er-Stat-Grid 2×3
//   2. Mood-HistoryChart (inline)
//   3. StreakShare-Banner (lila Pill, inline defined)
//   4. Insights (großer Score-Ring + Vergessen am Tag + Wochenvergleich)
//   5. WaterHistoryChart (inline, bg.clear)
//   6. CreatineHistoryChart (inline, bg.clear)
//   7. BuddyView (airySection)
//   8. MonthCalendar (white tile w/ border)
//   9. PhotoStreakSection (airySection)

struct HistoryView: View {
    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var water
    @Environment(PhotoStreakStore.self) private var photoStore

    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                DynamicBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        statGrid
                        MoodHistoryChart()
                        StreakShareBanner()
                        insightsSection
                        WaterHistoryChart()
                        CreatineHistoryChart()
                        BuddyView()
                        MonthCalendar()
                        PhotoStreakSection()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Fortschritt")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Einstellungen öffnen")
                }
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    // MARK: - 6er Stat-Grid 2×3

    private var statGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SimpleStatTile(icon: "flame.fill", tint: .orange,
                               label: "Aktuelle Streak",
                               value: "\(store.currentStreak)", suffix: nil)
                SimpleStatTile(icon: "checkmark.seal.fill", tint: .green,
                               label: "Beste Streak",
                               value: "\(store.bestStreak)", suffix: nil)
                SimpleStatTile(icon: "calendar", tint: Color.accentColor,
                               label: "Tage gesamt",
                               value: "\(store.totalDays)", suffix: nil)
            }
            HStack(spacing: 12) {
                SimpleStatTile(icon: "chart.line.uptrend.xyaxis", tint: .indigo,
                               label: "Letzte 30 Tage",
                               value: "\(Int(store.last30DaysRate * 100))", suffix: "%")
                SimpleStatTile(icon: "drop.fill", tint: .cyan,
                               label: "Ø Wasser (7 Tage)",
                               value: formatLiters(water.weeklyAverage), suffix: "L")
                SimpleStatTile(icon: "star.fill", tint: .yellow,
                               label: "Perfekte Tage",
                               value: "\(store.perfectDaysLast30)", suffix: nil)
            }
        }
    }

    // MARK: - Insights Section: 22-Ring + Wochenvergleich + Vergessen am Tag

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 0) {
                // Big Score Ring (22-er Ersatz)
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemFill), lineWidth: 10)
                            .frame(width: 110, height: 110)
                        Circle()
                            .trim(from: 0, to: min(1.0, Double(store.consistencyScore) / 100.0))
                            .stroke(
                                LinearGradient(
                                    colors: [Color.indigo, Color.indigo.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 110, height: 110)
                            .animation(.snappy, value: store.consistencyScore)
                        VStack(spacing: 0) {
                            Text("\(store.consistencyScore)")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.indigo)
                            Text("Score")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("Die geht weiter")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.indigo)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 110)
                    .padding(.horizontal, 8)

                // Vergessen am Tag (Mo-So Bars)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Vergessen am Tag")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    HStack(alignment: .bottom, spacing: 5) {
                        ForEach(weekdayMissBars(), id: \.label) { entry in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(entry.misses > 0
                                          ? Color.orange.opacity(0.85)
                                          : Color(.tertiarySystemFill))
                                    .frame(width: 8, height: max(4, CGFloat(entry.misses) * 8))
                                Text(entry.label)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            // 3-Metric Vergleich Diese Woche / Letzte / Trend
            HStack(spacing: 0) {
                weekMetric(label: "Diese Woche",
                           value: formatLiters(water.thisWeekAverageML),
                           tint: .blue)
                weekMetric(label: "Letzte Woche",
                           value: formatLiters(water.lastWeekAverageML),
                           tint: .secondary)
                weekMetric(label: "Trend",
                           value: trendDelta(),
                           tint: trendIsPositive() ? .green : .orange)
            }
        }
        .airySection()
    }

    private func weekMetric(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func trendIsPositive() -> Bool {
        water.lastWeekAverageML > 0
            && water.thisWeekAverageML >= water.lastWeekAverageML
    }

    private func trendDelta() -> String {
        let last = water.lastWeekAverageML
        guard last > 0 else { return "—" }
        let delta = Double(water.thisWeekAverageML - last) / Double(last) * 100
        let abs = Int(delta.rounded())
        return (delta >= 0 ? "+" : "") + "\(abs)%"
    }

    private struct WeekdayBar: Hashable {
        let label: String
        let misses: Int
    }

    private func weekdayMissBars() -> [WeekdayBar] {
        let labels = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
        var counts = [Int](repeating: 0, count: 7)
        let util = MetricsCalculator.forgetfulnessByWeekday(
            takenDays: store.takenDays,
            skippedDays: store.skippedDays,
            daysBack: 90
        )
        for (wd, count) in util {
            // Calendar.weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
            // Wir wollen Index: 0=Mo, 1=Di, 2=Mi, 3=Do, 4=Fr, 5=Sa, 6=So
            let idx = (wd + 5) % 7
            if (0..<7).contains(idx) {
                counts[idx] = count
            }
        }
        return zip(labels, counts).map { WeekdayBar(label: $0.0, misses: $0.1) }
    }

    private func formatLiters(_ ml: Int) -> String {
        let v = Double(ml) / 1000
        let s = v.formatted(.number.precision(.fractionLength(0...2)))
        return s.replacingOccurrences(of: ".", with: ",")
    }
}

// MARK: - SimpleStatTile (v13 — white tile + subtle shadow / border)

struct SimpleStatTile: View {
    let icon: String
    let tint: Color
    let label: String
    let value: String
    let suffix: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.caption.bold())
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if let suffix {
                    Text(suffix)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .frame(minHeight: 78, alignment: .topLeading)
    }
}

// MARK: - StreakShareBanner (v13 — purple pill, inline defined exactly ONCE)

struct StreakShareBanner: View {
    @Environment(CreatineStore.self) private var store

    private var bestSnapshot: Int { store.bestStreak }

    var body: some View {
        Button {
            Haptics.tapMedium()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up.fill")
                    .foregroundStyle(.white)
                    .font(.subheadline.weight(.bold))
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.2), in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text("Streak teilen")
                        .font(.subheadline.weight(.semibold))
                    Text("Dein \(store.currentStreak)-Tage-Streak im Bild verschicken.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.caption.bold())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.indigo, Color.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Streak-Karte teilen, \(store.currentStreak) Tage in Folge")
    }
}

// MARK: - MonthCalendar (clean inline)

struct MonthCalendar: View {
    @Environment(CreatineStore.self) private var store
    @State private var displayedMonth = Date()
    private let calendar = Calendar.current
    private let dayColumns = Array(repeating: GridItem(.flexible()), count: 7)

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...]) + Array(symbols[..<first])
    }

    private var monthCells: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let dayCount = calendar.range(of: .day, in: .month, for: displayedMonth)?.count
        else { return [] }
        let firstDay = monthInterval.start
        let weekdayOfFirst = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<dayCount {
            cells.append(calendar.date(byAdding: .day, value: offset, to: firstDay))
        }
        return cells
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button { changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.headline)
                Spacer()
                Button { changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: dayColumns, spacing: 10) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdaySymbols[i])
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, cell in
                    if let day = cell {
                        DayCell(day: day)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
        .padding(14)
        // v14.2: defensive .frame(maxWidth: .infinity) damit der
        // Monats-Kalender-Gesamtblock NIE breiter wird als der
        // ScrollView-Parent — auch falls ein zukünftiger Sub-Component
        // mal überläuft.
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            withAnimation { displayedMonth = newMonth }
        }
    }
}

// MARK: - DayCell

struct DayCell: View {
    @Environment(CreatineStore.self) private var store
    let day: Date

    var body: some View {
        let taken = store.isTaken(day)
        let skipped = store.isSkipped(day)
        let frozen = store.isFrozen(day)
        let isToday = Calendar.current.isDateInToday(day)
        let isFuture = day > Date() && !isToday
        let dayNumber = Calendar.current.component(.day, from: day)

        ZStack {
            // v14.2: Innen-Circle adaptiv (maxWidth:.infinity +
            // aspectRatio 1) statt fixed 30 — füllt die Zelle voll
            // aus und clippt nicht mehr auf schmalen Phones.
            Circle()
                .fill(fillColor(taken: taken, skipped: skipped, frozen: frozen))
                .padding(2)
            Text("\(dayNumber)")
                .font(.callout)
                .fontWeight(taken ? .bold : .regular)
                .foregroundStyle(textColor(taken: taken, isFuture: isFuture))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            // Auch der today-Border ist adaptiv (1pt Inset statt 34pt-radius).
            if isToday {
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: 1.5)
                    .padding(0)
            }
        }
        // v14.1: fixed 38pt frame entfernt — flex statt fixed.
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .opacity(isFuture ? 0.5 : 1)
    }

    private func fillColor(taken: Bool, skipped: Bool, frozen: Bool) -> Color {
        if taken { return .green }
        if frozen { return .cyan }
        if skipped { return .orange }
        return Color(.tertiarySystemFill)
    }

    private func textColor(taken: Bool, isFuture: Bool) -> Color {
        if taken { return .white }
        return isFuture ? Color(.tertiaryLabel) : .primary
    }
}

#Preview {
    HistoryView()
        .environment(CreatineStore())
        .environment(WaterStore())
}
