import SwiftUI
import Charts

// MARK: - Datenstrukturen für die Charts

struct WaterDay: Identifiable {
    // Stabile ID aus dem Datum — würde `UUID()` benutzt, würde Charts bei
    // jedem Re-Render die komplette Datenmenge neu zeichnen.
    var id: String { DayKey.string(for: date) }
    let date: Date
    let ml: Int
}

struct CreatineDay: Identifiable {
    var id: String { DayKey.string(for: date) }
    let date: Date
    let taken: Bool
}

// MARK: - Wasser-Verlauf (letzte 30 Tage)

/// Linien- oder Balkendiagramm der Wassermenge der letzten 30 Tage.
/// Eine horizontale Linie auf Höhe des Tagesziels zeigt, wann das Ziel erreicht war.
struct WaterHistoryChart: View {

    @Environment(WaterStore.self) private var water
    let days: Int = 30

    private var data: [WaterDay] {
        let calendar = Calendar.current
        return (0..<days).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            return WaterDay(date: date, ml: water.amount(on: date))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wasser (30 Tage)")
                .font(.headline)

            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Tag", item.date, unit: .day),
                        y: .value("ml", item.ml)
                    )
                    .foregroundStyle(item.ml >= water.dailyGoal ? .green : .blue)
                    .cornerRadius(3)
                }

                // v14.4: Annotation KOMPLETT entfernt — nicht der allerletzte
                // Versuch war's wert: 4 bisherige Versuche haben nicht
                // gegriffen, also räumen wir die wahrscheinlichste
                // Quelle strukturell weg. Die gestrichelte Linie selbst
                // kommuniziert das Ziel visuell; ein „Ziel"-Text-Label
                // war nice-to-have aber kritisch als Overflow-Quelle.
                RuleMark(y: .value("Ziel", water.dailyGoal))
                    .foregroundStyle(.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let ml = value.as(Int.self) {
                            Text("\(ml / 1000)L")
                        }
                    }
                }
            }
            .chartXAxis {
                // X-Achse alle 14 Tage ein Label, im Format "TT.MM" — z.B.
                // "14.07" für 14. Juli. Bewusst NICHT `month(.narrow)`,
                // weil das nur einen Buchstaben pro Monat liefert und
                // mehrdeutig wirkt (J=Juli/Juni/Januar).
                AxisMarks(values: .stride(by: .day, count: 14)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.day().month(.twoDigits))
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color.clear)
    }
}

// MARK: - Kreatin-Verlauf (letzte 30 Tage)

/// Schmale Balken pro Tag: grün wenn genommen, grau wenn nicht.
struct CreatineHistoryChart: View {

    @Environment(CreatineStore.self) private var store
    let days: Int = 30

    private var data: [CreatineDay] {
        let calendar = Calendar.current
        return (0..<days).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            return CreatineDay(date: date, taken: store.isTaken(date))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kreatin (30 Tage)")
                .font(.headline)

            Chart(data) { item in
                BarMark(
                    x: .value("Tag", item.date, unit: .day),
                    y: .value("Status", item.taken ? 1 : 0)
                )
                .foregroundStyle(item.taken ? .green : .gray.opacity(0.25))
                .cornerRadius(2)
            }
            .chartYScale(domain: 0...1)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 1]) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self), v == 1 {
                            Text("✓")
                        }
                    }
                }
            }
            .chartXAxis {
                // „dd.MM" + stride alle 14 Tage — vermeidet das „J/M/A"-Problem.
                AxisMarks(values: .stride(by: .day, count: 14)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.day().month(.twoDigits))
                        }
                    }
                }
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color.clear)
    }
}
