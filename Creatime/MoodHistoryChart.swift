import SwiftUI
import Charts

// MARK: - Mood-History-Chart (v7 — bleibt unverändert)
//
// Mini-7-Bar-Chart der letzten 7 Tage Stimmung. Eingebettet in
// HistoryView zwischen StatsGrid und Streak-Share-Banner. Nutzt ein
// eigenes BarMark-Chart weil wir diskrete Stimmungs-Werte als
// numerische Scores abbilden.

struct MoodHistoryChart: View {
    @Environment(CreatineStore.self) private var store

    /// Mapping emoji -> numerischer Score für die Y-Achse.
    static let moodScores: [String: Double] = [
        "neutral":  0,
        "good":     1,
        "great":    2,
        "stressed": -1,
        "tired":    -2,
    ]

    private static let moodLabels: [String: String] = [
        "neutral":  "😐",
        "good":     "😊",
        "great":    "🤩",
        "stressed": "🥵",
        "tired":    "😴",
    ]

    private var data: [BarEntry] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let key = DayKey.string(for: date)
            let moodKey = store.moodByDay[key] ?? ""
            let score = Self.moodScores[moodKey] ?? 0
            return BarEntry(date: date, score: score, hasEntry: !moodKey.isEmpty)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Stimmung · 7 Tage", systemImage: "face.smiling")
                .font(.headline)
                .foregroundStyle(.orange)

            Chart {
                ForEach(data) { entry in
                    BarMark(
                        x: .value("Tag", entry.date, unit: .day),
                        y: .value("Score", entry.score)
                    )
                    .foregroundStyle(barColor(score: entry.score, hasEntry: entry.hasEntry))
                    .cornerRadius(3)
                }
            }
            .chartYScale(domain: -2...2)
            .chartYAxis {
                AxisMarks(position: .leading, values: [-2, -1, 0, 1, 2]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text(emojiFor(score: v))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.weekday(.narrow))
                        }
                    }
                }
            }
            .frame(height: 120)
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func emojiFor(score: Int) -> String {
        Self.emoji(for: score)
    }

    static func emoji(for score: Int) -> String {
        switch score {
        case -2: return "😴"
        case -1: return "🥵"
        case  0: return "😐"
        case  1: return "😊"
        case  2: return "🤩"
        default: return "·"
        }
    }

    static func moodScore(for moodKey: String) -> Double? {
        moodScores[moodKey]
    }

    private func barColor(score: Double, hasEntry: Bool) -> Color {
        if !hasEntry { return .gray.opacity(0.15) }
        if score >  0 { return .mint }
        if score <  0 { return .orange }
        return .gray.opacity(0.5)
    }

    private struct BarEntry: Identifiable {
        let date: Date
        let score: Double
        let hasEntry: Bool

        var id: Date { date }
    }
}
