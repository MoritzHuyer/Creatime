# Creatime — Session Summary

> Stand: 2026-07-13 (v9 — v7 Glass-Card Rollback)

Native iOS-SwiftUI-Habit-Tracker für tägliche Kreatin-Einnahme + Wasser-Tracking.
Build clean, 0 Warnings, läuft im iOS 17+ Simulator.

---

## Aktueller Zustand

**Architektur:** `@Observable`-Stores, App Group (`group.com.moritz.Creatime`)
zwischen App + Widget + LiveActivity, `Shared/StreakCalculator` als DRY-Quelle
der Streak-Logik für App+Widget.

**UI-System (Stand v9 = v7-Wiederherstellung):**
- Glass-Cards (`.liquidGlassCard()`) als Default-Chrom auf allen 3 Tabs
- 64pt Streak-🔥-Zahl als Glass-Karten-Hero auf TodayView
- 6er-StatGrid (2×3 Glass-Cards) auf HistoryView
- 140pt (visuell = 110pt Ring + 16pt Padding) Achievements-Ring + Next-Achievement-Card
- 22pt Spacing zwischen Cards, `Liquid-Gradient` als BG (Indigo→Teal)
- Padding-Hack `.padding(.horizontal, -8)` für MoodEdge-Bleed im MoodEmojiPicker
- `InsightsSection` (`4 Sub-Rows`), `AchievementSection`, `DayCell` wieder vorhanden
- Neue Datei: `Creatime/VacationBanner.swift` (war v8-Inline, jetzt eigenständig)

---

## Timeline (gekürzt)

### v9 (heute, 2026-07-13) — v7 Glass-Card Rollback
**Anlass:** User-Feedback „die UI ist zu glatt, sieht nicht wunderschön aus". v8-Editoral-Hero wurde zugunsten der ursprünglichen Glass-Card-Ästhetik komplett rückgängig gemacht. 7 View-Files neu geschrieben + `VacationBanner.swift` neu erstellt.
- **Commit:** `02ba3df` auf `main`, gepusht via Auto-Push.

### v8 (2026-07-13, zurückgenommen) — Editorial Hero Redesign
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

- Repo: `Creatime` (Public) auf GitHub — `https://github.com/MoritzHuyer/Creatime`
- HTTP-Status des Repos bestätigt: `200 OK`
- Branch: `main`
- Letzte Commit-SHA: `02ba3df` (v7-Rollback)
- **Auto-Push** aktiv: nach jeder Code-Task führe ich `git add` + Commit + `git push origin main` aus (User-Wunsch: „jedes Mal direkt automatisch pusht")
- **Build-Trigger-Auto-Push** zusätzlich via `PBXShellScriptBuildPhase` (Phase ID `AA41`, noop wenn kein Remote)
- `.gitignore` deckt `DerivedData/`, `.swiftpm/`, `build/`, `*.xcuserdata/`, `.obsidian/`, `*.pbxproj.bak.*` ab
- Doku: `CLAUDE.md` (Claude Code Memory), `README.md` (GitHub-Landingpage), `CHANGELOG.md` (Versionshistorie)
