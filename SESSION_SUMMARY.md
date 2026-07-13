# Creatime — Session Summary

> Stand: 2026-07-13 (v8 — Editorial Hero Redesign)

Native iOS-SwiftUI-Habit-Tracker für tägliche Kreatin-Einnahme + Wasser-Tracking.
Build clean, 0 Warnings, läuft im iOS 17+ Simulator.

---

## Aktueller Zustand

**Architektur:** `@Observable`-Stores, App Group (`group.com.moritz.Creatime`)
zwischen App + Widget + LiveActivity, `Shared/StreakCalculator` als DRY-Quelle
der Streak-Logik für App+Widget.

**UI-System (Stand v8):**
- `Color(.systemGroupedBackground)` als Default-BG auf allen 3 Tabs
- 96pt Streak-Hero auf Today, 72pt auf History, 120pt-Ring auf Achievements
- CAPS-Tracking-Sektionlabels als typografisches Pattern
- Keine `.regularMaterial`-Cards für Hero-Bereiche
- Inline-Komponenten (Mood/Week) ohne Card-Rahmen
- `AboutSheet` aus SettingsView für App-Info

---

## Timeline (gekürzt)

### v8 (heute, 2026-07-13) — Editorial Hero Redesign
- TodayView: 96pt-Hero, Mood/Week inline, Wasser als Compact-Strip, Recovery als Streifen, `TipCard` raus
- HistoryView: 72pt-Hero + 4-col KeyStats + CAPS-Labels + InsightsStrip
- AchievementsView: 120pt-Ring (vorher 140pt) + Soft-Badges + Tipp-Footer
- MoodEmojiPicker: Dot-as-Select-State, kein `.regularMaterial`
- WaterTrackerCard: eine HStack-Zeile statt 6 UI-Sektionen
- Tote Structs (`InsightsSection`, `AchievementsSection`, `DayCell`-Stub) entfernt

### v7 (2026-07-06) — Feature Batch
- MoodEmojiPicker + MoodHistoryChart — daily mood journaling mit 7-Bar-Chart
- Haptics Enum (zentralisiert)
- Confetti in Erfolge-Tab via `lastCelebratedMilestone`-Bridge
- Streak Recovery Buddy mit `__N__`-Placeholder
- Daily Goal Customization (`WaterStore.GoalMode`)
- Buddy Streak Battle v1 (`BuddySystem` `@MainActor`, Crockford Invite-Code)
- Activity Ring Calendar (`ActivityRingDayCell` 3 Ringe)
- Round-1-9 Hot-Patch-Fixes (Build-Debugging): Konfetti-Routing durch `markAsTaken`,
  Equatable-Conformance, Charts-Import, Helpers `moodScore(for:)`/`emoji(for:)`

### v3 (früher) — Smart Reminders
- Smart-Reminder-Heuristik: Median der letzten 14 Intake-Zeiten
- Vacation-Mode mit Vacation-Banner in TodayView

### v5 — Toolbar-Cleanup
- `StreakShareBanner` aus der HistoryView-Toolbar in den Body gewandert
- Doppelter `gearshape.fill`-Toolbar-Bug entfernt

### v0–v2 — Foundation
- Streak-Engine (`takenDays` Set + `StreakCalculator.currentStreak`)
- OnboardingView mit 3 Seiten
- TabRoot (3 Tabs)
- Liquid-Glass-Suffix-APIs (`.liquidGlassCard()`/`.liquidGlassSheet()`/`.liquidGlassBanner()`)

---

## Stores (`@Observable`)

```
CreatineStore    ← Streak-Logik + Mood + Achievements + Vacation
WaterStore       ← Wasser-ml-Mengen + GoalMode (ml/glasses/bottles)
PhotoStreakStore ← Weekly-Foto-Einträge
BuddySystem      ← Invite-Code + Buddy-Name/Streak (Phase 1: manuell)
SoundsManager    ← Theme-Sounds (Creatine, Water, Goal)
ThemeManager     ← Singleton, Theme Switching (über SettingsView)
LiveActivityManager ← Dynamic Island + Lock-Screen Banner
```

Keys sind in `defaults` (App Group) gespeichert:
`takenDays`, `skippedDays`, `frozenDays`, `intakeTimesByDay`, `celebratedMilestones`,
`moodByDay`, `lastCelebratedMilestone`, `vacationUntil`, `lastFreezeMonth`,
`waterByDay`, `waterDailyGoal`, `waterGoalMode`, `waterQuickAmounts`,
`buddyName`, `buddyStreak`, `lastBuddyUpdate`, `recoveryCardDismissedForDay`,
`hasCompletedOnboarding`, `healthSyncEnabled`, `selectedTab`,
`reminderHour`, `reminderMinute`, `firstLaunchAt`.

---

## Wichtige Helper-Konventionen

| Convention | Wo |
|--|--|
| `formatUnits(_:)` mit `.replacingOccurrences(of: ".", with: ",")` | `WaterTrackerCard.swift` (Deutsch-Formatierung) |
| `Haptics.successHeavy()` für Achievements, `Haptics.success()` für normal markiert, `Haptics.tap()` für UI-Mikro | `Haptics.swift` |
| Long-Press auf Wasser-Button startet `boostTask` @ 0.5s Repeater | `WaterTrackerCard.swift` |
| Konfetti-Pulse: `confettiTrigger = true; Task.sleep(80ms); confettiTrigger = false` | `TodayView`, `AchievementsView` |
| `__N__`-Placeholder in motivationalen Quotes (Backslash-Escape-frei) | `RecoveryBuddyCard.swift` |
| Push-to-Settings: `showSettings = true` aus Today/History/Erfolge | alle 3 Views |
| Skip-/Freeze/Menu-Patterns | `CreatineStore.useFreeze(markTodayAsSkipped)` |

---

## Build / Setup

```bash
xcodebuild -project Creatime.xcodeproj \
  -scheme Creatime \
  -destination 'generic/platform=iOS Simulator' \
  build                        # 0 warnings, 0 errors

open Creatime.xcodeproj        # ⌘R zum Starten
```

---

## Offene Punkte

- Phase 2 Buddy-Sync (CloudKit / MultipeerConnectivity) — aktuell manuelle Eingabe
- Photo-Upload in iCloud-Backup (aktuell nur Local-Speicher)
- Steps-Integration via HealthKit (Steps + Kreatin kombinieren)
- `SettingsView` noch nicht Editorial-konform (Glass-Stellen übrig)
- Performance-Profil bei 365-Tage-MonthCalendar (lazy loaded, sollte OK sein)
- Realer Onboarding-Test-Wizard mit Personality-Fragebogen
- TestFlight-Distribution (aktuell nur Local-Dev)

---

## Git / GitHub (Stand 2026-07-13)

- Repo: `Creatime` (Public) — wird beim nächsten Push via `gh repo create` angelegt
- Branch: `main`
- **Auto-Push** nach jedem Build via `PBXShellScriptBuildPhase` (Phase ID `AA41`)
- `.gitignore` deckt `DerivedData/`, `.swiftpm/`, `build/`, `*.xcuserdata/`, `.obsidian/`, `*.pbxproj.bak.*` ab
- Doku: `CLAUDE.md` (Claude Code Memory), `README.md` (GitHub), `CHANGELOG.md` (Versionshistorie)
