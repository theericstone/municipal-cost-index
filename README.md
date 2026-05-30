# Massachusetts Core Services Municipal Cost Index (MCI)

A draft R/Shiny tool that establishes a **Core Services Municipal Cost Index** for
Massachusetts municipalities, in response to Brookline 2026 Annual Town Meeting
**Warrant Article 22**.

It measures how fast the *price* of a fixed basket of municipal inputs (compensation,
utilities, road/facility construction, supplies, services) rises versus the Proposition 2½
2.5% levy cap — and reconciles that against each community's *actual* per-capita spending.

> **Status: the headline index now uses REAL public data** (BLS QCEW + CPI/PPI + FHWA NHCCI,
> all key-free). The app loads a cached snapshot built by `data-raw/build_snapshot.R`; if that
> file is absent it falls back to deterministic sample data. Still illustrative pending DLS/DESE
> scraping: per-municipality spending (the Benchmark/Map layer) and the component weights.

## Refresh the real data

```r
# from this directory, fetches live public series and rebuilds the cached snapshot:
Rscript data-raw/build_snapshot.R     # writes inst/extdata/mci_snapshot.rds
```
No API keys required. The GitHub Action `.github/workflows/update-index.yaml` runs this weekly.

## Run it

```r
# from this directory, in R (>= 4.5):
shiny::runApp("mci")          # or: setwd("mci"); shiny::runApp()
```

Skeleton needs: `shiny, bslib, bsicons, data.table, reactable, leaflet, sf, plotly`
(install any missing with `install.packages(...)`).

```r
# run the index unit tests:
for (f in list.files("mci/R", pattern = "^fct_", full.names = TRUE)) source(f)
testthat::test_dir("mci/tests/testthat")
```

## Layout

```
mci/
├── docs/PLAN.md            ← methodology & full plan (read this first)
├── docs/DATA_SOURCES.md    ← vetted public data inventory
├── R/
│   ├── fct_index.R         ← pure index math (Laspeyres) — data.table, tested
│   ├── fct_sample_data.R   ← deterministic sample snapshot (pipeline contract)
│   ├── fct_fetch.R         ← live fetchers (FRED/EIA/NHCCI/DLS) for the pipeline
│   ├── mod_overview.R      ← index vs 2.5% cap
│   ├── mod_components.R    ← basket drill-down
│   ├── mod_benchmark.R     ← actual-vs-MCI reconciliation (peer layer)
│   ├── mod_map.R           ← geographic gap view
│   ├── mod_methodology.R   ← transparency tab
│   └── app.R               ← UI/server assembly + run_app()
├── app.R                   ← entry point (shiny::runApp)
├── _targets.R              ← reproducible pipeline (Phase 2/3)
├── tests/testthat/         ← index unit tests
├── .github/workflows/      ← weekly auto-update cron (Phase 4)
└── DESCRIPTION             ← deps (golem-ready)
```

## Design at a glance
- **Core:** fixed-weight Laspeyres input-price index; weights from DLS Schedule A.
- **Overlay:** actual per-capita expenditure vs MCI = "cost-management gap" (the peer benchmark).
- **No tidyverse:** `data.table` for data, `reactable` for tables, `plotly`/`leaflet` for viz.
- **Self-updating:** `targets` pipeline → versioned `pins` snapshot → GitHub Actions cron.
  The app reads the snapshot; it never calls a live API in a user session.
- **Defensible:** every weight, series, and formula published; sample vs real clearly flagged.

See `docs/PLAN.md` §6 for the full defensibility checklist and §7 for the roadmap.
