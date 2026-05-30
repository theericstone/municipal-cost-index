# Massachusetts Core Services Municipal Cost Index (MCI)
## Planning & Methodology — Draft v0.1

*Prepared 2026-05-30 in response to Brookline 2026 Annual Town Meeting Warrant Article 22.*

---

## 0. The mandate (what Article 22 actually asks for)

Article 22 began as a resolution urging the state to modernize Proposition 2½ and was
amended — after Advisory Committee discussion (returned to subcommittee, then adopted
15-0-0) and a unanimous Select Board favorable recommendation — into a concrete,
analytical charge:

> *Evaluate the utility and possibility of constructing a **Core Services Municipal Cost
> Index** … incorporating but not limited to employee compensation (salaries, benefits,
> steps, lanes, vacation), capital improvements (road repair, facilities construction),
> utilities, and other significant costs … that could be **updated on a regular basis** for use
> by Brookline, other municipalities in Massachusetts, and by Massachusetts executive and
> legislative officials in establishing fiscal policy.*

The Select Board added the decisive scoping constraint: a single-town index "will unlikely
sway the state legislature." A **regional or statewide "representative basket of
communities"** is required. Coordinate with **MAPC**; enlist **MMA** and the **Collins
Center** (UMass Boston).

### Design goals (from the user + the article)
1. **Defensible** — reproducible from public data; no black-box weights.
2. **Reflects municipal operational costs** — purpose-built basket, not CPI.
3. **Easily explainable** — a lay reader, a skeptic, and a legislator each understand it.
4. **Face validity** — the number "looks right" and tracks reality.
5. **Accepted by skeptics, legislators, the public** — survives the argument that Prop 2½ is
   healthy fiscal discipline.
6. **Self-updating** — refreshes on a schedule with no manual intervention.
7. **Scales to all 351 MA municipalities** — the draft UI starts with Brookline + peers, but
   every data source must support the full state.

---

## 1. What we are building (and what we are deliberately not)

**The article conflates two different measures.** We separate them, with the user's
direction (input-price index first, expenditure reconciliation as a second layer):

### Layer A — the headline Municipal Cost Index (input-price index)
A CPI-style index that tracks the **price** of a **fixed basket of municipal inputs** over
time. It answers the Prop 2½ question directly: *"How fast does the cost of buying the same
bundle of municipal services rise, versus the 2.5% nominal levy cap?"*

This is what "Municipal Cost Index" means in the field. It does **not** measure how much a
town spends; it measures what a town must pay to buy a constant bundle. That distinction is
the heart of its defensibility — a town cannot make the index go down by cutting services,
because it is a *price* index, not a *spending* index.

### Layer B — the actual-expenditure reconciliation overlay (the peer benchmark)
For each municipality, compare **actual per-capita expenditure growth** (from DLS Schedule
A) against the **MCI-implied cost growth** for the same period. The gap is interpretable:

| Actual growth vs. MCI | Interpretation |
|---|---|
| Below MCI | Absorbing cost pressure / deferring (possible service erosion or efficiency) |
| ≈ MCI | Holding service level at market cost |
| Above MCI | Expanding service, or cost growth above market |

This is a far more defensible "how do municipalities manage costs relative to peers" measure
than a raw spending ranking, because it benchmarks each town against an objective cost
yardstick rather than against each other's raw budgets (which differ by service mix, wealth,
and demographics). It directly answers the AC's "benchmark to evaluate how municipalities
manage costs relative to peers" while resisting the "you're just rewarding low-spending
towns" critique.

### Explicitly out of scope (for the draft)
- We are **not** recommending a specific Prop 2½ reform. The article is non-binding and
  analytical; the index is evidence, not advocacy.
- We are **not** baking quantity/seniority drift (step/lane progression) into the headline
  price index — see §3.3. It appears as a clearly-labeled separate overlay.

---

## 2. Methodology

### 2.1 Formula — fixed-weight Laspeyres index of price relatives

For year *t* relative to base year 0:

```
MCI_t = 100 × Σ_i  w_i × (P_i,t / P_i,0)
```

- `w_i` — fixed expenditure-share weight of component *i* in the base-year MA municipal
  budget (Σ w_i = 1), derived from **DLS Schedule A**.
- `P_i,t / P_i,0` — the price relative for component *i*, its underlying public price series
  indexed to the base year.

