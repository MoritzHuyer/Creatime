import SwiftUI

// MARK: - Fortschritts-Tab (v7 — Glass-Card-Stil)
//
// Layout-Philosophie: 9 klar getrennte Sektionen mit großzügigem Abstand
// (22pt). Jede nutzt `.liquidGlassCard()` als Hintergrund.
//
// Reihenfolge (von oben nach unten):
//   1. Vacation-Banner (selten)
//   2. 6er-Stat-Grid (2×3, glass): Streak, Creatine-Quote, Wasser-Ø,
//      Buddy, Mood-Ø, Consistency-Score
//   3. Mood-HistoryChart (7-Bar-Chart)
//   4. Streak-Share-Banner
//   5. InsightsSection (4 Sub-Rows)
//   6. Wochenverlauf (Wasser + Creatin Charts)
//   7. BuddyView (komplett)
//   8. MonthCalendar mit DayCell
//   9. PhotoStreakSection

struct HistoryView: View {
    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var water
    @Environment(PhotoStreakStore.self) private var photoStore

    @State private var showSettings = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack {
                DynamicBackground()

                ScrollView {
                    VStack(spacing: 22) {

                        // VacationBanner sitzt im Heute-Tab — hier nur
                        // Listen-Ansicht ohne weiteren Tap-Handler.

                        statGrid

                        MoodHistoryChart()
                            .liquidGlassCard()

                        StreakShareBanner()
                            .liquidGlassCard()

                        InsightsSection()
                            .liquidGlassCard()

                        VStack(spacing: 14) {
                            WaterHistoryChart()
                                .liquidGlassCard()
                            CreatineHistoryChart()
                                .liquidGlassCard()
                        }

                        BuddyView()

                        MonthCalendar()
                            .liquidGlassCard()

                        PhotoStreakSection()
                            .liquidGlassCard()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Fortschritt")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Einstellungen öffnen")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - 6er-Stat-Grid (2×3 Glass-Cards)

    private var statGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(
                    icon: "flame.fill",
                    tint: .orange,
                    label: "Aktuelle Streak",
                    value: "\(store.currentStreak)",
                    suffix: "Tage"
                )
                StatTile(
                    icon: "checkmark.seal.fill",
                    tint: .green,
                    label: "Creatine-Quote",
                    value: "\(Int(store.last30DaysRate * 100))",
                    suffix: "% 30T"
                )
                StatTile(
                    icon: "drop.fill",
                    tint: .cyan,
                    label: "Wasser-Ø (7T)",
                    value: formatLiters(water.weeklyAverage),
                    suffix: "Liter"
                )
            }

            HStack(spacing: 12) {
                StatTile(
                    icon: "person.2.fill",
                    tint: .purple,
                    label: "Buddy",
                    value: "\(max(0, store.currentStreak - 0))",
                    suffix: "vs Lead"
                )
                StatTile(
                    icon: "face.smiling",
                    tint: .pink,
                    label: "Mood-Ø",
                    value: averageMoodLabel,
                    suffix: "Letzte 7T"
                )
                StatTile(
                    icon: "gauge.with.dots.needle.50percent",
                    tint: consistencyTint(store.consistencyScore),
                    label: "Konsistenz",
                    value: "\(store.consistencyScore)",
                    suffix: "/ 100"
                )
            }
        }
    }

    private func formatLiters(_ ml: Int) -> String {
        let v = Double(ml) / 1000
        return v.formatted(.number.precision(.fractionLength(0...2)))
            .replacingOccurrences(of: ".", with: ",")
    }

    private var averageMoodLabel: String {
        let recent = (0..<7).compactMap { offset -> Double? in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let key = DayKey.string(for: date)
            guard let mood = store.moodByDay[key],
                  let score = MoodHistoryChart.moodScore(for: mood) else { return nil }
            return score
        }
        guard !recent.isEmpty else { return "—" }
        let avg = recent.reduce(0, +) / Double(recent.count)
        return MoodHistoryChart.emoji(for: Int(avg.rounded()))
    }

    private func consistencyTint(_ score: Int) -> Color {
        switch score {
        case 80...:  return .green
        case 50..<80: return .blue
        default:     return .orange
        }
    }
}

// MARK: - Eine Stat-Kachel (glass)

private struct StatTile: View {
    let icon: String
    let tint: Color
    let label: String
    let value: String
    let suffix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.caption.bold())
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(suffix)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .frame(minHeight: 78, alignment: .topLeading)
    }
}

// MARK: - InsightsSection (4 Sub-Rows in einer Glass-Card)

struct InsightsSection: View {
    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var water

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Insights", systemImage: "sparkles")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            VStack(spacing: 0) {
                InsightRow(
                    icon: "drop.fill",
                    tint: .blue,
                    title: "Wasser-Ø diese Woche",
                    value: formatLiters(water.thisWeekAverageML),
                    suffix: "L"
                )
                Divider().padding(.vertical, 6)
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    tint: .blue.opacity(0.8),
                    title: "Wochenvergleich",
                    value: water.weekOverWeekText,
                    suffix: ""
                )
                Divider().padding(.vertical, 6)
                InsightRow(
                    icon: "exclamationmark.triangle.fill",
                    tint: .orange,
                    title: "Vergesslichster Wochentag",
                    value: topForgetfulWeekdayLabel,
                    suffix: ""
                )
                Divider().padding(.vertical, 6)
                InsightRow(
                    icon: "star.fill",
                    tint: .yellow,
                    title: "Score (Konsistenz 90T)",
                    value: "\(store.consistencyScore)",
                    suffix: "/ 100"
                )
            }
        }
        .padding(16)
    }

    private var topForgetfulWeekdayLabel: String {
        let labels = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"]
        guard let top = store.topForgetfulWeekday else { return "— keine Daten" }
        let idx = (top.weekday - 1 + 7) % 7
        return "\(labels[idx]) (\(top.count)×)"
    }

    private func formatLiters(_ ml: Int) -> String {
        let v = Double(ml) / 1000
        return v.formatted(.number.precision(.fractionLength(0...2)))
            .replacingOccurrences(of: ".", with: ",")
    }
}

private struct InsightRow: View {
    let icon: String
    let tint: Color
    let title: String
    let value: String
    let suffix: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value + (suffix.isEmpty ? "" : " " + suffix))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - MonthCalendar mit DayCell (Glass-Card-Inhalt)

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
        VStack(spacing: 12) {
            HStack {
                Button { changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.headline)
                Spacer()
                Button { changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: dayColumns, spacing: 8) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdaySymbols[i])
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, cell in
                    if let day = cell {
                        DayCell(day: day)
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }
        }
        .padding(16)
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            withAnimation {
                displayedMonth = newMonth
            }
        }
    }
}

// MARK: - DayCell (einfache Variante — wird in v8 durch ActivityRingDayCell ersetzt)

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
            Circle()
                .fill(fillColor(taken: taken, skipped: skipped, frozen: frozen))
                .frame(width: 30, height: 30)

            Text("\(dayNumber)")
                .font(.callout)
                .fontWeight(taken ? .bold : .regular)
                .foregroundStyle(textColor(taken: taken, isFuture: isFuture))

            if isToday {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 1.5)
                    .frame(width: 34, height: 34)
            }
        }
        .frame(width: 36, height: 36)
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
        return isFuture ? Color(.tertiaryLabel) : Color.primary
    }
}

#Preview {
    HistoryView()
        .environment(CreatineStore())
        .environment(WaterStore())
}
