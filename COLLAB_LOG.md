# 🤝 Collab-Log — Claude ⇄ FreeBuff

> **Zweck:** Moritz arbeitet abwechselnd mit **Claude** und **FreeBuff** an Creatime.
> Damit sich beide KIs nicht verwirren, trägt hier **jede/r ein, was sie/er geändert hat**,
> bevor die/der andere übernimmt. Vor dem Loslegen: **immer zuerst diese Datei lesen.**

## 📋 Regeln

1. **Neueste Einträge nach OBEN** (direkt unter „Log").
2. Format pro Eintrag: `### <Kurzbeschreibung> — TT.MM.JJ — -Name-` + Stichpunkte, was & warum.
3. Name = `-Claude-` oder `-FreeBuff-`.
4. Wenn du etwas Größeres umbaust: **kurz sagen, welche Dateien** betroffen sind.
5. Diese Datei nach dem Eintrag committen + pushen, damit die/der andere sie sieht.

---

## 🧭 Aktueller Stand (Stand: 18.07.26)

- **Ein Repo / ein Ordner:** `/Users/moritz/Desktop/Creatime` → `github.com/MoritzHuyer/Creatime` (Branch `main`).
  Das frühere `Creatime-V2`-Repo ist **archiviert** (schreibgeschützt, nur Backup). Nicht mehr benutzen.
- **Stack:** SwiftUI, iOS 17+, `@Observable`. App-Target `Creatime` + `CreatimeWidget` (Extension) + `CreatimeTests`.
  App Group `group.com.moritz.Creatime` (`SharedDefaults.store`) teilt Daten mit dem Widget.
- **Basis:** v13 „Airy-Layout" (heller Look, Indigo-Theme). NICHT die alte v16-„Claude Design"-UI.
- **Build/Test:**
  ```bash
  xcodebuild -project Creatime.xcodeproj -scheme Creatime \
    -sdk iphonesimulator -configuration Debug build CODE_SIGNING_ALLOWED=NO
  ```
- **Wichtige Stores:** `CreatineStore` (Streak/Sättigung/Milestones), `WaterStore`, `SupplementStore`,
  `PhotoStreakStore`, `BuddySystem`, `SoundsManager`, `ThemeManager`.
- **Sprache:** komplett Deutsch. App erzwingt `.environment(\.locale, de_DE)` in `CreatimeApp.swift`.
  (Englische Lokalisierung ist bewusst noch NICHT umgesetzt — großer Task, siehe Log.)
- **Konventionen:** Karten-Hintergrund = `Color.ctCardSurface` (dark-mode-safe, NICHT `Color(.systemBackground)`).
  Akzentfarbe = `ThemeManager.tint` bzw. `Color.accentColor` (Theme), NICHT System-Blau.

---

## 📓 Log

### Sättigungs-Anzeige + Onboarding-Funnel + Aufräumarbeiten — 18.07.26 — -Claude-

Was ich zuletzt gemacht habe (alles auf `main` gepusht):

- **Kreatin-Sättigung (neu):** `CreatineStore.creatineSaturation` / `daysUntilSaturated` / `isSaturated`
  (28-Tage-Fenster). Neue `SaturationCard` **oben auf dem Fortschritt-Tab** (Ring + %, „Voll in X Tagen").
- **Quiz-Onboarding (neu):** `OnboardingView.swift` komplett neu — 7 Schritte
  (Willkommen → Ziel → Gewicht→Dosis → Training → Erinnerung → Wasserziel → Plan).
  Personalisierte Dosis (`@AppStorage("creatineDoseGrams")`, ~0,03 g/kg, 3–5 g), dezent auf dem Heute-Tab
  unter dem Hauptbutton angezeigt. **Kein Klon** der Konkurrenz „Creatine Today" — eigener Indigo-Look.
- **Einstellungen:** Button „Einführung erneut ansehen" (setzt `hasCompletedOnboarding=false`).
  Erinnerungszeit + Wasserziel-Stepper dort. Supplement-Verwaltung als eigenes Sheet
  (`SupplementManagerSheet`) + 14 Vorlagen. Sound-Auswahl entfernt (immer Gym-Sound).
- **Sounds:** `SoundsManager` erzeugt jetzt weiche, selbst synthetisierte Töne (PCM/AVAudioPlayer,
  `masterVolume`) statt harter System-Sounds. Lautlos-Schalter wird respektiert.
- **Meilenstein-Feiern:** `MilestoneCelebrationOverlay` (Heute-Tab) bei 3/7/14/30/60/100 Tagen.
- **Fortschritt-Tab aufgeräumt:** Insights-Block + Kreatin-Chart raus; nur noch Wasser- (14 Tage) +
  Stimmungs-Chart. Gruppierung: Sättigung → Überblick → Kalender → Trends → Teilen & Community.
- **Widget:** übernimmt Theme-Farbe (via App Group), zeigt Wasser-% + „Ziel erreicht".
- **Dark Mode:** `Color.ctCardSurface` eingeführt (Karten grau statt schwarz).
- **Deutsch-Fix:** Kalender/Wochentage fest deutsch; horizontaler Scroll-Bug behoben.

**Für dich, FreeBuff:** Heute-Tab-Layout ist von Moritz ausdrücklich als „perfekt" abgesegnet —
bitte dort vorsichtig sein. Offene, noch NICHT gebaute Ideen: englische Lokalisierung,
Dosis-Text in der Push-Erinnerung, Sättigung aufs Widget, App-Icon (macht Moritz selbst),
iCloud-Backup. Viel Erfolg! 🙌

<!-- Vorlage für den nächsten Eintrag (kopieren, nach oben über diesen Kommentar setzen):
### <Kurzbeschreibung> — TT.MM.JJ — -FreeBuff-
- ...
-->