**Why Laspeyres, not Fisher/chained?** Fisher is statistically superior (removes
substitution bias, passes time/factor-reversal tests; used by BEA and FHWA NHCCI). But its
whole-index transparency cost is fatal for *this* project: a fixed basket is intuitive ("the
same shopping list, repriced each year"), reproducible, and resistant to "you tweaked the
weights to get the answer you wanted." This matches the strongest sector precedents — the CPI,
the BLS ECI, the Higher Education Price Index (HEPI), and especially the **Illinois Municipal
Price Index** (our closest analogue: a public, documented, expenditure-share-weighted
Laspeyres index built from real municipal budgets, maintained by an independent university
center). We use Fisher only *inside* the road sub-component, because its source series (NHCCI)
is already Fisher-based.

### 2.2 Base year and reweighting cadence (anti-manipulation rules)
- **Base year:** a recent, non-anomalous year (avoid recession troughs and the COVID-
  distorted years). Published with the reason it was chosen.
- **Reweighting:** on a **fixed published schedule (~every 5 years)**, mirroring ECI's
  ~10-year and HEPI's periodic refreshes. Reweighting is a *rule*, not a discretionary act.
  When weights are refreshed, **retroactively recompute history** (as the Illinois MPI does)
  so the series has no artificial jumps.

### 2.3 The "personnel ≈ 75%" load-bearing fact
Roughly three-quarters of municipal spending is personnel. This is *why* a bespoke index is
justified (households and businesses are far less labor-intensive, so CPI/PPI systematically
**understate** municipal cost growth) and why the **BLS Employment Cost Index — State & Local
Government** series is the single most important building block.

---

## 3. The basket — components → public price series

Weights below are **illustrative defaults** anchored on the ~75% personnel share and typical
municipal operating shares. **They must be replaced with weights computed from MA DLS
Schedule A before publication.** The mapping uses only public, reproducible series.

| Article 22 component | Sub-component | Price series (relative) | Source | Rough weight |
|---|---|---|---|---|
| **Employee compensation** | Wages & salaries (incl. teachers) | ECI — State & local govt, wages (`ECIGVTWAG`) | FRED/BLS | ~37% |
| | Health & insurance benefits | ECI — S&L govt, benefits (`ECIGVTBEN`); cross-check MA GIC | FRED/BLS | ~13% |
| | Retirement / pensions / OPEB | ECI — S&L retirement component; PERAC actuarial (context) | FRED/BLS | ~9% |
| **Schools** | Special education (out-of-district tuition) | MA DESE per-pupil & OOD tuition rates (all districts); state OOD price-setting | DESE | ~5% |
| | Student transportation | MA DESE transportation expenditure; PPI/CPI transport + diesel | DESE / BLS | ~3% |
| **Utilities** | Electricity, gas, fuel | EIA MA retail electricity & natural gas; CPI utilities; PPI diesel | EIA / BLS | ~6% |
| **Capital — roads** | Road/highway repair | National Highway Construction Cost Index (NHCCI), Fisher | FHWA (Socrata) | ~6% |
| **Capital — facilities** | Building construction | PPI construction inputs (public); ENR BCI / RSMeans if licensed | BLS | ~6% |
| **Other significant** | Vehicles & equipment | PPI — motor vehicles / heavy equipment | BLS | ~3% |
| | Supplies & materials | PPI — office supplies, industrial commodities | BLS | ~4% |
| | Contracted/professional services | CPI/PPI services; ECI services proxy | BLS | ~8% |
| **Total** | | | | **100%** |

> **Schools matter to the headline.** In most MA communities schools are roughly half the
> budget, and their fastest-rising lines — **special education (especially out-of-district
> placements/tuition) and student transportation** — routinely outpace general inflation.
> MA DESE publishes per-pupil expenditure (by function, incl. SPED and transportation) and
> out-of-district tuition data for **all districts statewide**, making it the schools-side
> analogue to the DLS Databank. Teacher salaries are captured in the compensation block.

### 3.3 Steps/lanes/vacation — a defensibility subtlety
The ECI is deliberately built to hold employment mix constant and measure the *price* of
labor. Automatic step/lane and longevity increases are partly *price of a given job* and
partly *quantity/seniority drift*. To keep the headline an honest **input-price** index, the
core MCI tracks the ECI wage *price*; step/lane/COLA escalation from MA collective-bargaining
settlements appears as a **clearly-labeled separate "contractual escalator" overlay**, not
baked into the headline. Documenting this choice pre-empts the "this isn't really a price
index" critique.

---

## 4. Data sources (vetted) — see `DATA_SOURCES.md` for full detail

**Two hard requirements:** (1) municipal-finance data must cover **all 351** MA
municipalities; (2) every source must be reachable **programmatically** for auto-refresh.

| Layer | Source | Access | R tool | Cadence |
|---|---|---|---|---|
| Local actuals (all 351) | DLS Municipal Databank — Schedule A, Cherry Sheet, Levy/Prop 2½ | scripted Excel/CSV download (**no API**) | `httr2` + `readxl`/`fread` | annual |
| Muni boundaries | MassGIS `TOWNSSURVEY_POLYM` (351 polygons) | ArcGIS REST / GeoJSON | `sf` | static |
| National basket (wages, benefits, deflators, CPI) | **FRED** (`ECIGVTCOM/WAG/BEN`, `CUURA103SA0`, BEA) | REST API | **`fredr`** | quarterly/monthly |
| County local-govt wages by NAICS | BLS QCEW open data CSV | CSV-by-FIPS | `httr2`/direct | quarterly |
| Energy/utilities (MA) | EIA API v2 | REST | `eia` | monthly |
| Construction cost | NHCCI (`data.transportation.gov/resource/r94d-n4f9.json`) | Socrata JSON | `RSocrata`/`httr2` | quarterly |

### Known gaps (disclose these — they are part of being defensible)
1. **DLS has no API** — the only all-351 finance source ships Excel/CSV report files; we
   maintain a small scheduled downloader and re-validate file URLs each cycle.
2. **Census govt-finance API is state-level only** — cannot supply per-municipality MA data;
   the 5-year Census of Governments public-use files are download-only and not annual. DLS
   remains the sole all-351 annual source.
3. **GIC health premiums** and **PERAC pensions** are **PDF-only** (no API). Used as
   context/cross-checks; automating them requires PDF scraping (deferred).
4. **ENR BCI / RSMeans** are proprietary; the public PPI construction series is the
   defensible default for the facilities component.

---

## 5. Architecture (self-updating, reproducible)

```
            GitHub Actions (cron: weekly)  ── secrets: FRED/BLS/CENSUS/EIA keys
                          │
                          ▼
   ┌──────────────  targets pipeline (_targets.R)  ──────────────┐
   │  fredr │ eia │ httr2(QCEW) │ RSocrata(NHCCI) │ DLS download  │ RAW FETCH
   │                          ▼                                   │
   │             clean / normalize  (fct_clean.R)                 │
   │                          ▼                                   │
   │     compute_mci()  (fct_index.R)  ◀── testthat unit tests    │
   │                          ▼                                   │
   │     pin_write(board, "mci_snapshot", versioned = TRUE)       │
   └──────────────────────────┬───────────────────────────────────┘
                              ▼
            pins board (versioned, auditable snapshots
            + provenance: run ts, git SHA, renv.lock hash)
                              │  pin_read()  — cached, NO live API calls in-session
                              ▼
            golem-style Shiny app (R/ = package)
            bslib shell + page_navbar
            ├─ mod_overview     headline index vs 2.5% cap & CPI
            ├─ mod_components    basket drill-down + contributions
            ├─ mod_benchmark     actual-vs-MCI reconciliation (peer layer)
            ├─ mod_map           leaflet choropleth (MassGIS 351)
            └─ mod_methodology   transparency: sources, weights, formula
```

**Principles.**
- **The Shiny app never calls a live API.** On startup it reads the latest **pinned
  snapshot**. An upstream outage cannot break the dashboard, sessions are fast, and there are
  no rate-limit surprises.
- **All index math is pure functions** (`fct_*`), unit-tested with `testthat` independent of
  Shiny. The modules only display precomputed results.
- **Every published index value is traceable** to a git commit + `renv.lock` + data vintages
  (a provenance JSON travels with each snapshot).
- **No tidyverse.** Data manipulation is `data.table`; tables are `reactable`; charts are
  `plotly`/`echarts4r`/`dygraphs`; file reads are `data.table::fread`/`readxl`.

**Framework:** `golem` (app-as-package) for the production build — gives `DESCRIPTION`-pinned
deps, docs, `R CMD check`, and native testing, the structure an auditor expects. The skeleton
in this repo uses a plain modular layout mirroring golem conventions (`mod_*`, `fct_*`) so it
runs without golem installed and can be golem-ized later.

**Auto-update (shinyapps.io target):** GitHub Actions cron (free, serverless, git-versioned)
restores `renv.lock`, runs `targets::tar_make()`, runs tests, and writes a new versioned
snapshot. shinyapps.io does **not** run scheduled jobs itself, so the snapshot is published
where the deployed app can read it without a manual redeploy — either (a) the app reads a
**`pins::board_url`** pointing at the snapshot the Action commits to the repo (or an S3 board),
fetched at session startup; or (b) the Action calls `rsconnect::deployApp()` to redeploy with
the fresh snapshot bundled. Option (a) is preferred — no redeploy, app always serves the latest
snapshot, and an upstream API outage never breaks the live dashboard. (Note GitHub's 60-day
scheduled-workflow dormancy rule — the per-run commit self-heals it.)

---

## 6. Defensibility checklist (the part that wins the skeptics)

- [ ] Publish the **full basket, every weight, every source-series ID** (the opposite of the
      proprietary American City & County MCI — its black-box weights are exactly the gap we
      fill).
- [ ] Publish the Laspeyres formula and a **worked numerical example**.
- [ ] Use **only public series** so any third party can rebuild the number.
- [ ] Ship a **reproducible script/pipeline** that regenerates the index from raw inputs.
- [ ] Standing **methodology document** with a dated revision log.
- [ ] Weight-update cadence as a **fixed rule** (~5 yr) with retroactive recompute.
- [ ] **Independent review** (academic public-finance center / MMA / DLS) — disclosed.
- [ ] **Sensitivity analysis:** show how the headline moves under alternative weights (70% vs
      75% personnel) and alternative formulas (Laspeyres vs Fisher) — pre-empt "you rigged it."
- [ ] Present the MCI **alongside CPI, the BEA state-&-local deflator, ECI–S&L, and the ACC
      MCI** as external reality checks.
- [ ] **Confidence band / range**, not a bare point estimate; disclose data lags and revisions.
- [ ] Lock component definitions and series IDs in advance; changes require documented
      justification, and the full history is always shown (no cherry-picked endpoints).

---

## 7. Roadmap

**Phase 0 — Research & plan (this document).** ✅
**Phase 1 — Runnable skeleton on sample data.** ◀ delivered alongside this doc. Modular Shiny
app, pure `compute_mci()` in data.table, a deterministic sample snapshot, all five tabs, a
passing test. Lets stakeholders see the shape before any live wiring.
**Phase 2 — Live national basket.** ✅ DONE (and key-free). `R/fct_fetch_real.R` /
`build_real_snapshot()` pull real series: **BLS QCEW** (MA local-gov wages), **BLS CPI/PPI**
(health, utilities, facilities, vehicles, supplies, services), **FHWA NHCCI** (roads). Three
labelled proxies remain (pensions, SPED, transport). Real MCI: 2015–2024, ~3.6%/yr. Cached to
`inst/extdata/mci_snapshot.rds`; refreshed weekly by GitHub Actions. (FRED/EIA optional upgrades
for ECI/MA-energy precision later.)
**Phase 3 — All-351 expenditure layer.** Build the DLS Schedule A downloader/parser; compute
real expenditure-share weights; build the reconciliation overlay; add MassGIS choropleth.
**Phase 4 — Hardening & governance.** `renv` lock, full `testthat` suite, sensitivity tab,
methodology Quarto doc, GitHub Actions cron + `pins`, independent review, MAPC/MMA/Collins
engagement.

---

## 8. Decisions (resolved 2026-05-30)
1. **Base year — user-selectable.** Rather than fix one base year and ask people to trust it,
   the app exposes base year as a global control: the index recomputes live from the published
   formula at whatever base the user picks. This converts the "you cherry-picked the base year"
   critique into a transparency feature. Default base = the earliest available year.
2. **Scope — all 351 municipalities.** Confirmed: the headline index is a *single statewide
   curve* (input prices — ECI, CPI, NHCCI — are national/regional, not per-town), so there is
   no methodological cost to covering the whole state. Per-municipality variation lives only in
   the Layer B reconciliation, and DLS covers all 351. The "peer set" framing is dropped; the
   draft skeleton shows an illustrative subset only because real DLS/MassGIS data loads in
   Phase 3.
3. **Data — free/public only**, with an explicit in-app note (Methodology tab) that deeper or
   higher-resolution data is available for a fee (ENR CCI / RSMeans for facilities;
   municipality-level GIC health-premium and PERAC pension detail) and can be slotted in later
   without changing the formula.
4. **Hosting — shinyapps.io.** See §5 for the auto-update implication.
5. **Governance home — deferred.** Decide later (Town vs. MAPC vs. a university center, per the
   Illinois model).
```
