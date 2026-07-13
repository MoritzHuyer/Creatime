import SwiftUI

// MARK: - Erfolge-Tab (v7 — Glass-Card-Stil)
//
// Layout-Philosophie: Hero-Ring + Next-Card + 3-Spalten-Badge-Grid.
//
// Reihenfolge (von oben nach unten):
//   1. Hero-Ring (110pt) + freigeschaltet / Gesamt Zahl + Status-Text
//   2. Next-Achievement-Card (Glass)
//   3. AchievementSection (3-Spalten-Grid mit Glass-Badges)

struct AchievementsView: View {
    @Environment(CreatineStore.self) private var store
    @Environment(ThemeManager.self) private var themeManager

    @State private var showSettings = false
    @State private var selectedAchievement: Achievement?

    @State private var confettiTrigger = false
    @State private var celebrationToast: Achievement?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    private var unlockedAchievements: [Achievement] {
        Achievement.all.filter { isUnlocked($0) }
    }

    private var lockedAchievements: [Achievement] {
        Achievement.all.filter { !isUnlocked($0) }
    }

    private func isUnlocked(_ a: Achievement) -> Bool {
        if a.days == 0 {
            return store.celebratedMilestones.contains(0)
        }
        return store.bestStreak >= a.days
    }

    private var nextAchievement: Achievement? {
        lockedAchievements.min(by: { $0.days < $1.days })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DynamicBackground()

                ScrollView {
                    VStack(spacing: 22) {
                        heroHeader

                        nextAchievementCard

                        AchievementSection(
                            unlocked: unlockedAchievements,
                            locked: lockedAchievements,
                            columns: columns,
                            onSelect: { selectedAchievement = $0 }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                }

                ConfettiView(trigger: confettiTrigger)

                if let toast = celebrationToast {
                    VStack {
                        Spacer()
                        CelebrationToast(achievement: toast) {
                            celebrationToast = nil
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Erfolge")
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
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(achievement: achievement, unlocked: isUnlocked(achievement))
                .presentationDetents([.medium])
        }
        .onChange(of: store.lastCelebratedMilestone) { _, newValue in
            guard let newly = newValue else { return }
            fireConfetti(for: newly)
        }
        .animation(.snappy, value: celebrationToast)
    }

    private func fireConfetti(for milestone: Int) {
        Haptics.successHeavy()
        confettiTrigger = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            confettiTrigger = false
        }
        let achieved = Achievement.all.first(where: { $0.days == milestone })
            ?? Achievement.onboardingStarter
        celebrationToast = achieved
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            celebrationToast = nil
            store.acknowledgeLatestMilestone()
        }
    }

    // MARK: - Hero-Ring (110pt)

    private var heroHeader: some View {
        let unlockedCount = unlockedAchievements.count
        let totalCount = Achievement.all.count
        let pct = Double(unlockedCount) / Double(max(1, totalCount))

        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.18), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(
                        LinearGradient(
                            colors: [themeManager.theme.primary, themeManager.theme.primary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.snappy, value: unlockedCount)
                VStack(spacing: 0) {
                    Text("\(unlockedCount)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(themeManager.theme.primary)
                        .contentTransition(.numericText())
                    Text("von \(totalCount)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 140, height: 140)
            .padding(8)

            Text(unlockedCount == 0
                 ? "Noch keine freigeschaltet — fang mit Tag 1 an."
                 : unlockedCount == totalCount
                     ? "Wow, alle Erfolge freigeschaltet! 🏆"
                     : "Weiter so — du bist auf dem Weg.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Next-Achievement-Card

    @ViewBuilder
    private var nextAchievementCard: some View {
        if let next = nextAchievement {
            let remaining: Int = {
                if next.days == 0 { return 0 }
                return max(0, next.days - store.bestStreak)
            }()

            HStack(alignment: .center, spacing: 14) {
                Text(next.emoji)
                    .font(.system(size: 44))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Als Nächstes")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(next.title)
                        .font(.headline)
                    Text(next.days == 0
                         ? "Markiere deinen ersten Tag, um zu starten."
                         : "Noch \(remaining) Tage Streak nötig.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if next.days > 0 {
                    Text("\(store.bestStreak)/\(next.days)")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundStyle(themeManager.theme.primary)
                        .background(themeManager.theme.primary.opacity(0.15), in: Capsule())
                }
            }
            .padding(16)
            .liquidGlassCard()
        }
    }
}

// MARK: - AchievementSection (3-Spalten-Grid mit Glass-Badges)

struct AchievementSection: View {
    let unlocked: [Achievement]
    let locked: [Achievement]
    let columns: [GridItem]
    let onSelect: (Achievement) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Alle Errungenschaften", systemImage: "trophy.fill")
                .font(.subheadline.bold())

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(unlocked) { a in
                    AchievementBadge(achievement: a, unlocked: true)
                        .onTapGesture { onSelect(a) }
                }
                ForEach(locked) { a in
                    AchievementBadge(achievement: a, unlocked: false)
                        .onTapGesture { onSelect(a) }
                }
            }
        }
    }
}

// MARK: - AchievementBadge (Glass-Card-Style)

struct AchievementBadge: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(achievement.emoji)
                .font(.system(size: 36))
                .grayscale(unlocked ? 0 : 1)
                .opacity(unlocked ? 1 : 0.45)
            Text(achievement.title)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(unlocked ? .primary : .secondary)
            Text(unlocked
                 ? "Geschafft!"
                 : (achievement.days == 0 ? "Onboarding" : "ab \(achievement.days) Tagen"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .liquidGlassCard()
        .accessibilityLabel("\(achievement.title), \(unlocked ? "freigeschaltet" : "gesperrt — \(achievement.subtitle)")")
    }
}

// MARK: - Detail-Sheet für ein Badge

private struct AchievementDetailSheet: View {
    let achievement: Achievement
    let unlocked: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Text(achievement.emoji)
                .font(.system(size: 64))
                .grayscale(unlocked ? 0 : 1)
                .opacity(unlocked ? 1 : 0.45)
            Text(achievement.title)
                .font(.title2.bold())
            Text(achievement.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            HStack(spacing: 8) {
                Image(systemName: unlocked ? "checkmark.seal.fill" : "lock.fill")
                    .foregroundStyle(unlocked ? .green : .secondary)
                Text(unlocked
                     ? "Freigeschaltet"
                     : (achievement.days == 0 ? "Onboarding" : "ab \(achievement.days) Tagen"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(unlocked ? .green : .secondary)
            }
            .padding(.top, 4)
            Spacer()
            Button("Schließen") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - "Neu freigeschaltet!"-Toast

struct CelebrationToast: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(achievement.emoji)
                .font(.system(size: 30))
            VStack(alignment: .leading, spacing: 2) {
                Text("Neu freigeschaltet!")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Text(achievement.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
            Button {
                Haptics.tap()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Color.accentColor, Color.accentColor.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .shadow(color: Color.accentColor.opacity(0.35), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
        .accessibilityLabel("\(achievement.title) neu freigeschaltet")
    }
}

#Preview {
    AchievementsView()
        .environment(CreatineStore())
        .environment(ThemeManager.shared)
        .padding()
}
