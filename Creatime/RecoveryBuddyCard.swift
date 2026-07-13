import SwiftUI

// MARK: - Streak-Recovery-Buddy (v7 — pink Glass-Card)
//
// Wenn die User-Streak gebrochen wurde UND die alte Best-Streak jemals
// >= 7 Tage war, zeigen wir einen motivierenden Hinweis-Block im
// Heute-Tab. Pink Glass-Card mit Icon, Header, einem motivierenden
// Spruch und einem großen Button „Heute Kreatin nehmen".
//
//  1. Header (pink Heart-Icon) + „Streak-Neustart willkommen"
//  2. Best-Streak-Anzeige
//  3. Motivierender Spruch (rotiert täglich)
//  4. „Heute Kreatin nehmen" Button

struct RecoveryBuddyCard: View {
    @Environment(CreatineStore.self) private var store

    /// Action-Closure: in der Regel `RecoveryBuddyCard(action: markAsTaken)`.
    var action: () -> Void = {}

    @AppStorage("recoveryCardDismissedForDay") private var dismissedForDay: String = ""
    private let todayKey = DayKey.today

    /// Motivationssprüche. „__N__" wird zur Streak-Zahl ersetzt.
    private let motivationalQuotes = [
        "Jeder Neustart ist ein neuer Anfang.",
        "Die längste Reise beginnt mit einem einzigen Schritt.",
        "Du warst schon __N__ Tage am Ball — das bleibt in dir.",
        "Eine Pause ist kein Scheitern, sondern Atemholen.",
        "Zurückkommen ist die stärkste Übung.",
    ]

    private var shouldShow: Bool {
        guard store.bestStreak >= 7 else { return false }
        guard store.currentStreak <= 1 else { return false }
        guard !store.takenToday else { return false }
        guard !store.skippedToday && !store.frozenToday else { return false }
        return dismissedForDay != todayKey
    }

    private var quote: String {
        let burst = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let q = motivationalQuotes[burst % motivationalQuotes.count]
        return q.replacingOccurrences(of: "__N__", with: "\(store.bestStreak)")
    }

    var body: some View {
        if shouldShow {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title2)
                        .foregroundStyle(.pink)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Streak-Neustart willkommen")
                            .font(.headline)
                        Text("Beste Streak: \(store.bestStreak) Tage")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.pink.opacity(0.85))
                    }
                    Spacer(minLength: 0)
                    Button {
                        Haptics.tap()
                        dismissedForDay = todayKey
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Karte für heute weglassen")
                }

                Text(quote)
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    Haptics.tapMedium()
                    action()
                } label: {
                    Label("Heute Kreatin nehmen", systemImage: "checkmark.circle")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
            }
            .padding(16)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
