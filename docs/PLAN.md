# Massachusetts Core Services Municipal Cost Index (MCI)
## Planning & Methodology — Draft v0.1

*Prepared 2026-05-30 in response to Brookline 2026 Annual Town Meeting Warrant Article 22.*

---

## 0. What Article 22 asks for

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

### Design goals
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

## 1. What we are building

**The article conflates two different measures.** We separate them, with emphasis on input-price index first, expenditure reconciliation as a second layer used for validation/observation:

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
  budget (Σ w_i = 1). *Target:* derive from DLS Schedule A. *Current build:* documented
  default shares anchored on typical municipal budget composition (see §3).
- `P_i,t / P_i,0` — the price relative for component *i*, its underlying public price series
  indexed to the base year.

**Why Laspeyres, not Fisher/chained?** Fisher is statistically superior (removes
substitution bias, passes time/factor-reversal tests; used by BEA and FHWA NHCCI). But its
whole-index transparency cost is fatal for *this* project: a fixed basket is intuitive ("the
same shopping list, repriced each year"), reproducible, and resistant to "you tweaked the
weights to get the answer you wanted" arguments. This matches the strongest sector precedents — the CPI,
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
**understate** municipal cost growth) and why the local-government compensation series is the
single most important building block. *Current build:* **BLS QCEW** — Massachusetts
local-government average weekly wage (real, statewide, key-free). *Planned refinement:* the
**BLS Employment Cost Index — State & Local Government**, a purer price measure that holds
employment mix constant (QCEW average pay carries some composition drift).

---

## 3. The basket — components → public price series

**Weight provenance (honest status).** The **employee-benefits** weight (~18%) is anchored to
the real statewide **DLS Schedule A "Fixed Costs"** share. The other weights remain **documented
defaults** anchored on the ~75% personnel share and typical operating shares. *Why not all
DLS-derived?* The basket is organized by **input** (wages, utilities, supplies, …) but DLS's
all-351 reports are by **function** (education, public safety, …); only Fixed Costs is a clean
input/object line. True input weights need **object-level** Schedule A line data, which DLS does
not publish in any all-351 web report — and naïvely mixing DESE (all-funds) school totals with
DLS (general-fund) totals yields wrong shares (scope mismatch). Proper object-level weight
derivation is a Phase-4 analytical task. The "Series (as built)" column is what the shipped
pipeline fetches today — all public, reproducible, and (except the optional BLS key) key-free.

| Article 22 component | Sub-component | Series (as built) | Source | Weight |
|---|---|---|---|---|
| **Employee compensation** | Wages & salaries (incl. teachers) | MA local-government avg weekly wage | BLS QCEW | ~37% |
| | Health & insurance benefits | CPI — medical care (`CUUR0000SAM`) | BLS | ~13% |
| | Retirement / pensions / OPEB | *proxy:* tracks local-gov wages | BLS QCEW (proxy) | ~9% |
| **Schools** | Special education (out-of-district) | statewide special-ed expenditure per pupil | MA DESE | ~5% |
| | Student transportation | special-ed in/out-of-district transport per pupil | MA DESE | ~3% |
| **Utilities** | Electricity, gas | CPI — electricity + utility gas (`SEHF01`/`SEHF02`) | BLS | ~6% |
| **Capital — roads** | Road/highway repair | National Highway Construction Cost Index (Fisher) | FHWA (Socrata) | ~6% |
| **Capital — facilities** | Building construction | PPI — inputs to nonres. construction (`WPUIP2300001`) | BLS | ~6% |
| **Other significant** | Vehicles & equipment | CPI — new vehicles (`SETA01`) | BLS | ~3% |
| | Supplies & materials | CPI — commodities (`SAC`) | BLS | ~4% |
| | Contracted/professional services | CPI — services (`SAS`) | BLS | ~8% |
| **Total** | | | | **100%** |

The headline **CPI all-items** (`CUUR0000SA0`) is also fetched, as the reference comparison
line on the Overview chart (not part of the basket). **Planned upgrades** (all swap in without
changing the formula): BLS **ECI–State & Local** for compensation (purer price measure); **EIA**
MA electricity/gas for utilities; **DESE out-of-district tuition rates** and a true
transportation series; **ENR BCI / RSMeans** for facilities. The three current proxies
(pensions → wages, and — until the upgrades — the precision items above) are labelled as proxies
in the app's Methodology tab.

