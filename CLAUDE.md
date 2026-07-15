# Creatime — Claude Code Project Memory

> Stand: 2026-07-15 (v12 — UI-Revert auf v7 Glass-Card-Layout + Beta-Label)

iOS-SwiftUI-Habit-Tracker für tägliche Kreatin-Einnahme + Wasser-Tracking.

---

## Stack

| | |
|--|--|
| Sprache | SwiftUI, `@Observable`, iOS 17+ |
| Persistierung | App Group `group.com.moritz.Creatime` (`SharedDefaults.store`) |
| Build | Xcode 16, `Creatime` App + `CreatimeWidget` Extension + `CreatimeTests` |
| Bundle-ID | `com.moritz.Creatime` (App), `com.moritz.Creatime.CreatimeWidget` (Extension) |
| Min-iOS | 17.0 · Marketing `0.9.0` · Build `2` |

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

## v12 — v7 Glass-Card-Revert (2026-07-15) + Beta-Label

User-Feedback: v11 Bold Sports-App (siehe CHANGELOG.md [v11]) war zu cluttered + Doppel-Inhalte. Komplett-Revert auf v7 Glass-Card-Layout (vorher auf iPhone gefallen). Darkmode-Schutz (DynamicBackground + mode-aware LiquidGlass) bleibt erhalten.

**MARKETING_VERSION** ist jetzt `0.9.0` (1.0 für echten V1 App-Store-Submit reserviert). `CURRENT_PROJECT_VERSION` = `2`. Settings-Footer zeigt: „Creatime v0.9.0 (Beta)".

Geänderte Files: `TodayView.swift`, `HistoryView.swift`, `AchievementsView.swift`, `WaterTrackerCard.swift` (alle auf v7 restored via `git checkout 02ba3df`), `SettingsView.swift` (Footer-Erweiterung), `project.pbxproj` (Versioning), `CHANGELOG.md`/`DEVLOG.md` (Status).

V1 Launch Checklist mit 9 Blockern + 3 Post-Launch-Polish-Items in `CHANGELOG.md`. ⭐ = V1-blocker.

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

## Audience-Building-Strategy (v10)

Da App-Store-Launch erst mit 18 + €99/Jahr möglich: jetzt Audience aufbauen,
damit Launch-Tag ein Event ist.

**Hard-Fakten (verifiziert Mit-2025):**

| Plattform               | Min-Alter DE | Stripe/PayPal-KYC | Echt-Payout ab 18? |
| ----------------------- | ------------ | ----------------- | ------------------ |
| Apple App Store         | 18+          | n/a               | AB 18 + €99/Jahr   |
| Google Play             | 18+          | ja                | AB 18 + $25 einmal |
| GitHub Sponsors         | 18+          | ja (Stripe Connect)| nein (unter 18)    |
| Ko-fi                   | 18+          | ja (Stripe/PayPal) | nein (unter 18)    |
| Open Collective         | 18+          | ja                | nein (unter 18)    |
| PayPal.Me               | 18+          | ja (PayPal)       | nein (unter 18)    |
| Liberapay / BMC         | 18+          | ja                | nein (unter 18)    |
| PWA (Web-App)           | kein Gate    | n/a               | ja, immer (kein Geld, aber Audience) |

**Realistischer Pfad für mich:** B (Sponsoring-Slots ready, Audience jetzt
aufbauen) + D (€99 sparen, mit 18 launchen). Option A (PWA) als Marketing-
Beifang möglich, nicht als Hauptpfad.

### Marketing-/Store-Versionierung (wichtige Klarstellung)

Das Xcode-Projekt hat aktuell `MARKETING_VERSION = 1.0` / `CURRENT_PROJECT_VERSION = 1`
(siehe `Creatime.xcodeproj/project.pbxproj`). Die **v3/v5/v7/v8/v9/v10** in
`CHANGELOG.md` und `DEVLOG.md` sind **interne Feature-Codes**, NICHT die
App-Store-Versionsnummer. Beim ersten App-Store-Submit wird `MARKETING_VERSION`
final gesetzt (typischerweise `1.0` für den Launch). Bis dahin ist die
Versionsnummer im Binary bewusst klein gehalten.

### Dateien

- **`/DEVLOG.md`** — Building-in-Public-Journal (1-2/Woche eintragen)
- **`/BUILDING_IN_PUBLIC.md`** — Channel-Liste + Wochen/Monats-Checklisten +
  Launch-Vorbereitung für später
- **`/.github/FUNDING.yml`** — GitHub Sponsors + Ko-fi (Platzhalter, ready für 18+)
- **`/.github/ISSUE_TEMPLATE/`** — Bug + Feature Templates für Community

### Workflow-Hinweis

- **Bei jedem Code-Task:** am Ende `git add` + Commit + `git push origin main`
- **Bei DEVLOG-Updates:** manuell Sonntags/wochenweise, kein Auto-Push
  (außer ich pushe mit nach dem Schreiben)
- **Bei jeder Issue-Antwort:** im Issue-Thread antworten + ggf. im DEVLOG
  als Lessons-Learned vermerken

## Was ich NICHT anfasse

- `*.xcuserdata/` — User-State (per `.gitignore` exclude)
- `.obsidian/` — persönliche Notizen neben Projekt (per `.gitignore` exclude)
- `SPECs/Library/Creatine-Monohydrate-Facts.md` (existiert nicht, weglassen)
- Apple-Signing-Certificates (nur Apple Account verwaltet)
