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

### 2026-07-18 · Quiz-Onboarding + Konkurrenz-Analyse

**Was passiert ist:**

- **Eine sehr ähnliche App entdeckt** („Creatine Today" im App Store) — poliert,
  mit Quiz-Onboarding und 29,99 €/Jahr-Abo. Erste Reaktion: „Lohnt sich das noch?"
- **Antwort: ja.** Konkurrenz validiert den Markt (Leute suchen & zahlen für
  Kreatin-Tracker). Ich muss sie nicht schlagen — ich brauche einen eigenen Winkel.
  Creatime hat einen: **Wasser, Stimmung, Buddy-Battle, Foto-Streak** — Sachen,
  die eine reine Kreatin-App nicht hat. Positionierung: „Mehr als nur Kreatin —
  und ohne Abo-Genörgel."
- **Neues Quiz-Onboarding gebaut** — inspiriert vom Funnel-Prinzip, aber
  BEWUSST kein Klon: eigener heller Indigo-Look statt Orange, eigene Texte,
  und ein Schritt, den die Konkurrenz nicht hat (Wasserziel).
  Schritte: Willkommen → Ziel → **Gewicht → personalisierte Dosis** → Training
  → Erinnerung → Wasserziel → Plan-Zusammenfassung.
- **Dosis-Rechner** als echtes neues Feature: aus dem Gewicht wird eine
  Tagesdosis (Richtwert ~0,03 g/kg, gedeckelt 3–5 g) berechnet und dezent auf
  dem Heute-Tab angezeigt.

**Was ich gelernt habe:**

- **Konkurrenz ist ein Marktbeweis, kein Stoppschild.** Der leere Markt wäre
  das schlechtere Zeichen.
- **Nicht kopieren — differenzieren.** Denselben Funnel-Aufbau nutzen, aber mit
  eigener Identität, sonst bin ich nur ein Abklatsch.
- **Ein gutes Onboarding ist selbst ein Feature.** Es verbessert Retention und
  liefert direkt einen Nutzen (die personalisierte Dosis).
- **Monetarisierung bewusst offen gelassen** — ich kann eh erst mit 18
  veröffentlichen. Tendenz: einmaliger „Pro-Unlock" statt Mini-Abo.

---

### 2026-07-18 · v17 „Creatime V2" — Neustart + großes Feature-Update

**Was passiert ist:**

Nach den v13–v16-Runden (viel mit einem KI-Tool umgebaut) war die App für
mich verbaut: die UI war „gefallen", viele Features funktionierten nicht mehr
so, wie sie sollten, und ein „bitte nur ein paar Sachen fixen" endete jedes
Mal in einem kompletten UI-Umbau. Also: **sauberer Neuanfang.**

- **Ausgangspunkt gefunden über ein Handy-Screenrecording.** Auf meinem iPhone
  lief noch die Version, die mir gefiel. Aus dem Video wurde Frame für Frame
  klar: das war der **v13 „Airy-Layout"-Stand** (Commit `e98fa7c`) — luftiges
  Layout, Indigo-Akzent, Mood-Picker, Tipp-des-Tages. Genau den habe ich als
  saubere Basis für **„Creatime V2"** genommen.
- **Danach Schritt für Schritt aufgebaut, jede Änderung ein eigener Commit,**
  damit nie wieder eine ganze UI „wegrutscht".

**Was neu/besser ist:**

- **Heute-Tab:** „Kreatin genommen" ist jetzt der große Haupt-Button ganz oben.
  Moodboard kompakter. Wasser bekommt eine **Ziel-Leiste** (voll = 100 %,
  wird grün) + Prozentanzeige + Mengen-Tipp.
- **Sounds komplett neu:** Der harte iOS-System-„Punch" (das nervige „Ticken",
  bei dem man die Lautstärke nicht regeln kann) ist raus. Ich **synthetisiere
  jetzt eigene, weiche Töne** (PCM im Speicher, `AVAudioPlayer`) mit voller
  Lautstärke-Kontrolle. Abhaken = sanfter Zwei-Ton, Ziel erreicht = kleines
  C-E-G-Glöckchen. Respektiert den Lautlos-Schalter.
- **Meilenstein-Feiern:** Bei 7/30/100 Tagen ein hereinfederndes Feier-Overlay
  mit Emoji, Titel und Motivationszeile + Chime + Konfetti.
