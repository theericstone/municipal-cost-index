# Unit tests for the index engine. Run: testthat::test_dir("tests/testthat")
# (with R/fct_index.R + R/fct_sample_data.R sourced first).
library(testthat); library(data.table)

test_that("weights normalize to 1", {
  w <- data.table(component = c("a", "b", "c"), weight = c(2, 2, 1))
  expect_equal(sum(normalize_weights(w)$w), 1)
})

test_that("MCI equals 100 in the base year", {
  p <- sample_prices(); w <- sample_weights()
  mci <- compute_mci(p, w, 2015L)
  expect_equal(mci[year == 2015L, mci], 100)
})

test_that("a uniform x% price rise yields an x% index rise", {
  p <- data.table(component = rep(c("a", "b"), each = 2),
                  year = c(2020, 2021, 2020, 2021),
                  level = c(100, 110, 50, 55))          # both +10%
  w <- data.table(component = c("a", "b"), weight = c(0.7, 0.3))
  mci <- compute_mci(p, w, 2020L)
  expect_equal(mci[year == 2021L, mci], 110)
})

test_that("component contributions sum to the headline index", {
  p <- sample_prices(); w <- sample_weights()
  mci  <- compute_mci(p, w, 2015L)
  comp <- mci_components(p, w, 2015L)
  agg  <- comp[, .(s = sum(contribution)), by = year][order(year)]
  expect_equal(agg$s, mci[order(year)]$mci, tolerance = 1e-8)
})

test_that("mismatched components error out", {
  p <- data.table(component = "a", year = 2020:2021, level = c(100, 105))
  w <- data.table(component = c("a", "b"), weight = c(1, 1))
  expect_error(compute_mci(p, w, 2020L), "match exactly")
})

test_that("component_summary reports cumulative change and is base-year=0 at base", {
  p <- sample_prices(); w <- sample_weights()
  s <- component_summary(p, w, 2015L)
  expect_equal(nrow(s), nrow(w))                       # one row per component
  expect_true(all(c("component","w","index","cum_pct","cagr") %in% names(s)))
  s0 <- component_summary(p, w, max(p$year))           # base = last year
  expect_true(all(abs(s0$cum_pct) < 1e-8))             # no change at the base year
})

test_that("component_index_series is 100 at the base year for every component", {
  p <- sample_prices(); w <- sample_weights()
  ser <- component_index_series(p, w, 2015L)
  expect_true(all(abs(ser[year == 2015L, index] - 100) < 1e-8))
})

test_that("basket includes school cost drivers", {
  comps <- sample_weights()$component
  expect_true("Special education (out-of-district)" %in% comps)
  expect_true("Student transportation" %in% comps)
})

test_that("recompute_snapshot re-anchors to the chosen base year", {
  snap <- build_sample_snapshot()
  s23  <- recompute_snapshot(snap, 2020L)
  expect_equal(s23$base_year, 2020L)
  expect_equal(s23$mci[year == 2020L, mci], 100)                    # new base = 100
  # contributions still sum to the headline at the new base
  agg <- s23$components[, .(s = sum(contribution)), by = year][order(year)]
  expect_equal(agg$s, s23$mci[order(year)]$mci, tolerance = 1e-8)
  # benchmark base-year gap collapses to ~0 at the new base
  expect_true(all(abs(s23$benchmark[year == 2020L, gap]) < 1e-8))
})

test_that("benchmark gap is exp_index minus mci, base year gap ~ 0", {
  snap <- build_sample_snapshot()
  b <- as.data.table(snap$benchmark)
  expect_true(all(abs(b[year == snap$base_year, gap]) < 1e-8))
  one <- b[1]
  expect_equal(one$gap, one$exp_index - one$mci, tolerance = 1e-8)
})
