# MCI — Vetted Public Data Source Inventory

*All endpoints probed live or verified against official docs, 2026-05-30. Confirm exact DLS
report-file URLs interactively before wiring the scheduler — they are not guaranteed stable.*

> **Headline finding:** `data.mass.gov` is **NOT** a Socrata portal — it is a Next.js content
> site (confirmed: `x-powered-by: Next.js`, returns HTML, no `/api/catalog/v1`). DLS exposes
> **no SODA/REST API**; its data ships as Excel/CSV report downloads. The real MA open-data
> portal is the ArcGIS-based **MassGIS Hub** (`gis.data.mass.gov`), which carries geometry,
> not finance time series.

## Part 1 — Massachusetts municipal finance (must cover all 351 munis)

### DLS Municipal Databank — the irreplaceable all-351 core
- **Feeds:** actual expenditures by function/object (Schedule A), levy capacity & Prop 2½
  (levy limit, ceiling, excess capacity, override/exclusion history), Cherry Sheets, Tax Rate
  Recap. Statutory filings → full universe, not a sample.
- **Access:** **no API.** Pre-built report downloads (Excel/CSV) from the Databank Reports
  collection; custom extracts via `databank@dor.state.ma.us`. Plan: scripted HTTP download +
  parse with `httr2` + `readxl`/`data.table::fread`; re-validate file URLs each refresh.
- **History:** deep (late 1980s/1990s → present, varies by report). **Cadence:** annual (FY).
- **URLs:**
  - Databank: https://www.mass.gov/info-details/division-of-local-services-municipal-databank
  - Reports: https://www.mass.gov/collections/DLS-databank-reports
  - Data analytics: https://www.mass.gov/municipal-databank-data-analytics
  - Revenue & Expenditure (Schedule A): https://www.mass.gov/info-details/revenue-and-expenditure-data
  - Cherry sheets: https://www.mass.gov/info-details/cherry-sheet-state-payment-reports
  - Prop 2½ overrides/exclusions: https://www.mass.gov/info-details/proposition-2-12-overrides-exclusions

### MassGIS / portals
- **`gis.data.mass.gov`** (ArcGIS Hub) — municipal **boundaries** & geospatial; ArcGIS REST /
  GeoJSON via `sf`. Use `TOWNSSURVEY_POLYM` (one polygon per 351 munis, legally authoritative).
  No finance time series. https://www.mass.gov/info-details/massgis-data-municipalities
- **`data.mass.gov`** — content portal, not machine-readable; discovery layer only.

### MA DESE — school cost drivers (all districts statewide)
- **Feeds:** the schools block of the basket — **special education** (incl. out-of-district
  tuition) and **student transportation**, plus per-pupil expenditure by function. Schools are
  ~half of most municipal budgets and SPED/transport are the fastest-rising lines, so this is
  the schools-side analogue to the DLS Databank.
- **Coverage:** all MA districts. **Access:** DESE School & District Profiles data portal —
  downloadable Excel/CSV per-pupil expenditure and statistical reports; out-of-district tuition
  prices are set annually by the state (Operational Services Division). No clean REST API →
  scripted download + parse, like DLS. URLs: https://profiles.doe.mass.edu/ ·
  per-pupil expenditure reports https://www.doe.mass.edu/finance/statistics/ ·
  OOD tuition / Ch.71B pricing via OSD https://www.mass.gov/orgs/operational-services-division

### MAPC DataCommon
- Keyless JSON/GeoJSON API (`datacommon.mapc.org`, endpoints `/datasets/list`, `/tabular/list`,
  `/spatial/list`, `/boundaries/list`); **partial coverage** (often Metro-Boston 101 munis) —
  **not** a substitute for all-351 finance. Useful for context indicators/denominators.
  https://datacommon.mapc.org/ · https://github.com/MAPC/datacommon-io

## Part 2 — National input-price series (the basket)

### FRED — one key covers many series (primary national hub)
- `fredr` (CRAN). Key: free, `FRED_API_KEY` in `.Renviron`. https://sboysel.github.io/fredr/
- Verified series: ECI state & local govt — `ECIGVTCOM` (compensation), `ECIGVTWAG` (wages),
  `ECIGVTBEN` (benefits), quarterly since 2001; CPI Boston-Cambridge-Newton all-items
  `CUURA103SA0` (now monthly); BEA state-&-local deflators discoverable. **Not** in FRED:
  per-muni MA finance, NHCCI component detail.

### BLS Public Data API v2
- `https://api.bls.gov/publicAPI/v2/timeseries/data/`. Free key → 500 req/day, 50 series/req,
  20 yr/req. R: `blscrapeR`/`blsAPI`. Used for ECI, CPI Boston, PPI, QCEW.
- QCEW county local-govt wages by NAICS — verified open-data CSV:
  `https://data.bls.gov/cew/data/api/{YEAR}/{QTR}/area/{FIPS}.csv` (e.g. `25025` Suffolk).
- https://www.bls.gov/developers/ · https://www.bls.gov/regions/northeast/news-release/consumerpriceindex_boston.htm

### BEA — state & local govt consumption deflator
- NIPA Table 3.10.5 / 1.1.9. API key free; R: `bea.R`. National only (no MA-specific
  deflator). https://apps.bea.gov/API/signup/ · https://cran.r-project.org/web/packages/bea.R/

### Census of Governments / Annual Survey of S&L Gov Finances
- **Gap:** timeseries API `api.census.gov/data/timeseries/govsstatefin` is **state-level
  aggregate only** — no individual MA munis. 5-yr CoG public-use microdata is download-only,
  not annual. Not viable for all-351. R: `censusapi`.
  https://www.census.gov/data/developers/data-sets/govsstatefin.html

### EIA — MA electricity & natural gas
- API v2 (`https://api.eia.gov/v2/...`), free key required. R: `eia` (rOpenSci).
  Electricity: `/v2/electricity/retail-sales/data/?facets[stateid][]=MA&data[0]=price`.
  Gas: `/v2/natural-gas/pri/sum/data/`. Monthly, state-level, multi-decade.
  https://www.eia.gov/opendata/ · https://docs.ropensci.org/eia/

### FHWA NHCCI — road/construction cost (Fisher index)
- **Verified Socrata SODA** resource: `https://data.transportation.gov/resource/r94d-n4f9.json`
  (quarterly NHCCI + seasonally adjusted + component contributions, from 2003 Q1). R:
  `RSocrata` or `httr2`+`jsonlite`. App token optional. National only.
  https://www.fhwa.dot.gov/policy/otps/nhcci/

### MA-specific gaps (PDF-only, no API)
- **GIC** health-insurance premiums: PDF benefit-rate guides. https://www.mass.gov/lists/gic-benefit-rates
- **PERAC** pensions: PDF actuarial/annual reports for 104 systems.
  https://www.mass.gov/info-details/perac-reports-studies-and-retirement-system-analyses

## Minimal viable data stack
FRED (`fredr`) as the national hub (ECI/CPI/BEA) + `eia` (MA energy) + NHCCI Socrata
(`RSocrata`/`httr2`) + QCEW CSV (county wages) + DLS Databank Excel downloader (all-351
actuals) + MassGIS `TOWNSSURVEY_POLYM` (boundaries). Keys live in `.Renviron` locally and
GitHub Actions secrets in CI; all clients read `Sys.getenv()` so the same code runs in both.
