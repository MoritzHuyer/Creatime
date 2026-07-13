import SwiftUI

// MARK: - Streak-Recovery-Buddy (Editorial — eingebettet, weicher)
//
// Wenn die User-Streak gebrochen wurde UND die alte Best-Streak jemals
// >= 7 Tage war, zeigen wir einen sanften Hinweis-Block im Heute-Tab.
// Jetzt im Editorial-Stil: weniger Pink-Aggression, weicherer
// Tertiary-Background, kleinere Headline. Wirkt eingebettet statt
// „neues Element".
//
//  1. Header (klein) + motivational Quote
//  2. Kurze Info zur Best-Streak
//  3. „Heute Kreatin nehmen" Button
//  4. X-Button zum Wegblenden

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
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title3)
                    .foregroundStyle(.pink.opacity(0.85))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Neustart willkommen")
                            .font(.subheadline.bold())
                        Spacer()
                        Button {
                            Haptics.tap()
                            dismissedForDay = todayKey
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Karte für heute weglassen")
                    }

                    Text(quote)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        Haptics.tapMedium()
                        action()
                    } label: {
                        Label("Heute Kreatin nehmen", systemImage: "checkmark.circle")
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink.opacity(0.85))
                    .padding(.top, 4)
                }
            }
            .padding(14)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
