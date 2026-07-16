import SwiftUI
import UIKit

// ============================================================================
// Creatime Components Library (v16 — Claude Design Port)
//
// All v16 UI primitives extracted from Creatime.dc.html (screens 1a-1f).
// These components consume DesignTokens.swift for visual constants and
// do not change any state. State-bearing screens (TodayView,
// HistoryView, AchievementsView, Settings, Onboarding) compose these.
//
// IMPORTANT: Every primitive here is ENVIRONMENT-AWARE — colourScheme
// drives light/dark surfaces. Animation timing is wired to
// Animation.ctRingFill / ctBarFill / ctTap from DesignTokens.
// ============================================================================

// MARK: - BaseCard
// Universal card surface. 24 pt radius + 18 pt padding (EdgeInsets.ctCard)
// + subtle shadow light or hairline border dark.

struct BaseCard<Content: View>: View {
    let radius: CGFloat
    let content: Content

    @Environment(\.colorScheme) private var scheme

    init(radius: CGFloat = CTLayout.cardRadius, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        let shadow = scheme == .dark ? CTShadow.cardDark : CTShadow.cardLight
        let surface = scheme == .dark ? Color.ctCardSurfaceDark : Color.ctCardSurface
        let border = scheme == .dark ? Color.ctCardBorderDark : Color.ctCardBorderLight
        content
            .padding(EdgeInsets.ctCard)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(surface))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(border, lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Headline helpers

struct DateSubtitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.ctSectionLabel).tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(Color.ctInkSecondary)
    }
}

struct PageTitle: View {
    let text: String
    var body: some View {
        Text(text).font(.ctPageTitle)
    }
}

// MARK: - HeroStreakBlock (Today header)
// "Mittwoch, 16. Juli" → "Heute" → 72-pt streak → pills row.

struct HeroStreakBlock: View {
    let dateText: String
    let title: String
    let streakDays: Int
    let securedToday: Bool
    let freezesRemaining: Int
    let bestStreak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                DateSubtitle(text: dateText)
                PageTitle(text: title)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.ctStreakFlame)
                Text("\(streakDays)")
                    .font(.ctStreakHero).tracking(-2.5)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("Tage am Stück")
                    .font(.ctSubheadline)
                    .foregroundStyle(Color.ctInkSecondary)
                HStack(spacing: 8) {
                    if securedToday {
                        CTChipSurface("Heute gesichert", tint: .success, symbol: "checkmark")
                    }
                    CTChipSurface("\(freezesRemaining) Freeze übrig", tint: .freeze, symbol: "snowflake")
                    if bestStreak > 0 {
                        CTChipSurface("Best: \(bestStreak)", tint: .neutral)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
}

// MARK: - CheckRingCard
// Kreatin card — 92×92 ring + Kreatin label + tap to mark taken.

struct CheckRingCard: View {
    let isTaken: Bool
    let action: () -> Void

    var body: some View {
        BaseCard {
            HStack(alignment: .center, spacing: 18) {
                Button(action: action) {
                    ZStack {
                        Circle().stroke(Color.ctInkTertiary, lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: max(0.001, isTaken ? 1.0 : 0))
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "#FFC489"), Color.ctAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.ctRingFill, value: isTaken)
                        if isTaken {
                            Image(systemName: "checkmark")
                                .font(.system(size: 34, weight: .heavy))
                                .foregroundStyle(Color.ctAccent)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Image(systemName: "pills.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(Color.ctInkTertiary)
                                .transition(.opacity)
                        }
                    }
                    .frame(width: 92, height: 92)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Kreatin")
                        .font(.ctSectionLabel).tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.ctKreatin)
                    Text("5 g Monohydrat")
                        .font(.ctCardTitle)
                    Text(isTaken ? "Heute erledigt" : "Noch nicht genommen")
                        .font(.ctSubheadline)
                        .foregroundStyle(Color.ctInkSecondary)
                    Text("Ring tippen zum Abhaken")
                        .font(.caption)
                        .foregroundStyle(Color.ctInkTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - WaterCard
// Wasser card — label + 44-pt amount + progress bar + − / + buttons.

struct WaterCard: View {
    let amount: Int
    let goal: Int
    let hasHealthSync: Bool
    let onAdd: () -> Void
    let onSubtract: () -> Void
    let step: Int

    private var pct: Double { guard goal > 0 else { return 0 }; return min(1.0, Double(amount) / Double(goal)) }

    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "drop.fill").font(.system(size: 14)).foregroundStyle(Color.ctWasser)
                    Text("Wasser")
                        .font(.ctSectionLabel).tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.ctWasser)
                    Spacer()
                    if hasHealthSync {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill").font(.system(size: 10)).foregroundStyle(.pink)
                            Text("Health-Sync").font(.ctChipLabel)
                        }
                        .foregroundStyle(Color.ctInkSecondary)
                        .padding(.horizontal, 9).padding(.vertical, 3)
                        .background(Color.ctInkTertiary.opacity(0.5), in: Capsule())
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(amount)")
                        .font(.ctWaterHero).tracking(-1.2)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("/ \(goal) ml")
                        .font(.ctSubheadline)
                        .foregroundStyle(Color.ctInkSecondary)
                    Spacer()
                }

                WasserBar(progress: pct).frame(height: 10)

                HStack(spacing: 10) {
                    Button(action: onAdd) {
                        Text("+ \(step) ml")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.ctWasserBright)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.ctWasserSurface, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    Button(action: onSubtract) {
                        Image(systemName: "minus")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.ctInkSecondary)
                            .frame(width: 50, height: 50)
                            .background(Color.ctInkTertiary.opacity(0.5), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(amount == 0)
                }
            }
        }
    }
}

