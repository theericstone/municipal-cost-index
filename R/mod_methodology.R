# mod_methodology.R — transparency tab. The defensibility of the index lives here:
# the formula, the basket, every weight, every source, and the data provenance.
library(shiny); library(bslib); library(reactable); library(data.table)

mod_methodology_ui <- function(id) {
  ns <- NS(id)
  layout_columns(
    col_widths = c(7, 5),
    card(
      card_header("How the index is built"),
      div(class = "p-2",
        h5("Fixed-weight Laspeyres index of price relatives"),
        withMathJax(p("$$\\text{MCI}_t = 100 \\times \\sum_i w_i \\left(\\frac{P_{i,t}}{P_{i,0}}\\right)$$")),
        tags$ul(
          tags$li(strong("w"), HTML(" &mdash; each component's fixed share of the municipal budget; shares sum to 1. The employee-benefits share is anchored to DLS Schedule A statewide (Fixed Costs &asymp; 18%); the remaining shares are documented defaults pending object-level expenditure data.")),
          tags$li(HTML("<strong>P<sub>i,t</sub> / P<sub>i,0</sub></strong> &mdash; the component's public price series, relative to the base year.")),
          tags$li(strong("Base year"), " — a recent, non-anomalous year set to 100.")
        ),
        p(class = "text-muted",
          "A price index, not a spending index: a community cannot lower it by cutting ",
          "services. Weights are reweighted on a fixed ~5-year schedule with retroactive ",
          "recomputation — a rule, not a discretionary act. Full method: docs/PLAN.md.")
      )
    ),
    card(
      card_header("Basket & weights"),
      reactableOutput(ns("weights")),
      card_footer(class = "text-body-secondary small",
        HTML("<b>Measured</b> = anchored to real statewide data: wages and pension to the ",
             "US Census Survey of MA local-government finances (salaries 39.8%, pension trust 6%); ",
             "the benefits total to DLS Schedule A “Fixed Costs” (~18%). <b>Estimate</b> = documented ",
             "default from typical Massachusetts municipal budget composition, pending object-level ",
             "data. <b>*</b> Special education and transportation are <i>programs</i>, not inputs, so ",
             "their weight overlaps the wage line; kept separate to show the school cost drivers."))
    ),
    card(
      card_header("Live data source per component"),
      reactableOutput(ns("source_tbl"))
    ),
    card(
      card_header("Data sources (production targets)"),
      div(class = "p-2", uiOutput(ns("sources")))
    ),
    card(
      card_header("Data provenance"),
      div(class = "p-2", verbatimTextOutput(ns("prov")))
    ),
    card(
      card_header("A note on data quality"),
      div(class = "p-2 small text-muted",
        "This index is built entirely from ", strong("free, public data"),
        " so anyone can reproduce it. ", strong("Deeper or higher-resolution data ",
        "is available for a fee"), " and could sharpen specific components if the ",
        "Town chooses to invest later — for example ENR Construction Cost Index or ",
        "RSMeans for facilities, and municipality-level GIC health-premium and PERAC ",
        "pension detail. The methodology is designed to slot these in without changing ",
        "the formula.")
    )
  )
}

mod_methodology_server <- function(id, snap) {
  moduleServer(id, function(input, output, session) {
    output$weights <- renderReactable({
      w <- normalize_weights(as.data.table(snap()$weights))[order(-w)]
      src <- as.data.table(snap()$sources)
      if (!is.null(src) && "wbasis" %in% names(src)) {
        w <- merge(w, src[, .(component, Basis = wbasis)], by = "component", all.x = TRUE)[order(-w)]
      } else {
        w[, Basis := "Estimate (budget norms)"]
      }
      reactable(
        w[, .(Component = component, Weight = w, Basis = Basis)],
        columns = list(
          Weight = colDef(format = colFormat(percent = TRUE, digits = 1), maxWidth = 90),
          Basis = colDef(style = function(value) {
            if (grepl("Measured", value)) list(color = "#1e7e34", fontWeight = "bold")
            else list(color = "#6c757d")
          })),
        striped = TRUE, compact = TRUE, pagination = FALSE)
    })

    output$source_tbl <- renderReactable({
      s <- snap()$sources
      if (is.null(s)) {
        s <- data.table(component = "—",
                        source = "Run the data pipeline to populate sources",
                        proxy = FALSE)
      }
      s <- as.data.table(s)
      reactable(
        s[, .(Component = component, `Live source` = source,
              Proxy = ifelse(proxy, "proxy", ""))],
        columns = list(
          `Live source` = colDef(minWidth = 220),
          Proxy = colDef(maxWidth = 70,
            style = function(value) if (nzchar(value)) list(color = "#b9770e", fontWeight = "bold") else NULL)),
        striped = TRUE, compact = TRUE, defaultPageSize = 12)
    })

    output$sources <- renderUI({
      tags$ul(
        tags$li(HTML("<b>Compensation</b> — BLS Employment Cost Index, State &amp; Local Govt (FRED <code>ECIGVTWAG</code>, <code>ECIGVTBEN</code>)")),
        tags$li(HTML("<b>Schools — special education &amp; transportation</b> — MA DESE per-pupil expenditure &amp; out-of-district tuition data (all districts)")),
        tags$li(HTML("<b>Utilities</b> — EIA MA electricity &amp; natural gas; CPI utilities")),
        tags$li(HTML("<b>Roads</b> — FHWA National Highway Construction Cost Index (Socrata)")),
        tags$li(HTML("<b>Facilities</b> — BLS PPI construction inputs")),
        tags$li(HTML("<b>Other</b> — BLS PPI (vehicles, supplies); CPI/PPI services")),
        tags$li(HTML("<b>Local actuals (all 351)</b> — MA DLS Municipal Databank, Schedule A")),
        tags$li(HTML("<b>Boundaries</b> — MassGIS <code>TOWNSSURVEY_POLYM</code>"))
      )
    })

    output$prov <- renderText({
      s <- snap(); p <- s$provenance
      paste(sprintf("kind:  %s", p$kind),
            sprintf("note:  %s", p$note),
            sprintf("base year: %d", s$base_year),
            sep = "\n")
    })
  })
}
