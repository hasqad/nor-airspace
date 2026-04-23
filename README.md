# ✈ NOR AIRSPACE — Sanntids Flytrafikk over Norge

Et interaktivt kart som viser live flytrafikk over Norge, hentet direkte fra [OpenSky Network API](https://opensky-network.org/). Ingen backend, ingen build-steg — åpne `index.html` i nettleseren og det bare fungerer.

![Screenshot](screenshot.png)

---

## 🚀 Kom i gang

### Alternativ 1 — Åpne direkte
```bash
git clone https://github.com/DITT-BRUKERNAVN/nor-airspace.git
cd nor-airspace
# Åpne index.html i nettleseren din
open index.html        # macOS
xdg-open index.html    # Linux
start index.html       # Windows
```

### Alternativ 2 — Kjør med lokal server (anbefalt, unngår CORS-problemer)
```bash
# Python
python3 -m http.server 8080

# Node.js (npx)
npx serve .

# VS Code: bruk Live Server-extension
```
Åpne deretter `http://localhost:8080` i nettleseren.

---

## ✨ Funksjoner

- 🗺️ **Live kart** med mørk radar/ATC-estetikk
- ✈️ **Fly-ikoner** roterer etter faktisk kurs
- 📊 **Statistikk-header** — totalt, i luften, på bakken, antall nasjoner
- 🖱️ **Klikk på fly** for detaljpanel (høyde, hastighet, kurs, squawk, koordinater)
- 📋 **Sidefelt** med liste over alle fly, sortert etter høyde
- 🔄 **Auto-refresh** hvert 30. sekund med nedtellingsbar
- 🔁 **CORS-proxy fallback** — prøver direktekobling først, faller tilbake på proxy ved behov
- ❌ **Feilvisning** direkte på kartet med presis feilmelding

---

## 🗂️ Prosjektstruktur

```
nor-airspace/
├── index.html       # Hele applikasjonen (én fil, ingen dependencies)
├── README.md        # Denne filen
├── .gitignore       # Standard web-.gitignore
└── LICENSE          # MIT
```

---

## 🌐 API

Bruker [OpenSky Network REST API](https://openskynetwork.github.io/opensky-api/rest.html) — **gratis og uten API-nøkkel**.

**Endepunkt:**
```
GET https://opensky-network.org/api/states/all?lamin=57&lomin=4&lamax=72&lomax=32
```

Dekker norsk luftrom: `57°N–72°N`, `4°E–32°E`.

### Rate-limits (anonym)
| Type | Grense |
|------|--------|
| Requests per dag | ~400 |
| Oppdateringsintervall | maks hvert 10. sek |
| Dataforsinkelse | 5–10 sekunder |

For høyere grenser, opprett gratis konto på [opensky-network.org](https://opensky-network.org/index.php?option=com_users&view=registration) og legg inn credentials i `index.html`:

```javascript
// Bytt ut DIRECT_URL i index.html med:
const DIRECT_URL = 'https://BRUKERNAVN:PASSORD@opensky-network.org/api/states/all?lamin=57&lomin=4&lamax=72&lomax=32';
```

---

## 🛠️ Teknologi

| Teknologi | Bruk |
|-----------|------|
| [Leaflet.js](https://leafletjs.com/) v1.9.4 | Kartvisning |
| [OpenStreetMap](https://www.openstreetmap.org/) | Kartfliser (invertert + fargefiltrert) |
| [OpenSky Network API](https://opensky-network.org/) | Flydata i sanntid |
| [corsproxy.io](https://corsproxy.io/) | CORS-proxy fallback |
| Vanilla HTML/CSS/JS | Ingen build-steg nødvendig |

---

## ⚠️ Feilsøking

| Problem | Løsning |
|---------|---------|
| Ingen fly vises | Sjekk DevTools Console (F12) for feilmelding |
| `HTTP 429` | Rate-limit nådd — vent noen minutter |
| `Failed to fetch` | Åpne via lokal server i stedet for `file://` |
| Proxy feiler også | OpenSky API kan være nede, sjekk [status](https://opensky-network.org/) |

---

## 📄 Lisens

MIT © 2025