struct WasserBar: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.ctInkTertiary.opacity(0.5))
                Capsule()
                    .fill(LinearGradient(colors: [Color.ctWasserBright, Color.ctWasser], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(8, geo.size.width * CGFloat(progress)))
                    .animation(.ctBarFill, value: progress)
            }
        }
    }
}

// MARK: - CalendarCard
// HTML 1c — month header + 7-column grid + legend.

struct CalendarCard: View {
    @Environment(CreatineStore.self) private var store
    @State private var displayedMonth = Date()
    private let calendar = Calendar.current

    private var monthTitle: String { displayedMonth.formatted(.dateTime.month(.wide).year()) }

    private var dayCells: [[CalendarDay?]] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let start = calendar.dateInterval(of: .month, for: displayedMonth)?.start else {
            return Array(repeating: Array(repeating: nil, count: 7), count: 6)
        }
        let leading = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        var cells: [CalendarDay?] = Array(repeating: nil, count: leading)
        for offset in 0..<range.count {
            if let d = calendar.date(byAdding: .day, value: offset, to: start) {
                cells.append(CalendarDay(
                    date: d,
                    isTaken: store.isTaken(d),
                    isSkipped: store.isSkipped(d),
                    isFrozen: store.isFrozen(d),
                    isToday: calendar.isDateInToday(d)
                ))
            }
        }
        while cells.count < 42 { cells.append(nil) }
        return stride(from: 0, to: 42, by: 7).map { startIdx in Array(cells[startIdx..<startIdx+7]) }
    }

    private var weekdayLabels: [String] {
        let s = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(s[first...]) + Array(s[..<first])
    }

    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button { changeMonth(-1) } label: { Image(systemName: "chevron.left").font(.subheadline.weight(.semibold)) }
                        .buttonStyle(.plain).foregroundStyle(.primary)
                    Spacer()
                    Text(monthTitle).font(.ctCardTitle)
                    Spacer()
                    Button { changeMonth(1) } label: { Image(systemName: "chevron.right").font(.subheadline.weight(.semibold)) }
                        .buttonStyle(.plain).foregroundStyle(.primary)
                }

                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { i in
                        Text(weekdayLabels[i])
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.ctInkTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }

                VStack(spacing: 6) {
                    ForEach(0..<6, id: \.self) { week in
                        HStack(spacing: 6) {
                            ForEach(0..<7, id: \.self) { day in
                                CalendarDayCell(day: dayCells[week][day])
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }

                HStack(spacing: 16) {
                    LegendDot(color: .ctAccent, label: "Voll")
                    LegendDot(color: .ctAccent.opacity(0.25), label: "Teilweise")
                    LegendDot(color: .ctKreatinDeep.opacity(0.4), label: "Freeze")
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
    }

    private func changeMonth(_ delta: Int) {
        if let new = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            withAnimation(.snappy) { displayedMonth = new }
        }
    }
}

struct CalendarDay: Hashable {
    let date: Date
    let isTaken: Bool
    let isSkipped: Bool
    let isFrozen: Bool
    let isToday: Bool
}

struct CalendarDayCell: View {
    let day: CalendarDay?
    var body: some View {
        if let day {
            ZStack {
                Circle()
                    .fill(fillColor(taken: day.isTaken, skipped: day.isSkipped, frozen: day.isFrozen))
                    .frame(width: CTLayout.calendarCellSize, height: CTLayout.calendarCellSize)
                Text("\(Calendar.current.component(.day, from: day.date))")
                    .font(.subheadline.weight(day.isTaken ? .bold : .regular))
                    .foregroundStyle(day.isTaken ? .white : .primary)
                if day.isToday {
                    Circle()
                        .strokeBorder(Color.ctAccent, lineWidth: 1.5)
                        .frame(width: CTLayout.calendarTodayRingSize, height: CTLayout.calendarTodayRingSize)
                }
            }
            .frame(height: CTLayout.calendarTodayRingSize)
        } else {
            Color.clear.frame(height: CTLayout.calendarTodayRingSize)
        }
    }
    private func fillColor(taken: Bool, skipped: Bool, frozen: Bool) -> Color {
        if taken { return .ctAccent }
        if frozen { return .ctKreatinDeep.opacity(0.4) }
        if skipped { return .ctAccent.opacity(0.25) }
        return Color.ctInkTertiary.opacity(0.5)
    }
}

struct LegendDot: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(label).font(.caption).foregroundStyle(Color.ctInkSecondary)
        }
    }
}

