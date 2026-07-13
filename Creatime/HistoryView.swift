import SwiftUI

// MARK: - Fortschritts-Tab (Editorial-Stil)
//
// Layout-Philosophie: ein Hero-Streak-Block oben, darunter ruhige
// kompakte Sektionen statt vieler Karten. Reihenfolge:
//   1. VacationBanner (selten — kompakt)
//   2. HERO-Streak (riesige Zahl + Assessment-Text)
//   3. „Key stats" — 4-spaltige kompakte Typografie-Zeile
//   4. Mood-Chart (kompakter als vorher)
//   5. Insights-Strip (Score-Ring + Heatmap + Wochenvergleich in einer Zeile)
//   6. Verlaufs-Charts (Wasser, Kreatin) — kompakt gestapelt
//   7. BuddyView (typografisch zurückhaltender)
//   8. MonthCalendar (Hauptelement)
//   9. Foto-Streak (unten)

struct HistoryView: View {
    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var water
    @Environment(PhotoStreakStore.self) private var photoStore

    @State private var showSettings = false
    @State private var displayedMonth = Date()
    private let calendar = Calendar.current

    /// "Perfekte Tage": Kreatin genommen UND Wasserziel am selben Tag erreicht.
    private var perfectDays: Int {
        store.takenDays.filter { day in
            (water.waterByDay[day] ?? 0) >= water.dailyGoal
        }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        heroStreak
                            .padding(.top, 8)

                        // Kompakte 4-Spalten Key-Stats
                        keyStats
                            .padding(.top, 32)

                        // Foto-Streak-Karussell (Hero, nur wenn ≥ 1 Eintrag)
                        if !photoStore.entries.isEmpty {
                            Text("FOTOS")
                                .sectionLabelStyle()
                                .padding(.top, 32)
                            PhotoStreakCarousel()
                                .padding(.top, 6)
                        }

                        Text("STIMMUNG · LETZTE 7 TAGE")
                            .sectionLabelStyle()
                            .padding(.top, 36)
                        MoodHistoryChart()
                            .padding(.top, 6)

                        Text("INSIGHTS")
                            .sectionLabelStyle()
                            .padding(.top, 36)
                        InsightsStrip()
                            .padding(.top, 6)

                        Text("VERLAUF")
                            .sectionLabelStyle()
                            .padding(.top, 36)
                        VStack(spacing: 12) {
                            WaterHistoryChart()
                            CreatineHistoryChart()
                        }
                        .padding(.top, 6)

                        Text("STREAK-BATTLE")
                            .sectionLabelStyle()
                            .padding(.top, 36)
                        BuddyView()
                            .padding(.top, 6)

                        Text("KALENDER")
                            .sectionLabelStyle()
                            .padding(.top, 36)
                        MonthCalendar()
                            .padding(.top, 6)

                        Text("FOTO-STREAK")
                            .sectionLabelStyle()
                            .padding(.top, 36)
                        PhotoStreakSection()
                            .padding(.top, 6)
                            .padding(.bottom, 32)

                        // Streak-Share-Banner (typografisch dezent, am Ende)
                        StreakShareBanner()
                            .padding(.top, 24)
                            .padding(.bottom, 16)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Fortschritt")
            .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - HERO-STREAK

    private var heroStreak: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AKTUELLE STREAK")
                .sectionLabelStyle()
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(store.currentStreak)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .monospacedDigit()
                Text("Tage")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Label("Beste \(store.bestStreak)", systemImage: "trophy.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.yellow)
                Text("·")
                    .foregroundStyle(.tertiary)
                Label("\(store.totalDays) gesamt", systemImage: "checkmark.circle.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.green)
                Text("·")
                    .foregroundStyle(.tertiary)
                Label("\(Int(store.last30DaysRate * 100))% (30T)", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.blue)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Kompakte Key-Stats-Zeile (4 Spalten)

    private var keyStats: some View {
        HStack(alignment: .top, spacing: 0) {
            KeyStatCol(label: "Ø Wasser/Wo",
                       value: avgWaterText,
                       tint: .cyan)
            Divider().frame(height: 36).opacity(0.4)
            KeyStatCol(label: "Perfekte Tage",
                       value: "\(perfectDays)",
                       tint: .purple)
            Divider().frame(height: 36).opacity(0.4)
            KeyStatCol(label: "Score",
                       value: "\(store.consistencyScore)",
                       tint: consistencyTint(store.consistencyScore))
            Divider().frame(height: 36).opacity(0.4)
            KeyStatCol(label: "Mood Ø",
                       value: averageMoodLabel,
                       tint: .orange)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    /// Wöchentlicher Wasser-⌀ als formatierter Text (z. B. „1,8 L").
    private var avgWaterText: String {
        let liters = Double(water.weeklyAverage) / 1000
        let raw = liters.formatted(.number.precision(.fractionLength(0...2)))
        return raw.replacingOccurrences(of: ".", with: ",") + " L"
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

// MARK: - Section-Label Style

private extension View {
    /// Caption in Caps mit Tracking + Tertiär — wiederverwendbar für alle
    /// Sektionstitel im HistoryView.
    func sectionLabelStyle() -> some View {
        self.font(.caption2.weight(.semibold))
            .tracking(1.4)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Eine Key-Stat-Spalte

private struct KeyStatCol: View {
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - INSIGHTS-STRIP (Score-Ring + Heatmap + Wochenvergleich in EINEM)
//
// Statt der ursprünglichen Card mit zwei Sub-Rows packen wir die drei
// Insight-Visualisierungen nebeneinander auf eine ruhige Linie. Das
// reduziert die Card-Höhe um ca. 60%.

struct InsightsStrip: View {
    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var water

    private let weekdayShort = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // 1) Konsistenz-Score-Ring klein
            consistencyRing
                .frame(maxWidth: .infinity)

            Divider().frame(height: 60).padding(.horizontal, 4).opacity(0.4)

            // 2) Vergesslichkeits-Heatmap (7 Balken)
            heatmap
                .frame(maxWidth: .infinity)

            Divider().frame(height: 60).padding(.horizontal, 4).opacity(0.4)

            // 3) Wochenvergleich Wasser
            weeklyCompare
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 1) Score-Ring (klein)

    private var consistencyRing: some View {
        let score = store.consistencyScore
        let tint: Color = {
            switch score {
            case 80...:  return .green
            case 50..<80: return .blue
            default:     return .orange
            }
        }()
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(tint.opacity(0.18), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: Double(score) / 100.0)
                    .stroke(tint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.snappy, value: score)
                Text("\(score)")
                    .font(.system(.headline, design: .rounded).bold())
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
            }
            .frame(width: 54, height: 54)
            .accessibilityLabel("Konsistenz-Score \(score) von 100")

            Text("Score")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 2) Heatmap (7 Balken)

    private var heatmap: some View {
        let counts = (1...7).map { store.forgetfulnessByWeekday[$0] ?? 0 }
        let maxCount = max(1, counts.max() ?? 1)

        return VStack(alignment: .center, spacing: 4) {
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(counts.indices, id: \.self) { i in
                    let c = counts[i]
                    let h = max(3, CGFloat(c) / CGFloat(maxCount) * 30)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(c == 0 ? Color(.tertiarySystemFill) : .orange.opacity(0.7))
                        .frame(width: 8, height: h)
                }
            }
            .frame(height: 36)
            Text("Vergessen")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Vergesslichkeit letzte 90 Tage, max \(counts.max() ?? 0) an einem Wochentag")
    }

    // MARK: - 3) Wochenvergleich Wasser

    private var weeklyCompare: some View {
        let current = Double(water.thisWeekAverageML) / 1000
        let delta = water.weekOverWeekText
        let trendSymbol: String = {
            guard let d = water.weekOverWeekDelta else { return "✨" }
            if d > 0.02 { return "📈" }
            if d < -0.02 { return "📉" }
            return "✨"
        }()

        return VStack(spacing: 4) {
            Text(trendSymbol)
                .font(.title3)
            Text(delta)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(.blue)
            Text("\(current.formatted(.number.precision(.fractionLength(0...1)))) L/Wo")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Wasser-Wochenvergleich \(delta), diese Woche \(current) Liter")
    }
}

// MARK: - Der Monatskalender (Editorial — ruhiger Hintergrund)

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
                        ActivityRingDayCell(day: day)
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            withAnimation {
                displayedMonth = newMonth
            }
        }
    }
}

// MARK: - Alte AchievementsSection (entfernt — durch AchievementsView-Tab ersetzt)
// DayCell-Stub ebenfalls entfernt — MonthCalendar verwendet direkt ActivityRingDayCell.
