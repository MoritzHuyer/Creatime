# Changelog

Alle nennenswerten Änderungen an Creatime.
Datums-Format: `YYYY-MM-DD`.

---

## [v12] — 2026-07-15 · v7 Glass-Card UI-Revert + Beta-Label + V1-Launch-Checklist

v11 Bold Sports-App UI war zu cluttered (88pt Hero-Streak, Glow-Progress, Mesh-Background). Komplett-Revert auf v7 Glass-Card-Layout — das ist die Variante, die auf dem iPhone schon gefallen hat. Darkmode-Schutz (DynamicBackground + mode-aware LiquidGlass) bleibt erhalten, sonst kommt der matschige Indigo-Gradient zurück.

### Geänderte Dateien

- `Creatime/TodayView.swift` — v7 Layout (64pt Streak-Zahl, 48pt Emoji, 22pt Card-Spacing, 10 Sections)
- `Creatime/HistoryView.swift` — v7 Layout (9 Sections: Stat-Grid → Mood-Chart → Share-Banner → Insights → 2 Wochen-Charts → Buddy → Month-Calendar → Photo-Streak)
- `Creatime/AchievementsView.swift` — v7 Layout (110pt Hero-Ring + Next-Achievement-Card + 3-Spalten-Badge-Grid)
- `Creatime/WaterTrackerCard.swift` — v7 (42pt Hero-Number in Blue, ProgressBar mit scaleEffect y:1.6, Minus + Quick-Add + +1L Buttons)
- `Creatime/SettingsView.swift` — Footer-Text um „ (Beta)” ergänzt
- `Creatime.xcodeproj/project.pbxproj` — MARKETING_VERSION 1.0 → 0.9.0 (V1-Lock), CURRENT_PROJECT_VERSION 1 → 2

### Versionierung

- **MARKETING_VERSION** = `0.9.0` (1.0 für V1 App-Store-Submit reserviert)
- **CURRENT_PROJECT_VERSION** = `2` (Build-Counter incremented)
- **SettingsView-Footer** zeigt jetzt: „Creatime v0.9.0 (Beta)” + „Made with ❤️ by Moritz”

### V1 Launch Checklist (zu erledigen bis App-Store-Submit)

⭐ **V1-Blocker (was ich bis zum Launch tun muss):**

1. ⭐ **Apple Developer Program** — €99/Jahr (blockiert bis 18)
2. ⭐ **Englisch-Lokalisierung** — Settings-Texte aktuell DE-only
3. ⭐ **App Store Screenshots** — 6.7", 6.1", 5.5" (DE + EN)
4. ⭐ **App Store Description** — DE + EN, je ~4000 Zeichen
5. ⭐ **Privacy Policy URL** — im Web gehostet (Apple-Pflicht seit Mai 2024)
6. ⭐ **Support-URL** — im App Store Connect hinterlegt
7. ⭐ **Accessibility-Audit** — VoiceOver durch alle 3 Tabs (Heute / Fortschritt / Erfolge)
8. ⭐ **TestFlight** — mit 10–20 Beta-Usern vor V1-Submit
9. ⭐ **App Store Connect Final-Submit** — alle Felder gefüllt, Release-Notes

🛠️ **Post-Launch-Polish (nicht-blockierend):** App-Preview-Video, Onboarding-Feinschliff, Code-Sign/APNs-Key (nur falls LiveActivity-Push). Diese können auch nach V1-Launch passieren.

### Nicht verändert

- `Creatime/DynamicBackground.swift` — bleibt v11 (sonst LinearGradient = Darkmode-Bug zurück)
- `Creatime/LiquidGlass.swift` — bleibt v11 mode-aware (Darkmode-Schutz)
- `Creatime/ThemeManager.*`, `OnboardingView`, `NotificationManager`, `HealthKitManager`, Stores, LiveActivity

### Git

- (Auto-Push folgt nach Build-Verifikation)

---

## [v11] — 2026-07-14 · Bold Sports-App UI Redesign *(zurückgenommen in v12)*

Frischer Anlauf nach v9/v10: Bold-Sports-App-Look mit dynamischem Mesh-Background (`DynamicBackground.swift`) + 88pt Heavy Hero-Streak + Glow-Progress. Visuell auffällig, aber User-Feedback „zu cluttered, viel zu viel, vieles wiederholt sich" → Komplett-Revert in v12.

### Geänderte Dateien

- `Creatime/DynamicBackground.swift` **NEU** — mode-aware Orb-Background (ersetzt LinearGradient in 5 Files)
- `Creatime/LiquidGlass.swift` — mode-aware Highlights & Strokes für Darkmode-Schutz
- `Creatime/TodayView.swift` — Hero-Streak: 64pt → **88pt heavy** (theme-tinted) + UPPERCASE Tracking 1.4 Caption „TAGE IN FOLGE"
- `Creatime/HistoryView.swift` + `Creatime/AchievementsView.swift` — Bold Sports-App-Styling
- `Creatime/WaterTrackerCard.swift` — **56pt Heavy Hero-Number** + Glow-Shadow Progress-Bar (theme-tinted)

### Was bleibt (in v12 weiterverwendet)

- `Creatime/DynamicBackground.swift` — behalten als Darkmode-Schutz
- mode-aware `LiquidGlass.swift` — behalten für Darkmode-Reduktion der weißen Highlights

### Lehre

- „Bold und pumped" ≠ „schön" für eine persönliche Habit-Tracker-App. Mein Publikum will Konsistenz, keinen Fitness-Coach-Look.
- Layout-Density wichtiger als Style-Pushes. v11 hatte zu viele Cards + zu große Hero-Zahlen + visuelle Doppelung zwischen `TodayView` und `HistoryView`.
- Was ich behalten habe (DynamicBackground + mode-aware Glass) ist der technische Wert, nicht der visuelle. Pure UI-Reset, Infrastruktur-Update.

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
