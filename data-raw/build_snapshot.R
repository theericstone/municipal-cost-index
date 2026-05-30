# build_snapshot.R — fetch REAL public data and cache the snapshot the app reads.
# Run from the package root:  Rscript data-raw/build_snapshot.R
# (Also what the GitHub Action runs on a weekly schedule.)
suppressMessages(for (f in list.files("R", pattern = "^fct_", full.names = TRUE)) source(f))

message("Fetching real public data (BLS QCEW/CPI/PPI + FHWA NHCCI)…")
snap <- build_real_snapshot(startyear = 2015, endyear = 2024)

dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
saveRDS(snap, "inst/extdata/mci_snapshot.rds")
message(sprintf("Wrote inst/extdata/mci_snapshot.rds — MCI %d=%.1f (%s)",
                max(snap$mci$year), snap$mci[year == max(year), mci],
                snap$provenance$kind))