> **Schools matter to the headline.** In most MA communities schools are roughly half the
> budget, and their fastest-rising lines — **special education (especially out-of-district
> placements/tuition) and student transportation** — routinely outpace general inflation.
> MA DESE publishes per-pupil expenditure (by function, incl. SPED and transportation) and
> out-of-district tuition data for **all districts statewide**, making it the schools-side
> analogue to the DLS Databank. Teacher salaries are captured in the compensation block.

### 3.3 Steps/lanes/vacation — a defensibility subtlety
Automatic step/lane and longevity increases are partly *price of a given job* and partly
*quantity/seniority drift*. A pure input-price index should capture only the price part. The
**ECI** is purpose-built to hold employment mix constant and measure the *price* of labor —
which is why it is the planned compensation upgrade (§2.3). The current **QCEW** average-weekly-
wage series is real and key-free but carries some composition drift, so it slightly mixes price
and quantity; this is disclosed. Under either series, step/lane/COLA escalation from MA
collective-bargaining settlements can be shown as a **clearly-labeled separate "contractual
escalator" overlay** rather than baked into the headline — pre-empting the "this isn't really a
price index" critique.

---

## 4. Data sources (vetted) — see `DATA_SOURCES.md` for full detail

**Two hard requirements:** (1) municipal-finance data must cover **all 351** MA
municipalities; (2) every source must be reachable **programmatically** for auto-refresh.
The as-built stack is **key-free** (one optional free BLS key raises rate limits).

| Layer | Source (as built) | Access | Cadence |
|---|---|---|---|
| Compensation — wages | BLS **QCEW** — MA local-government avg weekly wage | open-data CSV by FIPS | annual |
| Compensation — benefits / other prices | BLS **CPI/PPI** public API (medical, electricity+gas, construction inputs, new vehicles, commodities, services) + headline CPI | REST API (POST), one batched call | monthly |
| Schools (SPED + transport) | MA **DESE** — RADAR special-ed + per-pupil files | Excel downloads (committed to repo, ~annual) | annual |
| Roads / construction | FHWA **NHCCI** (`data.transportation.gov/resource/r94d-n4f9.json`) | Socrata JSON | quarterly |
| Local actuals (all 351) | MA DLS **Schedule A** general-fund expenditures | `dls-gw.dor.state.ma.us` (302 → session download; UA + follow-redirect + cookie jar) | annual |
| Muni boundaries | MassGIS Municipalities **FeatureServer** → simplified bundled GeoJSON | ArcGIS REST (one-time `build_geo.R`) | static |

Fetch + assembly: `R/fct_fetch_real.R` (base R `system2`/`curl`, `jsonlite`, `data.table`,
`readxl`, `sf`). No `fredr`/`eia`/`RSocrata`/`httr2` dependency in the shipped path.

### Known gaps (disclose these — they are part of being defensible)
1. **DLS has no API** — the all-351 finance source ships Excel via a session-cookie'd redirect;
   we fetch with a small scripted downloader and re-validate the report URL each cycle.
2. **DESE has no clean bulk API** — the school files are downloaded ~annually and committed to
   the repo; a missing file auto-falls back to a labelled CPI proxy.
3. **Census govt-finance API is state-level only** — cannot supply per-municipality MA data; DLS
   remains the sole all-351 annual source.
4. **GIC health premiums** and **PERAC pensions** are **PDF-only** (no API); pensions currently
   use a wage-based proxy.
5. **ENR BCI / RSMeans** are proprietary; the public PPI construction series is the defensible
   default for the facilities component.
6. **ECI–State&Local** and **EIA MA energy** would sharpen compensation and utilities but were
   deferred (ECI series IDs are not cleanly resolvable key-free; both are easy upgrades).

---

## 5. Architecture (self-updating, reproducible)

