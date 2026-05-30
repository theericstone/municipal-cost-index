# _targets.R — reproducible pipeline (Phase 2/3). Run: targets::tar_make()
# Each external source is its own target, so a single API outage rebuilds only its
# branch. The final target writes a versioned, auditable pins snapshot that the
# Shiny app reads. Until live fetchers are wired, it pins the sample snapshot.
#
# Requires (live mode): targets, pins, fredr, eia, httr2, jsonlite, RSocrata, readxl

library(targets)

tar_option_set(packages = c("data.table", "jsonlite"))

# source the project's pure functions
for (f in list.files("R", pattern = "^fct_", full.names = TRUE)) source(f)

list(
  # fetch real public data and assemble the snapshot (always re-fetch on a run)
  tar_target(snapshot, build_real_snapshot(startyear = 2015, endyear = 2024),
             cue = tar_cue(mode = "always")),

  # cache it where the Shiny app reads it (and, in CI, commit this file)
  tar_target(cached_rds, {
    dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
    saveRDS(snapshot, "inst/extdata/mci_snapshot.rds")
    "inst/extdata/mci_snapshot.rds"
  }, format = "file")

  # --- Phase 4 option: also publish a versioned pins snapshot for shinyapps.io ---
  # , tar_target(publish, {
  #     board <- pins::board_folder("data-pins", versioned = TRUE)
  #     pins::pin_write(board, snapshot, "mci_snapshot", type = "rds")
  #   }, cue = tar_cue(mode = "always"))
)
