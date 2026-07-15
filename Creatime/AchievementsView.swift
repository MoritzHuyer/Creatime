import SwiftUI

// MARK: - Erfolge-Tab (v13 — Airy)
//
// Layout-Philosophie: keine Glass-Cards. Hero-Ring zentriert oben,
// NextAchievement als Luftband, Badges im 3-Spalten-Grid mit
// weißem background + sehr subtle Border.
//
// Reihenfolge:
//   1. Big Hero-Ring (200pt) + "2 von 5" + Status-Text
//   2. Nächster-Erfolg Card (subtle Pill)
//   3. "Alle Badges" 3-Spalten-Grid (subtle Tile pro Badge)

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

    private var statusLine: String {
        let unlocked = unlockedAchievements.count
        let total = Achievement.all.count
        if unlocked == 0 { return "Noch keine freigeschaltet — fang mit Tag 1 an." }
        if unlocked == total { return "Wow, alle Erfolge freigeschaltet! 🏆" }
        return "Weiter so — du bist auf dem Weg."
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DynamicBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        bigHeroRing
                        Text("Deine Errungenschaften")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(statusLine)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)

                        if let next = nextAchievement, next.days > 0 {
                            NextAchievementPill(
                                emoji: next.emoji,
                                title: next.title,
                                progress: store.bestStreak,
                                goal: next.days,
                                tint: themeManager.theme.primary
                            )
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Alle Badges", systemImage: "trophy.fill")
                                .font(.subheadline.bold())
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(unlockedAchievements) { a in
                                    BadgeTile(achievement: a, unlocked: true)
                                        .onTapGesture { selectedAchievement = a }
                                }
                                ForEach(lockedAchievements) { a in
                                    BadgeTile(achievement: a, unlocked: false)
                                        .onTapGesture { selectedAchievement = a }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
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
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
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

    private var bigHeroRing: some View {
        let unlocked = unlockedAchievements.count
        let total = max(1, Achievement.all.count)
        let pct = Double(unlocked) / Double(total)
        return ZStack {
            Circle()
                .stroke(themeManager.theme.primary.opacity(0.18), lineWidth: 14)
                .frame(width: 200, height: 200)
            Circle()
                .trim(from: 0, to: pct)
                .stroke(
                    LinearGradient(
                        colors: [themeManager.theme.primary, themeManager.theme.primary.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 200, height: 200)
                .animation(.snappy, value: unlocked)
            VStack(spacing: 0) {
                Text("\(unlocked)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager.theme.primary)
                    .contentTransition(.numericText())
                Text("von \(total)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
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
}

// MARK: - NextAchievementPill (subtle pill with progress)

struct NextAchievementPill: View {
    let emoji: String
    let title: String
    let progress: Int
    let goal: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 32))
            VStack(alignment: .leading, spacing: 4) {
                Text("Nächster Erfolg: \(title)")
                    .font(.subheadline.weight(.semibold))
                ProgressView(value: Double(progress), total: Double(max(1, goal)))
                    .tint(tint)
                    .frame(maxWidth: 200)
            }
            Spacer(minLength: 0)
            Text("\(progress)/\(goal)")
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundStyle(tint)
                .background(tint.opacity(0.15), in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
        }
    }
}

// MARK: - BadgeTile (subtle tile, NOT glass)

struct BadgeTile: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(achievement.emoji)
                .font(.system(size: 32))
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
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.black.opacity(unlocked ? 0.06 : 0.04), lineWidth: 0.5)
        }
        .accessibilityLabel("\(achievement.title), \(unlocked ? "freigeschaltet" : "gesperrt — \(achievement.subtitle)")")
    }
}

// MARK: - Achievement Detail Sheet

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

// MARK: - "Neu freigeschaltet!"-Toast (subtle, kept for celebrations)

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