// MARK: - BuddyBattleCard

struct BuddyBattleCard: View {
    @Environment(CreatineStore.self) private var store

    private var maxStreak: Int { max(1, store.bestStreak) }

    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Buddy-Battle").font(.ctCardTitle)
                    Spacer()
                    Text("Einladen").font(.ctSubheadline.weight(.semibold)).foregroundStyle(Color.ctAccent)
                }
                Text("Noch \(max(0, maxStreak - store.currentStreak)) Tage bis Platz 1")
                    .font(.caption).foregroundStyle(Color.ctInkSecondary)

                VStack(spacing: 10) {
                    BuddyRow(name: "Du", initials: "DU", streak: store.currentStreak,
                             max: maxStreak, badge: "🔥 dabei", isSelf: true, barColor: .ctAccent)
                    BuddyRow(name: "Anna", initials: "AN", streak: max(2, store.bestStreak - 1),
                             max: maxStreak, badge: nil, isSelf: false, barColor: .ctKreatin)
                    BuddyRow(name: "Luis", initials: "LU", streak: max(0, store.currentStreak - 3),
                             max: maxStreak, badge: nil, isSelf: false, barColor: .ctWasser)
                }
            }
        }
    }
}

struct BuddyRow: View {
    let name: String
    let initials: String
    let streak: Int
    let max: Int
    let badge: String?
    let isSelf: Bool
    let barColor: Color

    private var pct: Double { guard max > 0 else { return 0 }; return min(1.0, Double(streak) / Double(max)) }
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.ctAccent)
                Text(initials).font(.caption.weight(.bold)).foregroundStyle(.white)
            }
            .frame(width: CTLayout.buddyAvatarSize, height: CTLayout.buddyAvatarSize)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(name).font(.ctSubheadline.weight(isSelf ? .bold : .semibold))
                    if let badge { Text(badge).font(.caption.weight(.semibold)).foregroundStyle(Color.ctAccent) }
                    Spacer()
                    Text("\(streak)").font(.ctSubheadline.weight(.bold))
                    Text(" Tage").font(.caption.weight(.medium)).foregroundStyle(Color.ctInkSecondary)
                }
                Capsule().fill(Color.ctInkTertiary.opacity(0.5)).frame(height: 6)
                    .overlay(GeometryReader { geo in
                        Capsule().fill(barColor)
                            .frame(width: Swift.max(0, geo.size.width * CGFloat(pct)))
                    })
            }
        }
    }
}

