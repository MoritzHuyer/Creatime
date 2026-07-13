# Creatime — Claude Code Project Memory

> Stand: 2026-07-13 (v8 — Editorial Hero Redesign)

iOS-SwiftUI-Habit-Tracker für tägliche Kreatin-Einnahme + Wasser-Tracking.

---

## Stack

| | |
|--|--|
| Sprache | SwiftUI, `@Observable`, iOS 17+ |
| Persistierung | App Group `group.com.moritz.Creatime` (`SharedDefaults.store`) |
| Build | Xcode 16, `Creatime` App + `CreatimeWidget` Extension + `CreatimeTests` |
| Bundle-ID | `com.moritz.Creatime` (App), `com.moritz.Creatime.CreatimeWidget` (Extension) |
| Min-iOS | 17.0 · Marketing `1.0` · Build `1` |

---

## Stores (`@Observable`, in `Creatime/`)

- **`CreatineStore`** — Streak-Logik. `takenDays`/`skippedDays`/`frozenDays: Set<String>`,
  `moodByDay: [String:String]`, `intakeTimesByDay`, `celebratedMilestones`,
  `lastCelebratedMilestone`. Vacation-Toggle via `vacationUntil`.
- **`WaterStore`** — `waterByDay: [String:Int]`, `dailyGoal` (ml),
  `GoalMode` enum (`.ml`/`.glasses`/`.bottles`), `quickAmounts: [Int]`.
  `didSet` rundet `dailyGoal` auf nächste Einheit beim Mode-Wechsel.
- **`PhotoStreakStore`** — Weekly-Foto-Einträge.
- **`BuddySystem`** (SwiftUI-View) — `myInviteCode` (6-char Crockford), `buddyName`, `buddyStreak`,
  `lastBuddyUpdate`. Phase-1-manuell, Phase-2-CloudKit-Sync TODO.
- **Singletons** — `SoundsManager`, `ThemeManager.shared`, `LiveActivityManager.shared`.

`SettingsView` als Sheet (NICHT Tab!) — aus allen 3 Tabs erreichbar.

---

## Shared Module (`Shared/`)

- **`StreakCalculator.currentStreak(takenDays:skippedDays:frozenDays:)`** — App UND
  Widget nutzen identische Funktion (DRY-Strategie).
- **`SharedDefaults.store`** — `UserDefaults(suiteName: "group.com.moritz.Creatime")`.
- **`DayKey`** — `yyyy-MM-dd` String-Format (POSIX-Locale, Format/Sortierung-stabil).

---

## v8 — Editorial Hero UI (heute ausgerollt)

### Heute-Tab
- **96pt Streak-🔥** als freistehender Hero (kein Card-Rahmen, kein Gradient-BG)
- `systemGroupedBackground` statt Glass-Gradient
- MoodEmojiPicker inline (5 Emoji, kein `.regularMaterial`)
- WeekOverview inline (7 Kreise, 30pt heute-Ring)
- WaterTrackerCard als **eine Zeile** (Label · Hero-Number · Progress · Quick-Buttons)
- RecoveryBuddyCard als eingebetteter `tertiarySystemFill`-Streifen (selten)
- TipCard **entfernt** (Content wandert nach Achievements)

### Fortschritt-Tab
- 72pt Streak-Hero
- **4-Spalten KeyStats** mit `Divider().opacity(0.4)` (Ø Wasser / Perfekte Tage / Score / Mood-Ø)
- **InsightsStrip** statt InsightsCard (Score-Ring 54pt + Heatmap + Wochenvergleich in EINEM)
- **CAPS-Sektionlabels** mit Tracking 1.4
- MonthCalendar mit `ActivityRingDayCell` (3 Ringe)

### Erfolge-Tab
- **120pt Hero-Ring** (vorher 140pt — visuelle Konsistenz mit TodayView)
- **Soft-Badges** mit dünner `separator` Border + `secondarySystemGroupedBackground`
- **Tipp-Footer** migriert (war auf TodayView)

---

## v7 — Feature-Batch (2026-07-06)

| Feature | Kerndatei |
|--|--|
| MoodEmojiPicker | `Creatime/MoodEmojiPicker.swift` |
| MoodHistoryChart | `Creatime/MoodHistoryChart.swift` (`import Charts`) |
| Haptics (centralized) | `Creatime/Haptics.swift` |
| Confetti in Erfolge | `Creatime/AchievementsView.swift` (`lastCelebratedMilestone` bridge) |
| Streak Recovery Buddy | `Creatime/RecoveryBuddyCard.swift` |
| Wasser Goal Customization | `Creatime/WaterStore.swift` (`GoalMode` enum) |
| Buddy Streak Battle | `Creatime/BuddySystem.swift` + `Creatime/BuddyView.swift` |
| Activity Ring Calendar | `Creatime/ActivityRingDayCell.swift` |

---

## Konventionen

- **Code-Kommentare** deutsch / englisch mischen (identifier immer englisch)
- **KEIN `.regularMaterial`-Card** für Hero-Bereiche (Editorial-Look)
- **`formatUnits(_:)` WaterTrackerCard** — Deutsch-Formatierung via
  `.replacingOccurrences(of: ".", with: ",")`
- **`Haptics.successHeavy()`** für Achievements, `success()` für normal markiert,
  `tap()` für Mikro-Feedback
- **`__N__`-Placeholder** für Backslash-Escape-frei String-Templates
- **`liquidGlassCard/Sheet/Banner`**-Suffix-APIs existieren (gefunden in `Shared/`-Helpers,
  Definitionen je nach Xcode-Version vorhanden)

---

## Build / Test / Auto-Push

```bash
xcodebuild -project Creatime.xcodeproj \
  -scheme Creatime \
  -destination 'generic/platform=iOS Simulator' build
```

**Auto-Push** nach jedem erfolgreichen Build via `PBXShellScriptBuildPhase`
(Object ID `AA41`, Phase „Auto-Push"): `git add -A` + auto-commit mit
Timestamp + `git push origin main`. Noop wenn kein Remote konfiguriert.

---

## Git / GitHub

- Repo Name: `Creatime` (Public)
- Remote: nach `gh auth login` einmalig `gh repo create Creatime --public --source=. --remote=origin --push`
- Branch: `main`
- Workflows: noch keine — optional später `ios-testflight-deploy.yml`

---

## Was ich NICHT anfasse

- `*.xcuserdata/` — User-State (per `.gitignore` exclude)
- `.obsidian/` — persönliche Notizen neben Projekt (per `.gitignore` exclude)
- `SPECs/Library/Creatine-Monohydrate-Facts.md` (existiert nicht, weglassen)
- Apple-Signing-Certificates (nur Apple Account verwaltet)