```
          GitHub Actions (cron: weekly)  ── secret: BLS_KEY (optional)
                        │
                        ▼
   ┌──────────  data-raw/build_snapshot.R  (build_real_snapshot)  ──────────┐
   │  BLS QCEW (wages) │ BLS CPI/PPI (1 batched call) │ FHWA NHCCI (Socrata) │
   │  DESE files (committed) │ DLS Schedule A (curl, all 351)                │ RAW FETCH
   │                              ▼                                          │
   │            clean / index  (fct_index.R)  ◀── testthat unit tests        │
   │                              ▼                                          │
   │            saveRDS → inst/extdata/mci_snapshot.rds  (committed)         │
   └──────────────────────────────┬───────────────────────────────────────┘
                                  ▼
            committed snapshot .rds on GitHub  (raw URL)
                                  │  load_snapshot(): local-first in dev,
                                  │  remote raw URL on deploy. NO live API in-session.
                                  ▼
            modular Shiny app (R/ = mod_* / fct_* / utils_*)
            bslib page_navbar (fillable=FALSE, document scroll)
            ├─ mod_overview     index vs 2.5% cap & real CPI  +  override-votes bars
            ├─ mod_components   basket trend, relative importance, contributions
            ├─ mod_map          leaflet choropleth, all 351 (MassGIS + DLS)
            └─ mod_methodology  transparency: formula, weights, live sources, provenance
```

**Principles.**
- **The Shiny app never calls a live data API.** On startup it reads the latest committed
  snapshot (local file in dev, GitHub raw URL when deployed — fetched once per process). An
  upstream outage cannot break the dashboard; sessions are fast; no rate-limit surprises.
- **All index math is pure functions** (`fct_index.R`), unit-tested with `testthat` independent
  of Shiny. Modules only display precomputed results.
- **Reproducible & traceable.** `build_snapshot.R` regenerates the index from public sources;
  each snapshot carries a provenance block; the producing commit is the audit anchor.
- **No tidyverse.** Data manipulation is `data.table`; tables are `reactable`; charts are
  `plotly`; maps are `leaflet`/`sf`; file reads are `readxl`.

**Framework (as built):** a plain modular layout (`mod_*`, `fct_*`, `utils_*`) that runs
without extra scaffolding. *Planned hardening:* `golem` (app-as-package), `renv` lockfile,
`targets` pipeline, and `pins` versioned board — deferred to Phase 4.

**Auto-update (shinyapps.io target):** a GitHub Actions weekly cron runs `build_snapshot.R`,
runs the tests, and **commits the refreshed `mci_snapshot.rds`**. The deployed app reads that
committed file from the repo's raw URL at process startup — so it stays current with **no
redeploy**, and an upstream API outage never breaks the live dashboard. The `.rds` is excluded
from the shinyapps bundle (`.rscignore`) so the deployed app always uses the remote copy; in
local dev the bundled file is used so you see your latest build. (Note GitHub's 60-day
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
**Phase 1 — Runnable skeleton on sample data.** ✅ Modular Shiny app, pure `compute_mci()` in
data.table, deterministic sample snapshot, passing tests.
**Phase 2 — Live national basket.** ✅ DONE (key-free; one optional free BLS key for headroom).
`R/fct_fetch_real.R` / `build_real_snapshot()` pull real series: **BLS QCEW** (MA local-gov
wages), **BLS CPI/PPI** (benefits, utilities, facilities, vehicles, supplies, services — one
batched call), **FHWA NHCCI** (roads), plus headline **CPI** as the reference line. Real MCI:
2015–2024, ~3.8%/yr. Cached to `inst/extdata/mci_snapshot.rds`; refreshed weekly.
**Phase 2.5 — Schools + override evidence.** ✅ **MA DESE** special-education and student-
transportation per-pupil series (real, replacing CPI proxies); **Prop 2½ override-votes** chart
on the Overview tab (statewide, by year — the squeeze made visible).
**Phase 3 — All-351 expenditure layer + map.** ✅ DONE. DLS **Schedule A** downloader (all 351,
2 fiscal years) → per-municipality spending-growth-vs-MCI; **MassGIS** choropleth (`mod_map`,
349/351 joined). Benefits weight anchored to real DLS Fixed Costs (~18%). *Remaining:* full
**object-level** expenditure-share weights (Phase 4 — needs raw Schedule A line data, not in the
all-351 web reports).
**Phase 4 — Hardening & governance.** Real DLS weights; ECI/EIA/ENR precision upgrades; `renv`
lock + `targets` + `pins` + `golem`; sensitivity tab; independent review; MAPC/MMA/Collins
engagement; governance home.

---

## 8. Decisions (resolved 2026-05-30)
1. **Base year — user-selectable.** Rather than fix one base year and ask people to trust it,
   the app exposes base year as a global control: the index recomputes live from the published
   formula at whatever base the user picks. This converts the "you cherry-picked the base year"
   critique into a transparency feature. Default base = the earliest available year.
2. **Scope — all 351 MA municipalities.** The headline index is a *single statewide
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