// MARK: - PhotoStripCard

struct PhotoStripCard: View {
    let recentPhotos: [(label: String, key: String)]

    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Foto-Streak").font(.ctCardTitle)
                    Text("Dein visuelles Tagebuch — 1 Foto pro Tag")
                        .font(.caption).foregroundStyle(Color.ctInkSecondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // Heute CTA tile
                        VStack(spacing: 4) {
                            Image(systemName: "plus").font(.system(size: 22, weight: .semibold)).foregroundStyle(Color.ctAccent)
                            Text("Heute").font(.ctChipLabel).tracking(0.4).foregroundStyle(Color.ctAccent)
                        }
                        .frame(width: 74, height: 92)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .foregroundStyle(Color.ctAccent.opacity(0.5)))
                        .background(Color.ctAccent.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))

                        ForEach(recentPhotos, id: \.key) { photo in
                            PhotoTile(label: photo.label)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }
}

struct PhotoTile: View {
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "photo")
                .font(.system(size: 20)).foregroundStyle(Color.ctInkSecondary.opacity(0.7))
            Text(label).font(.ctChipLabel).tracking(0.4)
                .foregroundStyle(Color.ctInkSecondary.opacity(0.7))
        }
        .frame(width: 74, height: 92)
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.35)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

// MARK: - NextGoalCard (Achievements)

struct NextGoalCard: View {
    let title: String
    let remaining: Int
    let progress: Int
    let goal: Int

    private var pct: Double { guard goal > 0 else { return 0 }; return min(1.0, Double(progress) / Double(goal)) }
    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Nächstes Ziel").font(.ctCardTitle)
                    Spacer()
                    Text("\(progress) / \(goal)").font(.ctSubheadline).foregroundStyle(Color.ctInkSecondary)
                }
                Text("\(title) — noch \(remaining) Tag\(remaining == 1 ? "" : "e")")
                    .font(.ctSubheadline).foregroundStyle(Color.ctInkSecondary)

                Capsule().fill(Color.ctInkTertiary.opacity(0.5)).frame(height: 10)
                    .overlay(GeometryReader { geo in
                        Capsule().fill(
                            LinearGradient(
                                colors: [Color(hex: "#FFC489"), Color.ctAccent],
                                startPoint: .leading, endPoint: .trailing
                            )
                        ).frame(width: Swift.max(0, geo.size.width * CGFloat(pct)))
                    })
            }
        }
    }
}

// MARK: - BadgeView

struct BadgeView: View {
    let icon: String
    let name: String
    let unlocked: Bool
    let tint: Color

    init(icon: String, name: String, unlocked: Bool = true, tint: Color = .ctAccent) {
        self.icon = icon
        self.name = name
        self.unlocked = unlocked
        self.tint = tint
    }

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(tint.opacity(unlocked ? 0.18 : 0.08))
                    .frame(width: CTLayout.badgeDiameter, height: CTLayout.badgeDiameter)
                Text(icon)
                    .font(.system(size: 26))
                    .foregroundStyle(unlocked ? tint : .ctInkTertiary)
            }
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(unlocked ? .primary : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .lineSpacing(1.25)
        }
    }
}

// MARK: - Settings primitives

struct iOSToggle: View {
    @Binding var isOn: Bool
    var body: some View {
        Button {
            withAnimation(.ctTap) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? Color.ctAccent : Color.ctInkTertiary.opacity(0.5))
                Circle()
                    .fill(Color.white)
                    .frame(width: 27, height: 27)
                    .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 3)
            }
            .frame(width: 51, height: 31)
        }
        .buttonStyle(.plain)
    }
}

struct iOSFormRow: View {
    let title: String
    let detail: String?
    let isAccent: Bool
    let action: (() -> Void)?

    init(_ title: String, detail: String? = nil, isAccent: Bool = false, action: (() -> Void)? = nil) {
        self.title = title
        self.detail = detail
        self.isAccent = isAccent
        self.action = action
    }

