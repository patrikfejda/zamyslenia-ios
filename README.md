# Zamyslenia

iOS aplikácia s denným ranným a večerným zamyslením. Offline-first — texty sa stiahnu raz cez GitHub raw URL, ďalej funguje bez internetu.

Žiadny backend. Obsah žije v tomto repe ako Markdown + YAML; appka si ho synchronizuje cez `manifest.json`.

## Štruktúra

```
.
├── ios/                              # SwiftUI aplikácia (iOS 17+)
│   └── Zamyslenia/
├── content/                          # Zdrojový obsah (servuje sa cez GitHub raw)
│   ├── manifest.json                 # generované, nikdy needituj ručne
│   └── days/
│       └── YYYY/MM/DD.md             # jeden súbor = jeden deň
├── scripts/
│   └── generate-manifest.py
├── Inspiracia/                       # screenshoty z pôvodnej appky + opis
└── README.md
```

## Ako to funguje

1. **Zdroj dát.** Každý kalendárny deň má jeden súbor `content/days/YYYY/MM/DD.md` s YAML frontmatter (`date`, `feast`, `season`, `scripture_ref`, `thought_author`) a presne 8 sekciami (4 ranné, 4 večerné).
2. **Manifest.** `scripts/generate-manifest.py` prejde `content/days/` a vyrobí `content/manifest.json` — zoznam dní so SHA-256 a veľkosťou. App vidí len cez manifest.
3. **App.** Pri spustení stiahne `manifest.json`, porovná hashe s lokálnou kópiou a stiahne len zmenené dni. Všetko ukladá do `Application Support/ZamysleniaContent/` → ďalej funguje offline.

## Logický deň (dôležité)

Pretože večerná modlitba sa často číta aj po polnoci, appka **neprepína na nasledujúci deň o 00:00**. Logický deň:

- **04:00–14:59** → ráno aktuálneho kalendárneho dňa
- **15:00–03:59** → večer aktuálneho kalendárneho dňa (po polnoci stále včerajšieho)

Používateľ môže režim kedykoľvek manuálne prepnúť v headeri.

## Formát súboru na deň

```markdown
---
date: 2026-05-22
feast: null
season: easter
scripture_ref: Jn 21,15-19
thought_author: sv. Bernard z Clairvaux
---

## morning.prayer
Pane Ježišu, ty si sa priblížil k emauzským učeníkom...

## morning.scripture
Keď sa Ježiš zjavil svojim učeníkom...

## morning.comment
Sú to práve zamilovaní, ktorí sa niekedy...

## morning.thought
„Ak miluješ, pasieš; ak pasieš bez lásky, nič si nedosiahol."

## evening.prayer
V mene Otca i Syna i Ducha Svätého...

## evening.examination
Pane, dnes som prežil tento deň...

## evening.psalm
ŽALM 97
¹ Pán kraľuje, jasaj, zem...

## evening.word
V mesiaci máj je dobré myslieť viac na Máriu...
```

## Setup obsahu

```bash
# 1. Pridáš/upravíš deň v content/days/YYYY/MM/DD.md
$ vim content/days/2026/05/22.md

# 2. Pregeneruješ manifest
$ python3 scripts/generate-manifest.py

# 3. Commit + push
$ git add content/
$ git commit -m "Add 2026-05-22"
$ git push
```

Manifest sa **nesmie** editovať ručne.

## Setup iOS appky

1. Otvor `ios/Zamyslenia.xcodeproj` v Xcode 16+.
2. V `Signing & Capabilities` priraď svoj Team a `Bundle Identifier`.
3. Pri prvom spustení v Nastaveniach vlož **Content URL** — URL `manifest.json`:
   ```
   https://raw.githubusercontent.com/<USER>/zamyslenia-ios/main/content/manifest.json
   ```
4. Stlač *Aktualizovať texty* — stiahne obsah a od tohto momentu funguje offline.

## Funkcie

- Ranný a večerný režim s automatickým výberom podľa logického dňa
- Vertikálny scroll cez všetky sekcie dňa
- Navigácia po dňoch šípkami + kalendárna história
- Záložky a zdieľanie/kopírovanie textov
- Home screen widget (úryvok dňa)
- Premium devotional vizuál: sépiový denný + tmavý nočný režim, serifová typografia
- Plne offline po prvej synchronizácii
