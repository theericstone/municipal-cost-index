# fct_sample_data.R — deterministic illustrative data standing in for the live
# pinned snapshot. NO random number generation: fully reproducible. In Phase 2/3
# these tables are produced by the targets pipeline from FRED/EIA/NHCCI/DLS and
# read via pins::pin_read(). The schema here is the contract the pipeline targets.

library(data.table)

SAMPLE_YEARS <- 2015:2025
SAMPLE_BASE_YEAR <- 2015L

# ---- Basket definition: components, illustrative weights, annual price growth ----
# `growth` = average annual price growth; `shock` = additive YoY bumps applied in
# specific years to mimic real volatility (e.g. the 2021-22 energy/construction spike).
.sample_basket <- function() {
  data.table(
    # Schools are ~half a MA municipal budget; special education (esp. out-of-
    # district tuition) and student transportation are among the fastest-rising
    # cost drivers and must be represented. Source (production): MA DESE.
    component = c("Wages & salaries", "Health & insurance benefits",
                  "Retirement / pensions",
                  "Special education (out-of-district)", "Student transportation",
                  "Utilities & energy", "Roads & highway", "Facilities construction",
                  "Vehicles & equipment", "Supplies & materials",
                  "Contracted services"),
    weight    = c(0.37, 0.13, 0.09, 0.05, 0.03,
                  0.06, 0.06, 0.06, 0.03, 0.04, 0.08),
    # moderated to ~4%/yr blended (still above the 2.5% cap, the WA22 point,
    # but no longer running hotter than typical municipal spending growth)
    growth    = c(0.030, 0.052, 0.042, 0.070, 0.050,
                  0.035, 0.042, 0.046, 0.034, 0.030, 0.035)
  )
}

# Year-specific additive shocks to YoY growth (deterministic), keyed by component.
.sample_shocks <- function() {
  list(
    "Utilities & energy"      = c("2021" = 0.07, "2022" = 0.10, "2023" = -0.05),
    "Roads & highway"         = c("2021" = 0.05, "2022" = 0.08, "2023" = 0.02),
    "Facilities construction" = c("2021" = 0.04, "2022" = 0.07),
    "Health & insurance benefits"         = c("2024" = 0.015, "2025" = 0.015),
    "Student transportation"              = c("2022" = 0.06, "2023" = 0.03),
    "Special education (out-of-district)" = c("2023" = 0.02, "2024" = 0.02)
  )
}

#' Build the long component price-level table (component, year, level).
sample_prices <- function(years = SAMPLE_YEARS) {
  basket <- .sample_basket()
  shocks <- .sample_shocks()
  out <- vector("list", nrow(basket))
  for (i in seq_len(nrow(basket))) {
    comp <- basket$component[i]
    g    <- basket$growth[i]
    lvl  <- 100
    levels <- numeric(length(years))
    for (j in seq_along(years)) {
      if (j == 1L) {
        levels[j] <- 100
      } else {
        bump <- 0
        sh <- shocks[[comp]]
        if (!is.null(sh) && as.character(years[j]) %in% names(sh)) {
          bump <- sh[[as.character(years[j])]]
        }
        lvl <- lvl * (1 + g + bump)
        levels[j] <- lvl
      }
    }
    out[[i]] <- data.table(component = comp, year = years, level = levels)
  }
  rbindlist(out)
}

#' Basket weights (component, weight). Normalized downstream by the index engine.
sample_weights <- function() {
  .sample_basket()[, .(component, weight)]
}

# ---- Reconciliation sample: 13 communities, per-capita expenditure series ----
# Each muni grows at its own rate around the implied cost trend, so the overlay
# shows a spread of "manages below / at / above market cost growth".
.sample_munis <- function() {
  data.table(
    muni = c("Brookline", "Newton", "Cambridge", "Arlington", "Lexington",
             "Needham", "Wellesley", "Belmont", "Watertown", "Somerville",
             "Medford", "Framingham", "Natick"),
    # annual per-capita expenditure growth (illustrative)
    exp_growth = c(0.041, 0.045, 0.052, 0.036, 0.048, 0.043, 0.047, 0.038,
                   0.034, 0.050, 0.037, 0.039, 0.040),
    base_pc    = c(4200, 4600, 5400, 3500, 4900, 4700, 5200, 3900, 3400,
                   4100, 3300, 3000, 3600),
    lat = c(42.332, 42.337, 42.373, 42.415, 42.447, 42.280, 42.297, 42.396,
            42.371, 42.387, 42.418, 42.279, 42.283),
    lng = c(-71.121, -71.209, -71.110, -71.157, -71.224, -71.234, -71.296,
            -71.178, -71.183, -71.099, -71.107, -71.416, -71.349)
  )
}

#' Build the long actual-expenditure table (muni, year, per_capita_exp) + geo.
sample_actuals <- function(years = SAMPLE_YEARS) {
  m <- .sample_munis()
  out <- vector("list", nrow(m))
  for (i in seq_len(nrow(m))) {
    g <- m$exp_growth[i]
    pc <- m$base_pc[i] * (1 + g) ^ (years - min(years))
    out[[i]] <- data.table(muni = m$muni[i], year = years, per_capita_exp = pc)
  }
  rbindlist(out)
}

#' Municipality geo lookup (muni, lat, lng) for the skeleton map.
sample_geo <- function() .sample_munis()[, .(muni, lat, lng)]

#' Assemble the full snapshot the Shiny app consumes. In production this is the
#' object written by pins::pin_write() / read by pin_read().
build_sample_snapshot <- function() {
  prices  <- sample_prices()
  weights <- sample_weights()
  mci     <- compute_mci(prices, weights, SAMPLE_BASE_YEAR)
  list(
    base_year  = SAMPLE_BASE_YEAR,
    prices     = prices,
    weights    = weights,
    mci        = mci,
    components = mci_components(prices, weights, SAMPLE_BASE_YEAR),
    actuals    = sample_actuals(),
    benchmark  = compute_benchmark(sample_actuals(), mci, SAMPLE_BASE_YEAR),
    geo        = sample_geo(),
    provenance = list(
      kind = "SAMPLE / ILLUSTRATIVE",
      note = "Deterministic placeholder data. Not real prices. Replace via targets pipeline.",
      generated_for = "MCI skeleton v0.1"
    )
  )
}
