import SwiftUI

// MARK: - Erfolge-Tab (v16 — Claude Design Port)
//
// Layout matches Creatime.dc.html screen 1d:
//   1. PageTitle "Erfolge"
//   2. AchievementHero (9 unlocked, "von 24 Abzeichen freigeschaltet")
//   3. NextGoalCard (next milestone + progress bar)
//   4. BadgeGrid (3-column grid with 58pt circles)
//
// All state hooks (Environment CreatineStore + ThemeManager) preserved
// from v15.0.

struct AchievementsView: View {
    @Environment(CreatineStore.self) private var store

    @State private var confettiTrigger = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    private var unlocked: [Achievement] { Achievement.all.filter { isUnlocked($0) } }
    private var locked: [Achievement] { Achievement.all.filter { !isUnlocked($0) } }

    private func isUnlocked(_ a: Achievement) -> Bool {
        if a.days == 0 { return store.celebratedMilestones.contains(0) }
        return store.bestStreak >= a.days
    }

    private var next: Achievement? { locked.min(by: { $0.days < $1.days }) }

    var body: some View {
        ZStack {
            DynamicBackground()

            ScrollView {
                VStack(spacing: 12) {
                    PageTitle(text: "Erfolge").frame(maxWidth: .infinity, alignment: .leading).padding(.top, 24)

                    VStack(spacing: 4) {
                        Text("\(unlocked.count)")
                            .font(.ctAchievementHero)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("von \(Achievement.all.count) Abzeichen freigeschaltet")
                            .font(.ctSubheadline)
                            .foregroundStyle(Color.ctInkSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)

                    if let next, next.days > 0 {
                        NextGoalCard(
                            title: next.title,
                            remaining: max(0, next.days - store.bestStreak),
                            progress: store.bestStreak,
                            goal: next.days
                        )
                    }

                    BaseCard {
                        VStack(alignment: .leading, spacing: 12) {
                            // „Alle anzeigen" entfernt: Das Grid zeigt bereits
                            // alle Abzeichen — das Label sah aus wie ein Button,
                            // hatte aber keine Aktion (toter Link).
                            Text("Abzeichen").font(.ctCardTitle)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(unlocked, id: \.id) { a in
                                    BadgeView(icon: a.emoji, name: a.title, unlocked: true, tint: badgeTint(for: a))
                                        .accessibilityLabel("\(a.title) freigeschaltet")
                                }
                                ForEach(locked, id: \.id) { a in
                                    BadgeView(icon: a.emoji, name: a.title, unlocked: false, tint: badgeTint(for: a))
                                        .accessibilityLabel("\(a.title) gesperrt — ab \(a.days) Tagen")
                                }
                            }
                        }
                    }
                }
                .ctPagePadded()
                .padding(.bottom, 96)
            }

            ConfettiView(trigger: confettiTrigger)
        }
        .onChange(of: store.lastCelebratedMilestone) { _, new in
            guard let milestone = new else { return }
            Haptics.successHeavy()
            confettiTrigger = true
            Task {
                try? await Task.sleep(for: .milliseconds(80))
                confettiTrigger = false
                try? await Task.sleep(for: .seconds(4))
                store.acknowledgeLatestMilestone()
            }
        }
    }

    private func badgeTint(for a: Achievement) -> Color {
        switch a.days {
        case ..<7:    return .ctAccent
        case ..<30:   return .ctKreatin
        case ..<100:  return .ctWasser
        default:      return .ctSuccess
        }
    }
}

#Preview {
    AchievementsView()
        .environment(CreatineStore())
        .environment(ThemeManager.shared)
}
