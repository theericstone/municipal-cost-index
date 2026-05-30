# fct_index.R — pure index mathematics (data.table; no tidyverse, no Shiny).
# Everything here is unit-testable in isolation. The Shiny modules only display
# the results these functions return.

library(data.table)

#' Normalize a named/weighted component table so weights sum to 1.
#' @param weights data.table with columns: component, weight
#' @return data.table with an added `w` column (weight / sum(weight))
normalize_weights <- function(weights) {
  weights <- as.data.table(weights)
  stopifnot(all(c("component", "weight") %in% names(weights)))
  stopifnot(all(weights$weight >= 0), sum(weights$weight) > 0)
  weights[, w := weight / sum(weight)]
  weights[]
}

#' Compute the headline Municipal Cost Index (fixed-weight Laspeyres).
#'
#'   MCI_t = 100 * sum_i  w_i * (P_i,t / P_i,0)
#'
#' @param prices    long data.table: component, year, level  (a price level for
#'                  each component-year; need not be pre-indexed)
#' @param weights   data.table: component, weight  (normalized internally)
#' @param base_year integer base year; MCI(base_year) == 100 by construction
#' @return data.table: year, mci
compute_mci <- function(prices, weights, base_year) {
  prices  <- as.data.table(prices)
  weights <- normalize_weights(weights)
  stopifnot(all(c("component", "year", "level") %in% names(prices)))
  stopifnot(base_year %in% prices$year)

  comps_p <- sort(unique(prices$component))
  comps_w <- sort(unique(weights$component))
  if (!identical(comps_p, comps_w)) {
    stop("Components in `prices` and `weights` must match exactly.\n",
         "  prices:  ", paste(comps_p, collapse = ", "), "\n",
         "  weights: ", paste(comps_w, collapse = ", "))
  }

  base <- prices[year == base_year, .(component, base_level = level)]
  x <- merge(prices, base, by = "component", all.x = TRUE)
  x <- merge(x, weights[, .(component, w)], by = "component", all.x = TRUE)
  x[, price_relative := level / base_level]
  x[, contribution := 100 * w * price_relative]

  out <- x[, .(mci = sum(contribution)), by = year][order(year)]
  out[]
}

#' Per-component contributions to the index, for the drill-down view.
#' @return long data.table: year, component, w, price_relative, contribution
#'         (contribution sums to mci within each year)
mci_components <- function(prices, weights, base_year) {
  prices  <- as.data.table(prices)
  weights <- normalize_weights(weights)
  base <- prices[year == base_year, .(component, base_level = level)]
  x <- merge(prices, base, by = "component", all.x = TRUE)
  x <- merge(x, weights[, .(component, w)], by = "component", all.x = TRUE)
  x[, price_relative := level / base_level]
  x[, contribution := 100 * w * price_relative]
  x[order(year, -contribution),
    .(year, component, w, price_relative, contribution)][]
}

#' Per-component summary for the transparency view: how far each input's price
#' has risen, in absolute terms, alongside its budget weight ("relative
#' importance", in CPI parlance).
#' @return data.table: component, w (weight), index (latest, base=100),
#'         cum_pct (cumulative % change since base), cagr (avg annual %)
component_summary <- function(prices, weights, base_year) {
  comp <- mci_components(prices, weights, base_year)
  n <- max(comp$year) - min(comp$year)
  latest <- comp[year == max(year)]
  latest[, `:=`(
    index   = 100 * price_relative,
    cum_pct = 100 * (price_relative - 1),
    cagr    = 100 * (price_relative ^ (1 / n) - 1)
  )]
  latest[order(-cum_pct), .(component, w, index, cum_pct, cagr)][]
}

#' Long table of every component indexed to base = 100, for the trend chart.
#' @return data.table: component, year, index (base year = 100)
component_index_series <- function(prices, weights, base_year) {
  comp <- mci_components(prices, weights, base_year)
  comp[, .(component, year, index = 100 * price_relative)][order(component, year)]
}

#' Year-over-year growth of any indexed series.
#' @param dt data.table with columns `year` and `value`
#' @return data.table: year, value, yoy (fractional, e.g. 0.031 = 3.1%)
yoy_growth <- function(dt, value_col = "mci") {
  dt <- as.data.table(dt)[order(year)]
  v <- dt[[value_col]]
  dt[, yoy := c(NA_real_, v[-1] / v[-length(v)] - 1)]
  dt[]
}

#' Recompute a snapshot at a different base year.
#' The basket prices, weights, and actuals do not depend on the base year, so we
#' re-derive the index, contributions, and benchmark from them. This is exactly
#' the published formula re-applied — a third party picking the same base year
#' reproduces these numbers, which is why exposing it in the UI is a transparency
#' feature, not a manipulation risk.
#' @param snap a snapshot list (must contain prices, weights, actuals)
#' @param base_year integer base year (must exist in the price series)
#' @return a snapshot list with base_year, mci, components, benchmark refreshed
recompute_snapshot <- function(snap, base_year) {
  base_year <- as.integer(base_year)
  prices  <- as.data.table(snap$prices)
  weights <- as.data.table(snap$weights)
  mci <- compute_mci(prices, weights, base_year)
  out <- modifyList(snap, list(
    base_year  = base_year,
    mci        = mci,
    components = mci_components(prices, weights, base_year)
  ))
  # benchmark only if the snapshot carries per-municipality actuals
  if (!is.null(snap$actuals))
    out$benchmark <- compute_benchmark(as.data.table(snap$actuals), mci, base_year)
  out
}

#' Reconciliation overlay (the peer-benchmark layer).
#' Compares each municipality's actual per-capita expenditure growth against the
#' MCI-implied cost growth over the same window, both indexed to the base year.
#'
#' @param actuals long data.table: muni, year, per_capita_exp
#' @param mci     output of compute_mci() (year, mci)
#' @param base_year integer
#' @return data.table: muni, year, exp_index, mci, gap
#'         gap = exp_index - mci  (>0 spending faster than cost growth;
#'         <0 absorbing/deferring relative to market cost growth)
compute_benchmark <- function(actuals, mci, base_year) {
  actuals <- as.data.table(actuals)
  stopifnot(all(c("muni", "year", "per_capita_exp") %in% names(actuals)))
  base <- actuals[year == base_year, .(muni, base_exp = per_capita_exp)]
  x <- merge(actuals, base, by = "muni", all.x = TRUE)
  x[, exp_index := 100 * per_capita_exp / base_exp]
  x <- merge(x, as.data.table(mci)[, .(year, mci)], by = "year", all.x = TRUE)
  x[, gap := exp_index - mci]
  x[order(muni, year), .(muni, year, exp_index, mci, gap)][]
}
