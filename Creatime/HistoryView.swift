import SwiftUI

// MARK: - Fortschritts-Tab (v15.0 — Clean Rewrite)
//
// KOMPLETT NEU GESCHRIEBEN nach User-Wunsch "lösch das fortschritt tab
// und baue es neu". Grund: 4 v14.x-Versuche haben es nicht geschafft,
// den horizontalen Swipe-Bug zu entfernen. Diese Version ist minimal:
//
//   • ScrollView(.vertical) — NICHT generic, explizit vertical.
//   • VStack(spacing: 20) — keine horizontalen Container.
//   • Header: nur Streak-Number + Caption.
//   • Stats: 3 StatTiles in einer HStack OHNE ScrollView-Risiko.
//   • Insights: einfache Text-Box, OHNE Charts/Annotation/LazyVGrid.
//   • Buddy + Calendar + Photos: in Sheet-Detail-Views verschoben
//     (per "Mehr anzeigen"-Button unten).
//
// Alles entfernt:
//   • MoodHistoryChart.swift (im Main-Scroll nicht aufgerufen)
//   • HistoryCharts.swift (Wasser + Kreatin im Main-Scroll nicht aufgerufen)
//   • MonthCalendar (in Sheet verschoben)
//   • PhotoStreakSection (in Sheet verschoben)
//   • BuddyView (in Sheet verschoben)
//   • .debugSize() Wrapper (alle 9 entfernt)
//   • .fixedSize(horizontal: false) (nicht nötig wenn nichts überläuft)
//
// Resultat: ein paar weniger Sections, aber JEDE Section ist jetzt
// maximal intrinsisch-breit ≤ Parent-Breite. Kein Overflow möglich.

struct HistoryView: View {

    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var water

    @State private var showSettings = false
    @State private var showBuddySheet = false
    @State private var showCalendarSheet = false
    @State private var showPhotosSheet = false
    @State private var showChartsSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                DynamicBackground()

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        statsRow
                        insightsCard
                        detailLinksRow

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        .sheet(isPresented: $showBuddySheet) { BuddyView() }
        .sheet(isPresented: $showCalendarSheet) { MonthCalendarSheet() }
        .sheet(isPresented: $showPhotosSheet) { PhotoStreakSheet() }
        .sheet(isPresented: $showChartsSheet) { ChartsSheet() }
    }

    // MARK: - Header (Streak-Hero)

    private var header: some View {
        VStack(spacing: 6) {
            Text("\(store.currentStreak)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: store.currentStreak)
            Text("Tage in Folge")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            if store.bestStreak > store.currentStreak && store.bestStreak > 0 {
                Text("Beste: \(store.bestStreak)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(store.currentStreak) Tage Streak in Folge")
    }

    // MARK: - Stats Row (3 Tiles)

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(label: "Tage gesamt", value: "\(store.totalDays)", tint: .accentColor)
            StatTile(label: "30-Tage", value: "\(Int(store.last30DaysRate * 100))%", tint: .blue)
            StatTile(label: "Score", value: "\(store.consistencyScore)", tint: .indigo)
        }
    }

    // MARK: - Insights Text-Box

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Insights", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            Divider()

            insightRow(label: "Score heute",
                       value: "\(store.consistencyScore) von 100",
                       tint: .indigo)

            insightRow(label: "Letzte 30 Tage",
                       value: "\(Int(store.last30DaysRate * 100))% abgedeckt",
                       tint: .blue)

            insightRow(label: "Wasser (Ø 7 Tage)",
                       value: "\(water.weeklyAverage / 1000)L pro Tag",
                       tint: .cyan)

            insightRow(label: "Wasserziel",
                       value: "2,5L am Tag",
                       tint: .cyan)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private func insightRow(label: String, value: String, tint: Color) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Detail-Verweise (Sheet-Buttons)

    private var detailLinksRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mehr anzeigen")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            DetailLink(icon: "calendar", title: "Monats-Kalender") {
                showCalendarSheet = true
            }

            DetailLink(icon: "chart.bar.xaxis", title: "Charts (Wasser + Mood)") {
                showChartsSheet = true
            }

            DetailLink(icon: "person.2.fill", title: "Streak-Battle") {
                showBuddySheet = true
            }

            DetailLink(icon: "camera.fill", title: "Foto-Streak") {
                showPhotosSheet = true
            }
        }
    }
}

