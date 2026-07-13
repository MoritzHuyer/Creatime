# Changelog

Alle nennenswerten Änderungen an Creatime.
Datums-Format: `YYYY-MM-DD`.

---

## [v10] — 2026-07-13 · Sponsoring & Audience-Infrastruktur

Da der App-Store-Launch noch warten muss (Apple Developer Program verlangt
18+ + €99/Jahr, Payouts via Stripe/PayPal ebenfalls 18+), baue ich jetzt
**Audience + Portfolio** auf, damit der Launch-Tag ein Event ist, kein
Stress-Moment.

### Neue Dateien

- `.github/FUNDING.yml` — GitHub Sponsors + Ko-fi Slots als Platzhalter
  (Payouts geblockt bis 18+, Slots ready-to-fill, GitHub zeigt dann
  automatisch Buttons im Repo-Header).
- `.github/ISSUE_TEMPLATE/bug_report.md` — standardisiertes Bug-Reporting.
- `.github/ISSUE_TEMPLATE/feature_request.md` — standardisierte Feature-Wünsche.
- `DEVLOG.md` — „Building Creatime in Public" — Wochenjournal mit ehrlichen
  Status-Updates und Lessons-Learned.
- `BUILDING_IN_PUBLIC.md` — Audience-Growth-Playbook: Channel-Liste
  (Reddit/X/YouTube/Hacker News), Wochen- und Monats-Checklisten,
  Launch-Vorbereitung für später, was ich NICHT mache.

### Geänderte Dateien

- `README.md` — Stand-Banner auf v10 aktualisiert + neue Sponsor-Section
  + DEVLOG-Link + „Activity Ring" Line unverändert.
- `CLAUDE.md` — Stand auf v10, neue „Audience-Building-Strategy" Section
  mit Sponsoring-Gate-Realität (18+, Stripe/PayPal KYC).

### Nicht verändert

- Source-Code (`Creatime/`, `Shared/`, `CreatimeWidget/`, `Config/`)
- Build-Konfiguration
- Auto-Push-Workflow

### Warum das eine richtige Veränderung ist

1. **Audience baut sich auf, BEVOR die App live geht** — kostenloser
   Marketing-Vorteil am Launch-Tag
2. **Portfolio-Beweis** — Recruiter sehen GitHub-Stars + DEVLOG = seriös
3. **Issue-Templates** strukturieren Community-Feedback von Tag 1 an
4. **Sponsoring-Slots sind ready** — sobald ich 18 bin: 5-Min-Activation

### Git

- (Auto-Push folgt nach Build-Verifikation)

---

## [v9] — 2026-07-13 · v7 Glass-Card Rollback

Komplette Rücknahme des v8-Editorial-Hero-Redesigns.

**Anlass:** User-Feedback: die neue UI „ist zu viel glatt, sieht nicht wunderschön aus". v8 wirkte zu flach/zu clean ohne Charakter. Resultat: vollständige Wiederherstellung des ursprünglichen v7-Glass-Card-Looks.

### Geänderte Dateien
- `Creatime/TodayView.swift` — komplett neu geschrieben, Glass-Card-Layout 22pt spacing, 7 Cards (Streak, Mood, Week, Recovery, Hauptaufgabe, Wasser, Tipp)
- `Creatime/HistoryView.swift` — komplett neu geschrieben, 6-Tile-StatGrid 2×3 + InsightsSection + 2 Weekly-Charts + BuddyView + MonthCalendar mit reaktiviertem `DayCell` + PhotoStreakSection. `perfectDays` dead code entfernt (war in v8)
- `Creatime/AchievementsView.swift` — komplett neu geschrieben, 140pt Hero-Ring (visuell) + Next-Achievement-Card + `AchievementSection` 3-Spalten-Grid (Glass)
- `Creatime/MoodEmojiPicker.swift` — reaktiviert: Glass-Card, 5 Emojis + Labels, `.padding(.horizontal, -8)` Edge-Bleed-Hack
- `Creatime/WaterTrackerCard.swift` — reaktiviert: volle Glass-Card (Header + Goal-Row + dicke ProgressBar + 42pt Hero + Action-Row mit Long-Press-Boost + NavigationLink Ziel-Sheet)
- `Creatime/RecoveryBuddyCard.swift` — reaktiviert: pink Glass-Card mit Quote + „Heute Kreatin nehmen"-Button
- `Creatime/MoodHistoryChart.swift` — unverändert, public Helpers bleiben

### Neue Datei
- `Creatime/VacationBanner.swift` — Glass-Card mit Palm-Icon + Datum + Chevron, full-width tap. War v8 inline in TodayView/HistoryView und ist jetzt eigenständig.

### Re-Intro `dead code` aus v8-Cleanup
- `InsightsSection` + private `InsightRow` (in HistoryView)
- `AchievementSection` (in AchievementsView)
- `DayCell` simple Stub (in HistoryView) — ActivityRingDayCell existiert weiter, wird aber aktuell nicht im MonthCalendar v7 verwendet

### Funktional unverändert
- Haptics.Enum (`success`/`error`/`tap`/`tapMedium`/`select`/`boost`/`successHeavy`)
- ConfettiView via `lastCelebratedMilestone` + `acknowledgeLatestMilestone()`
- markAsTaken / freezeToday / skipToday-Pfad in TodayView
- LiveActivityManager.pushLiveActivityUpdate
- AchievementDetailSheet + CelebrationToast (in AchievementsView bleibt inline)
- WaterStore.GoalMode (ml / glasses / bottles), quickAmounts, didSet-Rounding

### Git
- **Commit-SHA**: `02ba3df` auf `main`
- **Auto-Push-Workflow** aktiv: nach jeder Code-Task wird `git add` + Commit + `git push origin main` ausgeführt

