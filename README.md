# ✈ NOR AIRSPACE — Sanntids Flytrafikk over Norge

Et interaktivt kart som viser live flytrafikk over norsk luftrom. Ingen backend, ingen build-steg, ingen API-nøkler — åpne `index.html` i nettleseren og det bare fungerer.

🌍 **Live:** [http://nor-airspace-hasqad.s3-website-us-east-1.amazonaws.com](http://nor-airspace-hasqad.s3-website-us-east-1.amazonaws.com)

---

## ✨ Funksjoner

- 🗺️ **Live radarkart** med mørk ATC-estetikk
- ✈️ **Fly-ikoner** roterer etter faktisk kurs og skalerer etter flytype (tunge fly = større ikon)
- 🏷️ **Flyselskap og flytype** — vises i tooltip, detaljpanel og sidefelt
- 📊 **Statistikk-header** — totalt, i luften, på bakken, antall nasjoner
- 🖱️ **Klikk på fly** for detaljpanel (flyselskap, flytype, høyde, hastighet, kurs, squawk, koordinater)
- 📋 **Sidefelt** med liste over alle fly, sortert etter høyde
- 🔄 **Auto-refresh** hvert 30. sekund med nedtellingsbar

---

## 🏗️ Infrastruktur

Prosjektet bruker AWS og GitHub Actions for hosting og datahenting.

```
GitHub Actions (hvert minutt)
    └── Henter flydata fra OpenSky Network API
        └── Laster opp data.json til S3

Nettleser
    └── Henter index.html fra S3
        └── Henter data.json fra S3 (oppdateres hvert minutt)
```

### AWS S3
- Statisk nettstedshosting av `index.html`
- Lagrer `data.json` med siste flydata
- Bucket: `nor-airspace-hasqad` (region: `us-east-1`)

### GitHub Actions
- Workflow: `.github/workflows/fetch-data.yml`
- Kjører hvert minutt (`cron: '* * * * *'`)
- Henter fra [OpenSky Network API](https://opensky-network.org/) og laster opp til S3
- Krever tre repository secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `S3_BUCKET`

### Automatisk deploy
- Workflow: `.github/workflows/deploy.yml`
- Deployer `index.html` til S3 automatisk ved hver push til `master`

---

## 🌐 Datakilde

Flydata hentes fra [OpenSky Network](https://opensky-network.org/) — **gratis og uten API-nøkkel**.

Dekker norsk luftrom: `57°N–72°N`, `4°E–32°E`.

---

## 🛠️ Teknologi

| Teknologi | Bruk |
|-----------|------|
| [Leaflet.js](https://leafletjs.com/) v1.9.4 | Kartvisning |
| [OpenStreetMap](https://www.openstreetmap.org/) | Kartfliser |
| AWS S3 | Hosting + datalagring |
| GitHub Actions | Automatisk datahenting og deploy |
| Vanilla HTML/CSS/JS | Ingen build-steg nødvendig |

---

## 🚀 Kjør lokalt

```bash
git clone https://github.com/hasqad/nor-airspace.git
cd nor-airspace
python3 -m http.server 8080
```

Åpne [http://localhost:8080](http://localhost:8080). Siden henter da `data.json` fra S3 direkte.

---

## 🗂️ Struktur

```
nor-airspace/
├── index.html                         # Hele applikasjonen
├── proxy/
│   └── index.mjs                      # AWS Lambda proxy (ikke i bruk)
├── .github/
│   └── workflows/
│       ├── deploy.yml                 # Deploy index.html til S3 på push
│       └── fetch-data.yml             # Henter flydata til S3 hvert minutt
├── aws-setup.sh                       # Engangs-script for AWS-oppsett
├── deploy-proxy.sh                    # Engangs-script for Lambda-oppsett
├── README.md
├── LICENSE
└── .gitignore
```

---

## ⚠️ Feilsøking

| Problem | Løsning |
|---------|---------|
| Ingen fly vises | Sjekk at GitHub Actions kjører under Actions-fanen |
| Actions feiler | Verifiser at `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `S3_BUCKET` er satt som secrets |
| `Failed to fetch` | Åpne via lokal server i stedet for `file://` |

---

## 📄 Lisens

MIT © 2025