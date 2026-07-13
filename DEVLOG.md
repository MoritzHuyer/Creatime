# 📓 Devlog — Building Creatime in Public

> Solo-Developer aus DE, baut seit 2026 an **Creatime 🦬** — einer
> iOS-SwiftUI-Habit-Tracker-App für kreatin- und Wasser-Routinen.
> Du kannst hier live mitlesen, wie die App wächst.

**Langzeit-Ziel:** Eines Tages im App Store launchen — das geht erst, sobald
ich 18 bin und die Apple Developer-Program-Gebühr zahlen kann. Bis dahin:
**Audience & Portfolio** aufbauen, damit der Launch-Tag ein Event ist, kein
Stress-Moment.

Mehr zur Strategie in [`./BUILDING_IN_PUBLIC.md`](./BUILDING_IN_PUBLIC.md).

---

## Letzte Einträge

### 2026-07-13 · v9 Rollback + v10 Sponsoring-Infrastruktur

**Was diese Woche passiert ist:**

- **v9:** User-Feedback „v8 sieht nicht wunderschön aus" → kompletter
  Rollback auf v7-Glass-Card-Layout. 7 View-Files neu geschrieben
  (`TodayView`, `HistoryView`, `AchievementsView`, `MoodEmojiPicker`,
  `WaterTrackerCard`, `RecoveryBuddyCard`, `MoodHistoryChart`) + neue Datei
  `Creatime/VacationBanner.swift` angelegt.
- **v10:** Sponsoring-Infrastruktur jetzt vorbereitet. `.github/FUNDING.yml`
  mit Platzhaltern für GitHub Sponsors + Ko-fi (echte Payouts erst mit 18,
  aber Slots sind ready-to-fill), `.github/ISSUE_TEMPLATE/` für Community-
  Feedback, DEVLOG + BUILDING_IN_PUBLIC für Open-Source-Transparenz.

**Was ich gelernt habe:**

- „Editorial" ≠ „schöner". Mein v8-Redesign war zu clean/leer.
  Charaktervolle Glass-Cards > super-minimalistisches Hero.
- Wenn Xcode-Tests durchlaufen, ist das ein guter Indikator — aber
  das echte visuelle Urteil liegt beim Simulator-Run.
- **Stripe- und PayPal-KYC-Gates** machen Sponsoring-Plattformen für
  Minderjährige unzugänglich. Lektion: Audience jetzt aufbauen, Payout am Tag-X.
- „Es gibt keinen Hack" — Wer bezahlt 18+ und €100/Jahr, der launcht.
  Wer das nicht hat, baut Audience und Portfolio. Beides ist valide.

---

### Ältere Einträge

_(Wird laufend ergänzt — pro Woche ca. 1-2 Einträge.)_

---

## Wie ich dieses Devlog strukturiere

- **Bottom-line zuerst** — Was ist passiert? Was kam dabei raus?
- **Journaling weekly** — Du wirst hier 1-2 Einträge pro Woche sehen.
- **Behind-the-Scenes** — Code, Bugs, Architektur-Diskussionen, was schiefgeht.
- **No Bullshit** — Wenn ich Mist baue, schreib ich das auf. Das ist der Deal.

---

## Aktueller Projektstand

| Metrik                          | Wert                                                  |
| ------------------------------- | ----------------------------------------------------- |
| **App-Version**                 | v10                                                   |
| **Lines of Swift**              | ~4.500 (14+ Dateien in `Creatime/`)                   |
| **Features (implementiert)**    | Streak, Wasser, Mood, Photo-Streak, Buddy, Live-Activity, Widgets, AppIntents, Liquid Glass Design |
| **Storage**                     | App Group (`UserDefaults`), kein Backend               |
| **Apple-Health-Sync**           | Bidirektional für Wasser                               |
| **App-Group**                   | `group.com.moritz.Creatime`                            |
| **Bundle-ID**                   | `com.moritz.Creatime`                                  |
| **Build-Status**                | Clean, 0 Warnings                                      |
| **Public Repo**                 | [github.com/MoritzHuyer/Creatime](https://github.com/MoritzHuyer/Creatime) |
| **Auto-Push-Workflow**          | aktiv (nach jedem `xcodebuild build`)                  |

---

## Wie du mich unterstützen kannst (und was nichts kostet)

- ⭐ **GitHub Star** — Visibility ohne Geld.
- 🐛 **[Issue aufmachen](https://github.com/MoritzHuyer/Creatime/issues/new/choose)** — Bugs + Feature-Wünsche, ich schaue alles persönlich durch.
- 📓 **Devlog teilen** — Reddit, Mastodon, Discord, wo auch immer Indie-Dev-Relevantes ist.
- 💬 **Mit-Diskutieren** — bei Architektur-Entscheidungen in den Issues.

Sobald ich alt genug bin: GitHub Sponsors + Ko-fi werden hier automatisch
aktiviert (Slots sind in `.github/FUNDING.yml` schon vorbereitet).

Vielen Dank fürs Mitlesen. 🦬