- **Widget poliert:** übernimmt jetzt die gewählte Theme-Farbe, zeigt Wasser-%
  und einen grünen „Ziel erreicht"-Zustand.
- **Mehrere Supplements:** neben Kreatin (bleibt der Held) eine optionale
  Checkliste. Eigener Verwaltungs-Bereich in den Einstellungen + 14 Vorlagen.
- **Fortschritt aufgeräumt:** der verwirrende „Trends"-Block (Score-Ring,
  „Vergessen am Tag", Wochenvergleich) ist weg. Trends = 2 klare Diagramme
  (Wasser 14 Tage + Stimmung 7 Tage), gruppiert in Überblick → Kalender →
  Trends → Community.
- **Deutsch-Fix + Bugfixes:** Kalender/Wochentage fest deutsch, Sound-Toggle
  wirkt, Wasser aus Widget/Siri erscheint sofort in der App, Wochenschnitt
  korrekt, seitliches Scrollen im Fortschritt-Tab behoben.

**Was ich gelernt habe:**

- **Wenn ein Umbau die App verschlimmert, ist der mutigste Schritt der Reset.**
  Nicht immer weiter draufpatchen — zurück zum letzten Stand, der sich richtig
  angefühlt hat, und von dort sauber aufbauen.
- **Ein Screenrecording ist eine Spezifikation.** Der beste „Design-Brief" war
  einfach das Video der Version, die mir gefiel.
- **Ein Commit pro Änderung = Angstfreiheit.** Weil jeder Schritt einzeln
  rückrollbar ist, traue ich mich, größere Sachen umzubauen.
- **System-Sounds sind eine Sackgasse, wenn man Lautstärke will.** Eigene Töne
  zu synthetisieren war weniger Aufwand als gedacht und löst das Problem an
  der Wurzel.

---

### 2026-07-15 · v12 UI-Revert auf v7 + Beta-Label + V1-Checklist

**Was diese Woche passiert ist:**

- **v11 Bold Sports-App hat sich als „zu cluttered" herausgestellt** — 88pt Hero-Streak, Glow-Progress, Mesh-Background. Komplett-Revert auf v7 Glass-Card-Layout (das ist die Variante die auf dem iPhone schon gefallen hat, vor Build 34aaa2a).
- 4 Files via `git checkout 02ba3df --` restored: `TodayView` / `HistoryView` / `AchievementsView` / `WaterTrackerCard`.
- **Darkmode-Schutz erhalten**: LinearGradient-Background in den 3 Views durch `DynamicBackground()` ersetzt, mode-aware `LiquidGlass` beibehalten — sonst wäre der matschige Indigo-Gradient zurück.
- **Versionierung:** `MARKETING_VERSION` 1.0 → **0.9.0** (1.0 für V1-Submit reserviert), `CURRENT_PROJECT_VERSION` 1 → 2. Settings-Footer zeigt jetzt „Creatime v0.9.0 (Beta)".
- **Beta-Label bewusst minimal**: nur im Settings-Footer, sonst nirgends. Wer Beta testet, schaut eh in die Settings.
- **V1 Launch Checklist** in CHANGELOG mit 9 essentiellen Blockern + 3 Post-Launch-Polish-Items.

**Was ich gelernt habe:**

- **„Bold und pumped" ≠ „schön"** für eine persönliche Habit-Tracker-App. Mein Publikum will Konsistenz, keinen Fitness-Coach-Look. v11 wirkte wie ein Dashboard für ein Supplement-Branding, nicht wie mein eigener Tracker.
- **Layout-Density wichtiger als Style-Pushes.** v11 hatte zu viele Cards + zu große Hero-Zahlen + doppelte Inhalte zwischen TodayView und HistoryView = cluttered. v7's 22pt-Spacing mit kompakteren Hero-Werten hat mehr Atmung.
- **Subtile Beta-Kennzeichnung > aufdringliche Watermarks.** Watermarks im Hero-Bereich wären für eigene Tests störend. Footer-only ist die richtige Position.
- **DRY-Discipline zahlt sich bei Bugfixes aus** — derselbe `LinearGradient`-Stub in 4 Files, ein Helper, ein Commit, alle dunkel-mode-safe.

---

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
| **App-Version**                 | v0.9.0 (Beta-pre-V1, intern v12)                      |
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