---

## [v8] — 2026-07-13 · Editorial Hero Redesign *(zurückgenommen in v9)*

### Heute-Tab
- **96pt Streak-Hero** als freistehender Eye-Catcher (vorher 64pt + separate „Tage in Folge"-Subtitel)
- `Color(.systemGroupedBackground)` statt Glass-Gradient → ruhiger editorial Look
- `MoodEmojiPicker` jetzt **inline** ohne `.regularMaterial`-Card-Rahmen
- `WeekOverview` inline, 30pt-Heute-Ring statt 34pt
- `WaterTrackerCard` als **einzeiliger Compact-Strip** (Label · Anzahl · Progress · Quick-Buttons)
- `RecoveryBuddyCard` als eingebetteter `tertiarySystemFill`-Streifen, Pink-Tint 0.85 entsättigt
- **`TipCard` vollständig entfernt** aus Today-Tab (Content migriert → Achievements-Footer)
- Vacation-Banner als `Capsule()` statt Card-Background
- Negativer `.padding(.horizontal, -8)`-Hack in MoodEmojiPicker raus
- Pause-Button-Label vereinfacht: „Heute pausieren oder einfrieren"

### Fortschritt-Tab
- **72pt Streak-Hero** mit Best/30d/Lifetime-Subzeile (vorher: 6er-Stat-Grid mit Glass-Cards)
- **4-Spalten KeyStats** mit `Divider().opacity(0.4)` (Ø Wasser · Perfekte Tage · Score · Mood-Ø)
- **CAPS-Sektionslabels** mit `tracking(1.4)` als Konstant-Editorial-Pattern
- **`InsightsStrip`** ersetzt `InsightsCard` — Score-Ring 54pt + Heatmap + Wochenvergleich in EINEM
- MoodHistoryChart bleibt, jetzt zwischen KeyStats und Insights

### Erfolge-Tab
- **Hero-Ring 140pt → 120pt** für visuelle Konsistenz mit TodayView (Counter 64pt → 48pt)
- **Soft-Badges** mit dünner `separator` Border + `secondarySystemGroupedBackground` statt Glass
- **Tipp-Footer** neu (vom Heute-Tab migriert, Inhalt eigenständig)

### Cleanup
- Tote Structs entfernt: `InsightsSection`, `AchievementsSection`, `DayCell`-Stub
- Ungenutzte `previous`-Variable im Wochenvergleich entfernt
- `MoodHistoryChart` public Helpers: `moodScore(for:)`, `emoji(for:)`

---

## [v7] — 2026-07-06 · Feature Batch *(wieder aktuell seit v9)*

### Features
- **MoodEmojiPicker** im Heute-Tab (5 Emoji-Achsen: 😐😊🤩🥵😴)
- **MoodHistoryChart** im Fortschritts-Tab (mini 7-Bar-Chart, `import Charts`)
- **Haptics** Enum (`success`/`error`/`tap`/`tapMedium`/`select`/`boost`/`successHeavy`) mit `prepare()`-Pattern
- **Confetti in Erfolge-Tab** — beobachtet `store.lastCelebratedMilestone`, feuert `ConfettiView` + `CelebrationToast`, ack via `acknowledgeLatestMilestone()`
- **Streak Recovery Buddy** — motivierende Karte wenn Streak gerade gebrochen UND Best ≥ 7 Tage, Action-Closure routed durch `TodayView.markAsTaken()` damit Konfetti konsistent bleibt
- **Wasser Goal Customization** — `WaterStore.GoalMode` enum (ml/glasses/bottles), `didSet`-Rounding auf nächste Einheit
- **Buddy Streak Battle v1** — `@MainActor BuddySystem`, 6-stelliger Crockford Invite-Code, `ActivityShareSheet` global definiert in `ShareStreakCard.swift`
- **Activity Ring Calendar** — `ActivityRingDayCell` ersetzt `DayCell`, 3 konzentrische Ringe (Creatine grün/orange/cyan / Wasser cyan / Foto pink), ISO-Woche-basierte Foto-Detection

### Wiring
- `CreatineStore` — neue Felder `moodByDay`, `lastCelebratedMilestone`, beide in `init()`/`save()`/`reload()` gepflegt
- `CreatimeApp` — `BuddySystem` injected via `.environment(buddy)`
- `AchievementsView.fireConfetti` — beobachtet `store.lastCelebratedMilestone` über `onChange`
- `SettingsView` — Wasser-Einheit-Card mit segmentiertem Picker für `goalMode`

### Persistierung
- `WaterStore`: `goalModeKey`, `goalKey` neu in `defaults`
- `CreatineStore.save()` schreibt jetzt alle Felder (vorher fehlten `mood` + `lastCelebrated`)
- `WaterStore.goalMode.didSet` rundet `dailyGoal` auf nächste Einheit (verhindert „8,5 / 8 Gläser" Anzeige)

### Konvention
- `__N__`-Placeholder in `RecoveryBuddyCard`-Quotes (statt Swift-Interpolation-Konflikt mit Backslash)
- `Achievement.Equatable` (mit 4-Feld `==` für Animationen)

---

## [v0–v6] — Foundation

Vorgängerversionen: TabRoot (Heute / Fortschritt / Erfolge), Onboarding (3 Seiten), Smart-Reminder-Heuristik aus Intake-Zeiten, Vacation-Mode, Streak-Freeze (2/Monat), Photo-Streak (wöchentliche Erinnerung), Goal-Reach-Haptic+Sound, Liquid-Glass-Suffix-APIs, WeekOverview Status-Ringe, MonthCalendar ActivityRingDayCell, Widget + LiveActivity Pipeline, StatCard-Grid (vor v8), Buddy-View-Editor-Sheet mit Stepper, ShareStreakCard.
