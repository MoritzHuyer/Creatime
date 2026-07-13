# Creatime — Claude Code Project Memory

> Stand: 2026-07-13 (v9 — v7 Glass-Card Rollback)

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

## v9 — v7 Glass-Card-Layout (heute ausgerollt, **Rollback von v8**)

User-Feedback „zu glatt, nicht wunderschön" → Editorial-Hero vollständig rückgängig. Glass-Card-Optik ist jetzt wieder überall.

### Heute-Tab
- **64pt Streak-🔥** freistehend in Glass-Card (Label "Tage in Folge" drunter)
- MoodEmojiPicker in eigener Glass-Card (5 Emojis + Labels, `.padding(.horizontal, -8)` Edge-Bleed-Hack wieder aktiv)
- WeekOverview in Glass-Card (7 Kreise, 30pt)
- RecoveryBuddyCard als pink Glass-Card mit "Heute Kreatin nehmen"-Button
- Big "Kreatin genommen"-Button (60pt, volle Breite)
- Pause/Freeze als `Menu` (typografisch klein, unter dem Big-Button)
- WaterTrackerCard in voller Glass-Card (Header + Goal-Row + dicke Progress-Bar + 42pt Hero + Action-Row mit Long-Press-Boost)
- TipCard als Glass-Card (Tipp-rotiert täglich)
- Reminder-Chip als Capsule am Foot
- BG: `LinearGradient(systemIndigo.0.10 → systemTeal.0.06 → .clear)`

### Fortschritt-Tab
- **6er-Stat-Grid 2×3** mit Glass-Cards: Aktuelle Streak / Creatine-Quote / Wasser-Ø / Buddy / Mood-Ø / Konsistenz-Score
- MoodHistoryChart (7-Bar-Chart) in Glass-Card
- StreakShareBanner in Glass-Card (ActivityShareSheet-Share-Button)
- **InsightsSection** in Glass-Card (4 Sub-Rows: Wasser-Ø-Woche / Wochenvergleich / Vergesslichster-Wochentag / Konsistenz-Score)
- 2 Weekly-Charts (Wasser + Creatin) in Glass-Cards
- BuddyView in Glass-Card
- MonthCalendar (Glass-Card) mit wieder-eingeführtem `DayCell`-Stub
- PhotoStreakSection (Glass-Card) am Ende

### Erfolge-Tab
- **140pt visuell (= 110pt Ring + 16pt Padding)** Hero-Ring + unlocked-counter
- Next-Achievement-Card in Glass (wieder-eingeführt ≠ v8 soft border)
- AchievementSection 3-Spalten-Grid (wieder-eingeführt) mit `AchievementBadge` (Glass)

### Neu hinzugefügte Datei
- `Creatime/VacationBanner.swift` — Glass-Card mit Palm-Icon + Datum + Chevron, full-width tap-area (`onTap: () -> Void`)

### Hinzugefügte Structs (Re-Intro aus v8-Cleanup)
- `InsightsSection` + `InsightRow` (in HistoryView)
- `AchievementSection` (in AchievementsView)
- `DayCell` Simple-Stub (in HistoryView)

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

- Repo Name: `Creatime` auf `https://github.com/MoritzHuyer/Creatime` (Public)
- Remote: bereits angelegt mit `gh repo create Creatime --public --source=. --remote=origin`
- Branch: `main`
- Letzte Commit-SHA: `02ba3df` (v9 = v7-Rollback)
- **Auto-Push-Workflow**: Ich pushe nach jeder fertigen Code-Task automatisch via `git add` + Commit + `git push origin main` (User-Wunsch)
- **Build-Trigger-Auto-Push** zusätzlich via `PBXShellScriptBuildPhase` (Phase ID `AA41`)
- Workflows: noch keine — optional später `ios-testflight-deploy.yml`

---

## Was ich NICHT anfasse

- `*.xcuserdata/` — User-State (per `.gitignore` exclude)
- `.obsidian/` — persönliche Notizen neben Projekt (per `.gitignore` exclude)
- `SPECs/Library/Creatine-Monohydrate-Facts.md` (existiert nicht, weglassen)
- Apple-Signing-Certificates (nur Apple Account verwaltet)
