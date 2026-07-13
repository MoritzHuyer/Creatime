import SwiftUI

// MARK: - ActivityRingDayCell
//
// Ersetzt die alte DayCell im MonthCalendar. Pro Tag werden 3
// konzentrische ActivityRinge gezeichnet (angelehnt an Apple's
// Activity-App Konzept):
//
//   • Äußerer Ring (orange) — Creatine-Streak-Status (taken / skipped / frozen / leer)
//   • Mittlerer Ring (cyan) — Wasserziel-Progress (0.0–1.0)
//   • Innerer Ring (pink) — Foto-Streak-Status (dieses Wochen-Foto ja/nein)
//
// Die Ringe sind klein (28pt) und sollen visuell AND der reinen
// Tag-Nummer stehen. Auch `isToday` und `isFuture` werden weiterhin
// gerendert.

struct ActivityRingDayCell: View {
    @Environment(CreatineStore.self) private var store
    @Environment(WaterStore.self) private var water
    @Environment(PhotoStreakStore.self) private var photoStore

    let day: Date
    @State private var showActionConfirm = false

    var body: some View {
        let taken = store.isTaken(day)
        let skipped = store.isSkipped(day)
        let frozen = store.isFrozen(day)
        let isToday = Calendar.current.isDateInToday(day)
        let isFuture = day > Date() && !isToday

        let waterPct = min(1.0,
            Double(water.amount(on: day)) / Double(water.dailyGoal))
        let hasPhotoThisWeek: Bool = {
            // Wir prüfen ob irgendein Foto in derselben ISO-Woche wie der
            // Tag liegt. Wäre overkill eine echte Funktion auf dem Store
            // zu definieren — Inline mit WeekKey.
            let weeks = WeekKey.key(for: day)
            return photoStore.entries.contains { $0.week == weeks }
        }()
        let dayNumber = Calendar.current.component(.day, from: day)

        ZStack {
            // Drei Ringe: außen Creatine, mitte Wasser, innen Foto.
            ZStack {
                if !isFuture {
                    RingShape(progress: takenProgress(taken, skipped, frozen), tint: ringColor(taken, skipped, frozen))
                        .frame(width: 34, height: 34)
                    RingShape(progress: waterPct, tint: .cyan)
                        .frame(width: 26, height: 26)
                    RingShape(progress: hasPhotoThisWeek ? 1.0 : 0.0, tint: .pink)
                        .frame(width: 18, height: 18)
                }
            }

            // Tageszahl im inneren Ring
            Text("\(dayNumber)")
                .font(.callout)
                .fontWeight(taken ? .bold : .regular)
                .foregroundStyle(textColor(taken: taken, isFuture: isFuture))
                .frame(width: 14, height: 14)

            // Heute-Indikator
            if isToday {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 2)
                    .frame(width: 36, height: 36)
            }
        }
        .frame(width: 36, height: 36)
        .contentShape(Rectangle())
        .onTapGesture {
            // Nur vergangene skipped/frozen Tage sind interaktiv.
            if (skipped || frozen) && !isFuture {
                showActionConfirm = true
            }
        }
        .confirmationDialog(
            frozen ? "Eis-Tag widerrufen?" : "Pause widerrufen?",
            isPresented: $showActionConfirm,
            titleVisibility: .visible
        ) {
            Button(frozen ? "Eis-Tag entfernen" : "Pause rückgängig machen") {
                if frozen {
                    store.unfreeze(date: day)
                } else {
                    store.unskip(date: day)
                }
                Haptics.tap()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text(frozen
                 ? "Der Tag wird wieder als „offen“ gezählt (Freeze-Budget steigt nicht)."
                 : "Der Tag wird wieder als „nicht genommen“ gezählt.")
        }
        .accessibilityLabel(dayAccessibilityLabel(
            day: day,
            taken: taken,
            skipped: skipped,
            frozen: frozen,
            waterPct: waterPct,
            hasPhoto: hasPhotoThisWeek
        ))
    }

    private func takenProgress(_ taken: Bool, _ skipped: Bool, _ frozen: Bool) -> Double {
        if taken { return 1.0 }
        if skipped || frozen { return 0.5 }   // „halb" — Streak-Schutz
        return 0.15                            // leichter grauer Indikator-Bogen
    }

    private func ringColor(_ taken: Bool, _ skipped: Bool, _ frozen: Bool) -> Color {
        if taken { return .green }
        if frozen { return .cyan }
        if skipped { return .orange }
        return .gray.opacity(0.4)
    }

    private func textColor(taken: Bool, isFuture: Bool) -> Color {
        if taken { return .white }
        return isFuture ? Color(.tertiaryLabel) : Color.primary
    }

    private func dayAccessibilityLabel(day: Date, taken: Bool, skipped: Bool, frozen: Bool, waterPct: Double, hasPhoto: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMMM"
        var parts: [String] = [formatter.string(from: day)]
        if taken { parts.append("Kreatin genommen") }
        else if skipped { parts.append("Pausiert") }
        else if frozen { parts.append("\u{2744} Eis-Tag") }
        if waterPct >= 0.99 { parts.append("Wasserziel erreicht") }
        else if waterPct > 0.2 { parts.append("Wasser \(Int(waterPct * 100))%") }
        if hasPhoto { parts.append("Foto vorhanden") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - RingShape
//
// Generischer Ring — konzentrischer Kreis mit Trim-Progress. Innen
// ausgespart, außen gefüllt. Wird mit einem `.frame(...)` skaliert.

struct RingShape: View {
    var progress: Double     // 0.0 ... 1.0
    var tint: Color
    var lineWidth: CGFloat = 2.5

    var body: some View {
        ZStack {
            // Hintergrund-Ring (sehr blass)
            Circle()
                .stroke(tint.opacity(0.18), lineWidth: lineWidth)
            // Progress-Ring
            Circle()
                .trim(from: 0, to: max(0.001, min(1.0, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