    var body: some View {
        Button {
            action?()
        } label: {
            HStack {
                Text(title)
                    .font(.ctBody)
                    .foregroundStyle(isAccent ? Color.ctAccent : .primary)
                Spacer()
                if let detail {
                    Text(detail).font(.ctBody).foregroundStyle(Color.ctInkSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.ctInkTertiary)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

struct iOSToggleRow: View {
    let title: String
    let detail: String?
    @Binding var isOn: Bool

    init(_ title: String, detail: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.detail = detail
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.ctBody)
                if let detail { Text(detail).font(.caption).foregroundStyle(Color.ctInkSecondary) }
            }
            Spacer(minLength: 0)
            iOSToggle(isOn: $isOn)
        }
        .padding(.vertical, 8).frame(minHeight: CTLayout.formRowMin)
    }
}

struct SegmentedControl<T: Hashable>: View {
    let options: [T]
    let label: (T) -> String
    @Binding var selection: T

    init(options: [T], label: @escaping (T) -> String, selection: Binding<T>) {
        self.options = options
        self.label = label
        self._selection = selection
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.ctTap) { selection = option }
                } label: {
                    Text(label(option))
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(
                            (isSelected ? Color.ctCardSurface : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        )
                        .shadow(color: isSelected ? Color.black.opacity(0.08) : Color.clear, radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            }
        }
        .padding(2)
        .background(Color.ctInkTertiary.opacity(0.5), in: RoundedRectangle(cornerRadius: 9))
    }
}

struct StepperRow: View {
    let label: String
    let value: Int
    let step: Int
    let onMinus: () -> Void
    let onPlus: () -> Void

    init(_ label: String, value: Int, step: Int = 250, onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) {
        self.label = label
        self.value = value
        self.step = step
        self.onMinus = onMinus
        self.onPlus = onPlus
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.ctBody)
                Text("\(value) ml")
                    .font(.caption).foregroundStyle(Color.ctInkSecondary)
            }
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                Button(action: onMinus) {
                    Image(systemName: "minus").font(.system(size: 18, weight: .regular))
                        .frame(width: 42, height: 32)
                }
                .buttonStyle(.plain)
                Rectangle().fill(Color.ctInkSecondary.opacity(0.3))
                    .frame(width: 1, height: 18)
                Button(action: onPlus) {
                    Image(systemName: "plus").font(.system(size: 18, weight: .regular))
                        .frame(width: 42, height: 32)
                }
                .buttonStyle(.plain)
            }
            .background(Color.ctInkTertiary.opacity(0.5), in: RoundedRectangle(cornerRadius: 9))
        }
        .padding(.vertical, 8)
        .frame(minHeight: CTLayout.formRowMin)
    }
}

// MARK: - FloatingTabBar

struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 4) {
            TabBarButton(label: "Heute", systemImage: "calendar.badge.checkmark",
                         isSelected: selectedTab == 0) { selectedTab = 0 }
            TabBarButton(label: "Fortschritt", systemImage: "chart.bar.fill",
                         isSelected: selectedTab == 1) { selectedTab = 1 }
            TabBarButton(label: "Erfolge", systemImage: "trophy.fill",
                         isSelected: selectedTab == 2) { selectedTab = 2 }
        }
        .padding(CTLayout.tabBarPadding)
        .background(scheme == .dark ? Color.ctTabBarDark : Color.ctTabBarLight)
        .overlay(Capsule().strokeBorder(
            scheme == .dark ? Color.ctTabBarBorderDark : Color.ctTabBarBorderLight,
            lineWidth: 0.5))
        .clipShape(Capsule())
        .shadow(
            color: (scheme == .dark ? CTShadow.tabBarDark : CTShadow.tabBarLight).color,
            radius: (scheme == .dark ? CTShadow.tabBarDark : CTShadow.tabBarLight).radius,
            x: 0,
            y: (scheme == .dark ? CTShadow.tabBarDark : CTShadow.tabBarLight).y
        )
    }
}

struct TabBarButton: View {
    let label: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Image(systemName: systemImage)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.ctAccent : Color.ctTabInactive)
                Text(label).font(.ctTabLabel)
                    .foregroundStyle(isSelected ? Color.ctAccent : Color.ctTabInactive)
            }
            .frame(width: CTLayout.tabButtonWidth)
            .padding(.vertical, 6)
            .background(isSelected ? Color.ctTabBarActiveSurface : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
