# ✈ NOR AIRSPACE — Sanntids Flytrafikk over Norge

Et interaktivt kart som viser live flytrafikk over norsk luftrom. Ingen backend, ingen build-steg, ingen API-nøkler — åpne `index.html` i nettleseren og det bare fungerer.

---

## 🚀 Kom i gang

```bash
git clone https://github.com/hasqad/nor-airspace.git
cd nor-airspace
python3 -m http.server 8080
```
Åpne deretter [http://localhost:8080](http://localhost:8080) i nettleseren.

> Du kan også åpne `index.html` direkte, men lokal server anbefales for å unngå CORS-problemer.

---

## ✨ Funksjoner

- 🗺️ **Live radarkart** med mørk ATC-estetikk
- ✈️ **Fly-ikoner** roterer etter faktisk kurs og skalerer etter flytype (tunge fly = større ikon)
- 🏷️ **Flyselskap og flytype** — vises i tooltip, detaljpanel og sidefelt
- 📊 **Statistikk-header** — totalt, i luften, på bakken, antall nasjoner
- 🖱️ **Klikk på fly** for detaljpanel (flyselskap, flytype, høyde, hastighet, kurs, squawk, koordinater)
- 📋 **Sidefelt** med liste over alle fly, sortert etter høyde
- 🔄 **Auto-refresh** hvert 30. sekund med nedtellingsbar
- 🔁 **Automatisk API-fallback** — prøver flere kilder i rekkefølge til én svarer

---

## 🌐 Datakilder

Alt er **gratis og uten API-nøkkel**. Kildene prøves i denne rekkefølgen:

| Prioritet | Kilde | Type |
|-----------|-------|------|
| 1 | [airplanes.live](https://airplanes.live/) | Community ADS-B |
| 2 | [adsb.lol](https://adsb.lol/) | Community ADS-B |
| 3 | [OpenSky Network](https://opensky-network.org/) | Direkte |
| 4 | OpenSky via CORS-proxy | Fallback |

Dekker norsk luftrom: `57°N–72°N`, `4°E–32°E`.

---

## 🛠️ Teknologi

| Teknologi | Bruk |
|-----------|------|
| [Leaflet.js](https://leafletjs.com/) v1.9.4 | Kartvisning |
| [OpenStreetMap](https://www.openstreetmap.org/) | Kartfliser |
| Vanilla HTML/CSS/JS | Ingen build-steg nødvendig |

---

## 🗂️ Struktur

```
nor-airspace/
├── index.html   # Hele applikasjonen (én fil, ingen dependencies)
├── README.md
├── LICENSE      # MIT
└── .gitignore
```

---

## ⚠️ Feilsøking

| Problem | Løsning |
|---------|---------|
| Ingen fly vises | Åpne DevTools (F12 → Console) og se hvilken kilde som feiler |
| `signal is aborted` | Timeout — alle API-er trege, prøv igjen |
| `Failed to fetch` | Åpne via lokal server i stedet for `file://` |

---

## 📄 Lisens

MIT © 2025