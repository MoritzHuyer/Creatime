# Changelog

Alle nennenswerten Änderungen an Creatime.
Datums-Format: `YYYY-MM-DD`.

---

## [v8] — 2026-07-13 · Editorial Hero Redesign

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

## [v7] — 2026-07-06 · Feature Batch

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
