# app.R (in R/) — assembles UI + server. The app reads a snapshot object only;
# it never calls a live API. In production the base snapshot comes from a remote
# pins board (built by GitHub Actions); in the skeleton, build_sample_snapshot().
#
# Base year is a GLOBAL, user-selectable control: the index recomputes live from
# the published formula at whatever base year the user picks. This is a
# transparency feature ("don't trust our base year — choose your own").
library(shiny); library(bslib)

app_ui <- function(years = 2015:2025, base_default = 2015, banner = NULL) {
  page_navbar(
    title = "MA Municipal Cost Index",
    theme = bs_theme(version = 5, primary = "#1f4e79", base_font = font_google("Inter")),
    # Normal document flow: the whole page scrolls instead of each card
    # overflowing internally. Cards/plots below carry explicit heights.
    fillable = FALSE,
    header = tagList(
      # Belt-and-suspenders: bslib's page-fill shell otherwise clamps the body to
      # 100vh and pushes scrolling inside cards. Let the document itself scroll.
      tags$style(HTML(
        ".bslib-page-fill{height:auto !important;min-height:100vh;}
         html,body{height:auto !important;overflow-y:auto !important;}
         .navbar{position:sticky;top:0;z-index:1030;}
         .bslib-value-box .value-box-title{font-size:.8rem;margin-bottom:.1rem;}
         .bslib-value-box .value-box-value{font-size:1.55rem;line-height:1.1;}")),
      div(class = "bg-body-tertiary border-bottom text-body-secondary small text-center py-1 px-2",
          banner)),
    sidebar = sidebar(
      width = 260,
      selectInput("base_year", "Base year (index = 100)",
                  choices = years, selected = base_default),
      helpText(class = "small",
        "Pick any base year — the index recomputes from the published formula. ",
        "Changing it re-anchors the reference point; the underlying component ",
        "price movements and weights are unchanged."),
    ),
    nav_panel("Overview",     mod_overview_ui("overview")),
    nav_panel("Components",   mod_components_ui("components")),
    nav_panel("Methodology",  mod_methodology_ui("methodology")),
    nav_spacer(),
    nav_item(tags$a("Source on GitHub", href = "https://github.com/theericstone/municipal-cost-index",
                    target = "_blank", class = "text-muted"))
  )
}

app_server <- function(base_snap) {
  function(input, output, session) {
    # Reactive snapshot recomputed at the user-selected base year.
    snap <- reactive({
      by <- input$base_year
      if (is.null(by)) by <- base_snap$base_year
      recompute_snapshot(base_snap, as.integer(by))
    })
    mod_overview_server("overview", snap)
    mod_components_server("components", snap)
    mod_methodology_server("methodology", snap)
  }
}

#' Load the cached real snapshot if present, else fall back to sample data.
#' The pipeline / GitHub Action writes inst/extdata/mci_snapshot.rds; the app
#' only ever reads it (never calls a live API in a user session).
load_snapshot <- function() {
  path <- system.file("extdata", "mci_snapshot.rds", package = "mci")
  if (!nzchar(path)) path <- "inst/extdata/mci_snapshot.rds"
  if (file.exists(path)) readRDS(path) else build_sample_snapshot()
}

#' Launch the app. Defaults to the cached real snapshot when available.
run_app <- function(snap = load_snapshot(), ...) {
  years  <- sort(unique(as.data.table(snap$prices)$year))
  sample <- grepl("SAMPLE", snap$provenance$kind %||% "")
  banner <- if (sample)
    "Build on sample data. See Methodology."
  else
    sprintf("Massachusetts municipal operating-cost index, %d–%d — built from public BLS, FHWA and DESE data.",
            min(years), max(years))
  shinyApp(ui = app_ui(years = years, base_default = snap$base_year, banner = banner),
           server = app_server(snap), ...)
}

`%||%` <- function(a, b) if (is.null(a)) b else a
