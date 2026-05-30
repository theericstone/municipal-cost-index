# mod_overview.R — headline index vs the Proposition 2.5% cap.
library(shiny); library(bslib); library(plotly); library(data.table)

mod_overview_ui <- function(id) {
  ns <- NS(id)
  tagList(
    mci_intro("What is the Municipal Cost Index?",
      "The MCI measures how fast the ", strong("price"), " of a fixed ",
      tags$em("basket"), " of the things a municipality must buy — staff pay and ",
      "benefits, ", strong("schools (including special education and student "),
      strong("transportation)"), ", utilities, road and building construction, supplies and ",
      "contracted services — rises over time. It is a ",
      strong("price index, not a spending index"),
      ": it shows what it costs to deliver the ", tags$em("same"), " services each year, ",
      "so a community cannot lower it by cutting services."),
    div(class = "card border-start border-4 border-warning bg-warning-subtle mb-3",
      div(class = "card-body py-2 px-3",
        div(class = "fw-semibold", "The Proposition 2½ squeeze"),
        div(class = "small lh-sm mt-1",
          "Proposition 2½ lets a community's tax levy grow only ", strong("2.5% a year"),
          " (plus “new growth” from new construction). But the cost of delivering the ",
          tags$em("same"), " services — the MCI — has been rising ", strong("faster than 2.5%"),
          ". Every year that gap widens: to merely hold services flat, communities need more ",
          "than the cap allows, so the difference must come from ", strong("overrides"),
          " or from ", strong("cutting services"), ". That is the structural squeeze Warrant ",
          "Article 22 asks the state to weigh.",
          tags$br(), tags$br(),
          "This tool separates two very different things: the cost of ",
          strong("maintaining the status quo"), " (a fixed basket, simply repriced each year) ",
          "from the separate choice to ", strong("expand town or school services"),
          ". The MCI measures only the first — so residents and legislators can see how much ",
          "budget pressure comes from just standing still."))),
    layout_columns(
      fill = FALSE,
      mci_kpi(ns("vb_level"), "Latest index",          "graph-up-arrow",      "primary",   ns("cap_level")),
      mci_kpi(ns("vb_cum"),   "Cumulative cost growth", "cash-stack",          "secondary", ns("cap_cum")),
      mci_kpi(ns("vb_cagr"),  "Avg. annual growth",     "calendar3",           "secondary", ns("cap_cagr")),
      mci_kpi(ns("vb_gap"),   "Gap vs 2.5% cap",        "exclamation-triangle","warning",   ns("cap_gap"))
    ),
    card(
      card_header("Municipal Cost Index vs. the Proposition 2.5% nominal levy cap"),
      plotlyOutput(ns("plot"), height = "460px"),
      card_footer(class = "text-body-secondary small",
        "Blue = measured cost of the basket. Red dashed = the 2.5%/yr the levy cap ",
        "allows. Grey dotted = general CPI for context. The widening gap between blue ",
        "and red is the structural pressure Warrant Article 22 asks the state to weigh.")
    )
  )
}

mod_overview_server <- function(id, snap) {
  moduleServer(id, function(input, output, session) {
    refs <- reactive({
      s   <- snap()
      mci <- as.data.table(s$mci)
      by  <- s$base_year
      mci[, cap := 100 * 1.025 ^ (year - by)]
      ref <- s$reference
      if (!is.null(ref) && nrow(as.data.table(ref))) {
        ref <- as.data.table(ref)
        cb  <- ref[year == by, cpi]
        mci <- merge(mci, ref[, .(year, cpi = 100 * cpi / cb)], by = "year", all.x = TRUE)
      } else {
        mci[, cpi := 100 * 1.028 ^ (year - by)]   # fallback if no CPI series
      }
      mci[order(year)]
    })

    base <- reactive(snap()$base_year)
    last <- reactive(max(refs()$year))

    output$vb_level <- renderText({
      d <- refs(); sprintf("%.1f", d[year == max(year), mci])
    })
    output$cap_level <- renderText(sprintf("%d index  ·  vs. %d (=100)", last(), base()))

    output$vb_cum <- renderText({
      d <- refs(); sprintf("+%.1f%%", d[year == max(year), mci] - 100)
    })
    output$cap_cum <- renderText(sprintf("since %d", base()))

    output$vb_cagr <- renderText({
      d <- refs(); n <- max(d$year) - min(d$year)
      cagr <- (d[year == max(year), mci] / 100) ^ (1 / n) - 1
      sprintf("%.2f%%", 100 * cagr)
    })
    output$cap_cagr <- renderText(sprintf("%d–%d", base(), last()))

    output$vb_gap <- renderText({
      d <- refs()
      sprintf("+%.1f pts", d[year == max(year), mci - cap])
    })
    output$cap_gap <- renderText(sprintf("cumulative vs. 2.5%%/yr since %d", base()))

    output$plot <- renderPlotly({
      d <- refs()
      plot_ly(d, x = ~year) |>
        add_lines(y = ~mci, name = "Municipal Cost Index",
                  line = list(width = 4, color = "#1f4e79")) |>
        add_lines(y = ~cap, name = "Prop 2½ cap (2.5%/yr)",
                  line = list(dash = "dash", color = "#c0392b")) |>
        add_lines(y = ~cpi, name = "CPI (all items)",
                  line = list(dash = "dot", color = "#7f8c8d")) |>
        layout(
          yaxis = list(title = sprintf("Index (%d = 100)", snap()$base_year)),
          xaxis = list(title = ""),
          legend = list(orientation = "h", y = -0.15),
          hovermode = "x unified")
    })
  })
}
