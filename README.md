# Creatime 🦬

Deine tägliche Kreatin-Routine — Streak im Blick, Wasser im Blick, nichts sonst.

> Native iOS SwiftUI App · iOS 17+ · Xcode 16
>
> Stand: **2026-07-13 — v8 Editorial Hero Redesign**

![App-Screenshots](docs/screenshots.png)

---

## Features

| | |
|--|--|
| 🔥 | **Editorial Streak-Hero** — riesige 96pt-Tages-Zahl, du siehst sofort wo du stehst |
| 😐-🤩 | **Mood-Tagebuch** — 5 Achsen mit kleinem 7-Bar-History-Chart |
| 💧 | **Wasser-Tracker** — Einheit frei wählbar: Liter · Gläser · Flaschen |
| ⚡️ | **Haptisches Feedback** — iOS-native Mikros bei jedem Tap |
| 🎉 | **Konfetti** — bei Erfolge-Freischaltung (3 / 7 / 14 / 30 / 60 / 100 Tage) |
| ❄️ | **Streak-Freeze** — 2 Eis-Tage pro Monat schützen dein Streak-Konto |
| 👥 | **Buddy Streak Battle** — lade einen Freund ein, vergleicht eure Streaks |
| 🎯 | **Activity Ring Kalender** — pro Tag: Kreatin / Wasser / Foto als Ringe |
| 🔔 | **Smart Reminder** — Median deiner letzten 14 Tage Intake-Zeiten |
| 💎 | **Apple Health Sync** (optional, Wasser) |

---

## Architektur

- **SwiftUI + `@Observable`** (iOS 17) — keine Combine, kein Redux-Boilerplate
- **App Group** `group.com.moritz.Creatime` — App + Widget + LiveActivity lesen identisch
- **`Shared/StreakCalculator`** — DRY-Streak-Logik für App und Widget
- **Liquid Glass** — Sheet-/Banner-/Card-Suffix-APIs für Soft-Container

### Tech-Stack

| | |
|--|--|
| Sprache | SwiftUI (iOS 17+) |
| Persistenz | UserDefaults via App Group |
| Targets | iPhone-only (`TARGETED_DEVICE_FAMILY = 1`) |
| Min-iOS | 17.0 |
| Bundle-ID | `com.moritz.Creatime` |

---

## Setup

```bash
git clone https://github.com/MORITZ_USERNAME/Creatime.git
cd Creatime
open Creatime.xcodeproj
# ⌘R to run
```

### CLI Build

```bash
xcodebuild -project Creatime.xcodeproj \
  -scheme Creatime \
  -destination 'generic/platform=iOS Simulator' \
  build
```

### CLI Test

```bash
xcodebuild -project Creatime.xcodeproj \
  -scheme Creatime \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test
```

---

## Auto-Push nach jedem Build

Im Xcode-Projekt ist eine `PBXShellScriptBuildPhase` (Phase-ID `AA41`,
Phase-Name „Auto-Push") eingebaut. Sie committet und pusht automatisch
nach jedem erfolgreichen Xcode-Build:

```bash
# Pseudo-Code der Phase (siehe project.pbxproj)
if ! git remote -v | grep -q origin; then exit 0; fi  # ohne Remote: noop
git add -A
if git diff --cached --quiet; then exit 0; fi         # keine Änderungen: skip
git commit -m "Auto-commit `date +%H:%M:%S`"
git push origin main 2>/dev/null || true              # silent on failure
```

### Auto-Push deaktivieren

Xcode → Target **Creatime** → Build Phases → „Auto-Push" löschen.

---

## Roadmap (offen)

- Phase 2 — Buddy-Sync (CloudKit / MultipeerConnectivity), aktuell manuelle Eingabe
- Steps-Integration via Apple Health
- Photo-Streak-Upload in iCloud-Backup
- Realer Onboarding-Test-Wizard mit Personality-Fragebogen

---

## Lizenz

Privat. Moritz. Alle Rechte vorbehalten.

---

🦬 Creatime — eine Streak, mehr nicht.