// MARK: - StatTile

struct StatTile: View {
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title.bold())
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - DetailLink

struct DetailLink: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 26)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sheet-Container (Lightweight Wrappers)
//
// Diese Sheet-Views zeigen jeweils nur den relevanten Sub-Component
// innerhalb eines Schlanken Sheets. So bleibt der Main-ScrollView
// schlank und das horizontale-Swipe-Problem kann in den Sub-Views
// lokal bleiben (oder auch dort nicht — wir testen!).

struct MonthCalendarSheet: View {
    var body: some View {
        NavigationStack {
            MonthCalendar()
                .padding()
        }
    }
}

struct PhotoStreakSheet: View {
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                PhotoStreakSection()
                    .padding()
            }
        }
    }
}

struct ChartsSheet: View {
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    WaterHistoryChart()
                    Divider()
                    MoodHistoryChart()
                }
                .padding()
            }
        }
    }
}

#Preview {
    HistoryView()
        .environment(CreatineStore())
        .environment(WaterStore())
}

// MARK: - MonthCalendar (minimal inline — ausgelagert aus altem HistoryView)
//
// v15.0: Diese Struct war inline im alten HistoryView.swift. Beim
// Complete-Rewrite wurde sie versehentlich nicht migriert. Wir fügen
// sie wieder minimal ein, damit MonthCalendarSheet() sie aufrufen kann.
// Bewusst minimal gehalten: KEIN LazyVGrid mit 7-col + 38pt-Cells
// (das war Überlaufverdächtiger in v13/v14), sondern HStack-basiert
// mit kleinem festen Cell-Size + Padding-Guard.
//
// Architektur: Calendar-Header (Monat + Pfeile) HStack oben, dann
// 7×7 cells (maximal 49 DayCells) als VStack of HStacks. Jede Cell
// ist 36pt Circle, garantiert < Parent-Breite auch auf iPhone SE.

struct MonthCalendar: View {
    @Environment(CreatineStore.self) private var store
    @State private var displayedMonth = Date()
    private let calendar = Calendar.current

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var dayCells: [[Date?]] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let monthStart = calendar.dateInterval(of: .month, for: displayedMonth)?.start
        else { return Array(repeating: Array(repeating: nil, count: 7), count: 6) }
        let leading = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<range.count {
            cells.append(calendar.date(byAdding: .day, value: offset, to: monthStart))
        }
        while cells.count < 42 { cells.append(nil) }
        return stride(from: 0, to: 42, by: 7).map { start in
            Array(cells[start..<start+7])
        }
    }

    private var weekdayLabels: [String] {
        let s = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(s[first...]) + Array(s[..<first])
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                }
                Spacer()
                Text(monthTitle).font(.headline)
                Spacer()
                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                }
            }

            HStack {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdayLabels[i])
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: 6) {
                ForEach(0..<6, id: \.self) { week in
                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { day in
                            CalendarDayCellView(date: dayCells[week][day])
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func changeMonth(_ delta: Int) {
        if let new = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            withAnimation { displayedMonth = new }
        }
    }
}

/// Einzelner Tag im Monats-Kalender. Bewusst MINI: 32pt-Kreis,
/// lineLimit(1), minimumScaleFactor(0.7) → garantiert passt in
/// jede Parent-Spalte (kein Overflow mehr möglich).
struct CalendarDayCellView: View {
    @Environment(CreatineStore.self) private var store
    let date: Date?

    var body: some View {
        ZStack {
            if let date {
                let taken = store.isTaken(date)
                let skipped = store.isSkipped(date)
                let frozen = store.isFrozen(date)
                let isToday = Calendar.current.isDateInToday(date)
                let dayNum = Calendar.current.component(.day, from: date)

                Circle()
                    .fill(fillColor(taken: taken, skipped: skipped, frozen: frozen))
                    .frame(width: 32, height: 32)
                Text("\(dayNum)")
                    .font(.footnote.weight(taken ? .bold : .regular))
                    .foregroundStyle(taken ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if isToday {
                    Circle()
                        .strokeBorder(Color.accentColor, lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                }
            }
        }
        .frame(height: 36)
    }

    private func fillColor(taken: Bool, skipped: Bool, frozen: Bool) -> Color {
        if taken { return .green }
        if frozen { return .cyan }
        if skipped { return .orange }
        return Color(.tertiarySystemFill)
    }
}
