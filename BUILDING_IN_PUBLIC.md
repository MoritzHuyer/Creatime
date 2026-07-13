# 🌍 BUILDING IN PUBLIC — Audience-Growth-Playbook

> Sub-File zu [`./DEVLOG.md`](./DEVLOG.md) — dort das Journal, hier die Strategie.
> Wie ich Creatime von „Solo-Side-Project" zu „etwas mit echter Audience" bringe.

---

## Grundprinzip

**Sichtbarkeit ≠ Marketing.** Ich baue keine Anzeigen, sondern sorge dafür, dass
Leute, die nach meinen Themen suchen, mich finden können:

1. **Such-Indienz:** Wer nach „creatine tracker iOS" / „habit streak tracker" googelt, findet mich irgendwann.
2. **Community-Lift:** Wer in relevanten Subreddits/Foren unterwegs ist, sieht mich.
3. **Peer-Trust:** Wer meinen Code auf GitHub sieht, erkennt: „das ist ein ernsthaftes Projekt, kein Schüler-Hack."

Jeweils **kostenlos** und **langfristig wirksamer** als Paid-Ads.

---

## Channel-Liste (Priorisiert nach ROI für Indie-iOS-Devs)

### Tier 1 — Direkt-Audience (kostenlos, viel Impact)

| Plattform                          | Was posten                                                                  | Frequenz       |
| ---------------------------------- | --------------------------------------------------------------------------- | -------------- |
| **Reddit r/creatine**              | Tool-Showcase Posts („Hi, ich hab einen Creatine-Tracker gebaut")            | 1×/Monat       |
| **Reddit r/iOSProgramming**        | Tech-Beiträge mit Code-Snippet („Building habit tracker with @Observable") | 1×/Monat       |
| **Reddit r/swiftui**               | Konkrete iOS-17-Beispiele aus Creatime                                        | 2×/Monat       |
| **Reddit r/fitness_de** (DE-Markt) | „Suche Beta-Tester für eine Kreatin-Routine-App"                             | 1×/Quartal     |
| **Hacker News (Show HN)**          | Bei echten Meilensteinen (Open-Source-Tag, v1.0 Launch)                      | 2×/Jahr        |
| **Dev.to**                         | Mittellange Artikel mit Code-Erklärungen                                     | 1-2×/Monat     |

### Tier 2 — Langsam-Aufbau

| Plattform                  | Was posten                                            | Frequenz        |
| -------------------------- | ----------------------------------------------------- | --------------- |
| **X (Twitter) #buildinpublic** | Mini-Updates mit Screenshot, was diese Woche fertig wurde | 2-3×/Woche |
| **YouTube-Shorts**         | 30-Sek-Clips: Bug-Fix / neues Feature / Live-Build    | 2-3×/Monat      |
| **Mastodon (Indie-Dev)**   | Link zu DEVLOG-Einträgen                              | 1×/Woche        |

### Tier 3 — Wenn Zeit und Lust da ist

- **Newsletter** (Substack / Ghost / self-hosted mit Ghost)
- **Discord Server** für Beta-Tester
- **TikTok** (Short-Form mit Face — ich mach das nur, wenn ich mich dabei wohl fühle)

---

## Wochen-Checkliste (~3 Stunden, jeden Sonntag)

- [ ] DEVLOG-Eintrag schreiben (was ist diese Woche passiert?)
- [ ] GitHub Issues durchgehen — auf User-Feedback reagieren
- [ ] Reddit-Check — Erwähnungen von Creatime? Antworten?
- [ ] 1-2 Posts / Snippets auf X / Reddit / Dev.to
- [ ] README + Screenshots updaten, falls neue Features

---

## Monats-Checkliste (~6 Stunden, jeden Ersten)

- [ ] YouTube-Short (z. B. „Wie ich meinen Streak 30 Tage gehalten habe")
- [ ] Demo-Video aufnehmen + in README einbinden
- [ ] Major-Feature in DEVLOG ankündigen
- [ ] Marketing-Screenshot-Set aus Simulator (für späteren Launch vorbereiten)
- [ ] Sponsoring-Setup aktualisieren (FUNDING.yml, falls Status geändert)
- [ ] 1× ins öffentliche Forum posten (Showcase-Thread auf r/iOSProgramming o. ä.)

---

## Quartals-Checkliste (~15 Stunden, jedes Quartal)

- [ ] Roadmap-Update in DEVLOG.md schreiben
- [ ] „Mit-Macher"-Aufruf („Wer will Beta-Tester sein? — Apply-Form")
- [ ] Performance-Review der App (Cold-Start-Time, Memory-Footprint)
- [ ] iOS-Version-Bump checken (Apple bringt jährlich neue SDKs — Chancen nutzen)

---

## Was ich NICHT mache

- ❌ **Twitter-Spam** — kein 5× täglich „working on……". Leser merken das.
- ❌ **Anzeigen kaufen** — erst beim echten Launch, mit echtem Budget.
- ❌ **Open-Source-Theater** — kein „JETZT KOSTENLOS!" wenn ich nicht stable bin.
- ❌ **Über-Promising** — Features ankündigen, dann nicht liefern. Lieber weniger versprechen.
- ❌ **Clickbait-Demos** — keine „Du wirst nicht glauben was passiert ist"-YouTube-Thumbnails.
- ❌ **FOMO-Marketing** — kein „Limited Launch!" wenn ich eigentlich unlimitiert bin.

---

## Launch-Vorbereitung (für später, wenn ich 18 + €99 habe)

### Hard-Blocker (ohne diese kein App Store)

- [ ] Apple Developer Account aufsetzen
- [ ] App Store Connect Listing vorbereiten
- [ ] Privacy Nutrition Labels ausfüllen (was sammle ich, was nicht?)
- [ ] Privacy Policy + Support URL hosten (GitHub Pages free)
- [ ] `PrivacyInfo.xcprivacy` einbauen (Pflicht seit Mai 2024, sonst REJECTED)

### Marketing-Material

- [ ] Screenshots für 6.7" / 6.1" / 4.7" (DE + EN, je 3-8 Stück)
- [ ] App-Preview-Video (15-30s, ohne Voice-Over, Glass-Hero-Shots)
- [ ] App-Beschreibung DE + EN (je 4000 Zeichen)
- [ ] Press-Kit (Logo + Screenshots + Description)

### Distribution-Day-1

- [ ] Product-Hunt-Launch planen (Vorbereitungs-Thread 2 Wochen vorher)
- [ ] Hacker News Launch-Day-Vorbereitung (Show HN-Post-Text)
- [ ] Reddit Launch-Day-Posts in 5 Subreddits (gesprächig, ehrlich, kein Spam)
- [ ] Persönliches Netzwerk („Hey, mein Side-Project ist live — wenn du es testest, freu ich mich über Feedback")

---

## Erfolgs-Metriken (realistisch für Indie-iOS, ohne Marketing-Budget)

> ⚠️ **Wichtig:** Diese Targets sind **aspirational best-case**, keine Garantien.
> Baseline heute (2026-07-13): **~0 GitHub-Stars**, 0 Reddit-Reach, 0 Newsletter-Abonnent:innen.
> Die Zahlen sind Zielmarken, keine Versprechen — und sollten NICHT als Verpflichtung
> gegen mich selbst gelesen werden. Wenn ich nach 3 Monaten 8 statt 30 Stars habe,
> ist das trotzdem Wert, den ich gefeiert haben will.

| Metrik                                  | Baseline (heute) | Ziel Monat 3 | Ziel Monat 6 |
| --------------------------------------- | ------------ | ------------ |
| GitHub Stars                            | ~0           | 30           | 100          |
| Reddit-Posts Views (Ø)                  | 0            | 500          | 2.000        |
| DEVLOG / Blog-Abonnent:innen            | 0            | 50           | 200          |
| Hacker News Show-Pageviews              | 0            | —            | 5.000        |
| (Nach Launch) App-Store-Downloads / Monat | 0           | —            | 1.000        |

---

## Bonus-Tipp: Was ich von erfolgreichen Indie-Devs gelernt habe

- **Pieter Levels** — Built in Public, radikal ehrlich über Revenue
- **Levels.io / Nomad List** — gamifizierte Audience-Building-Playbooks
- **DHH / 37signals** — strong opinions, loosely held (gilt für Code + Marketing)
- **Marc Lou** — Ship fast, talk about shipping (YouTube-Short-Form)
- **Linus Lee / Otherside** — Devlog als Indie-Projekt-Inkubator

Die Lesson aus allen: **„Just ship. Talk about what you shipped. Repeat."**

---

🦬 Non scholae sed vitae discimus — wir lernen für das Leben, nicht für die Schule.
