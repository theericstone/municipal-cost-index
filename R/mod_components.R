# mod_components.R — how the index is actually built: the price trend of every
# input (indexed to a common base), its budget weight, and its contribution.
library(shiny); library(bslib); library(plotly); library(reactable); library(data.table)

mod_components_ui <- function(id) {
  ns <- NS(id)
  layout_sidebar(
    fillable = FALSE, fill = FALSE,
    sidebar = sidebar(
      title = "View",
      sliderInput(ns("year"), "Contribution year", min = 2015, max = 2025,
                  value = 2025, step = 1, sep = ""),
      helpText("The year slider controls the contribution bars at the bottom. ",
               "The trend chart and table above always show the full history.")
    ),
    mci_intro("How the index is built",
      "The MCI is a weighted blend of input prices. The chart shows ", strong("how far "),
      "each input's price has risen since the base year (everything starts at 100, like ",
      "the CPI). The bold black line is the composite MCI — it sits between its fastest ",
      "and slowest components, pulled upward by the heavily-weighted ones. The table ",
      "gives each input's ", strong("budget weight"), " and its ", strong("actual rise"),
      " in absolute terms; the bars at the bottom show how weight × price rise becomes ",
      "each input's contribution to the headline number."),
    card(
      card_header("Price of each input over time (base year = 100)"),
      plotlyOutput(ns("trend"), height = "440px"),
      card_footer(class = "text-body-secondary small",
        "Read this like a stock chart: a line at 150 means that input costs 50% more ",
        "than in the base year. Click legend items to isolate a series.")
    ),
    card(
      card_header("Relative importance & cumulative price change"),
      reactableOutput(ns("summary"))
    ),
    card(
      card_header(textOutput(ns("bars_title"), inline = TRUE)),
      plotlyOutput(ns("bars"), height = "380px")
    )
  )
}

mod_components_server <- function(id, snap) {
  moduleServer(id, function(input, output, session) {
    prices  <- reactive(as.data.table(snap()$prices))
    weights <- reactive(as.data.table(snap()$weights))
    by      <- reactive(snap()$base_year)

    observe({
      yrs <- sort(unique(prices()$year))
      updateSliderInput(session, "year", min = min(yrs), max = max(yrs),
                        value = max(yrs))
    })

    # ---- Trend: every component indexed to base = 100, plus the composite MCI ----
    output$trend <- renderPlotly({
      ser <- component_index_series(prices(), weights(), by())
      mci <- as.data.table(snap()$mci)
      comps <- sort(unique(ser$component))
      p <- plot_ly()
      for (cc in comps) {
        dc <- ser[component == cc][order(year)]
        p <- add_lines(p, data = dc, x = ~year, y = ~index, name = cc,
                       line = list(width = 2),
                       hovertemplate = paste0(cc, ": %{y:.0f}<extra></extra>"))
      }
      p |>
        add_lines(data = mci[order(year)], x = ~year, y = ~mci, name = "MCI (composite)",
                  line = list(width = 5, color = "black"),
                  hovertemplate = "MCI: %{y:.0f}<extra></extra>") |>
        layout(yaxis = list(title = sprintf("Price index (%d = 100)", by())),
               xaxis = list(title = "", automargin = TRUE),
               legend = list(orientation = "h", y = -0.2, yanchor = "top", font = list(size = 10)),
               margin = list(b = 110, t = 10),
               hovermode = "x unified")
    })

    # ---- Relative importance table ----
    output$summary <- renderReactable({
      s <- component_summary(prices(), weights(), by())
      d <- s[, .(Input = component, `Budget weight` = w,
                 `Price index (now)` = index,
                 `Total rise since base` = cum_pct / 100,
                 `Avg. annual` = cagr / 100)]
      reactable(
        d, defaultSorted = list("Total rise since base" = "desc"),
        columns = list(
          `Budget weight`          = colDef(format = colFormat(percent = TRUE, digits = 1)),
          `Price index (now)`      = colDef(format = colFormat(digits = 0)),
          `Total rise since base`  = colDef(format = colFormat(percent = TRUE, digits = 1)),
          `Avg. annual`            = colDef(format = colFormat(percent = TRUE, digits = 1))
        ),
        striped = TRUE, highlight = TRUE, compact = TRUE, defaultPageSize = 12)
    })

    # ---- Contribution bars for the selected year ----
    sel <- reactive({
      req(input$year)
      as.data.table(snap()$components)[year == input$year][order(-contribution)]
    })
    output$bars_title <- renderText(sprintf("Contribution to the index in %s",
                                            if (is.null(input$year)) "" else input$year))
    output$bars <- renderPlotly({
      d <- sel()
      plot_ly(d, x = ~contribution, y = ~reorder(component, contribution),
              type = "bar", orientation = "h",
              marker = list(color = "#1f4e79"),
              hovertemplate = "%{y}: %{x:.1f} index pts<extra></extra>") |>
        layout(xaxis = list(title = "Index points contributed"),
               yaxis = list(title = ""), margin = list(l = 170))
    })
  })
}
