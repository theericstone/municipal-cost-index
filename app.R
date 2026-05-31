# Top-level entry point (shinyapps.io deploys this). Run with: shiny::runApp("mci").
# Sources the runtime R/ files and launches on the cached snapshot (read-only;
# the app never fetches live data — that's the pipeline's job).
local({
  runtime <- c("utils_ui.R", "fct_index.R", "fct_sample_data.R",
               "mod_overview.R", "mod_components.R", "mod_map.R",
               "mod_methodology.R", "app.R")
  for (f in runtime) source(file.path("R", f))
})

run_app()
