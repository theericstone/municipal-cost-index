# mod_map.R — statewide choropleth: each municipality's operating-spending growth
# over the index period vs. the Municipal Cost Index. Boundaries from MassGIS
# (bundled GeoJSON); values from DLS Schedule A (snapshot$munis, all 351).
library(shiny); library(bslib); library(leaflet); library(data.table)

mod_map_ui <- function(id) {
  ns <- NS(id)
  tagList(
    mci_intro("How each community's spending tracked the cost index",
      "This map compares every municipality's total operating-spending growth over the ",
      "index period against the statewide Municipal Cost Index. Communities shaded ",
      strong("red"), " grew spending faster than market costs rose; ", strong("blue"),
      " grew slower — absorbing or deferring cost pressure under the levy cap. Because ",
      "every town is measured against the same cost yardstick, it compares cost management, ",
      "not wealth."),
    card(
      full_screen = TRUE,
      card_header("Spending growth vs. the Municipal Cost Index, by municipality"),
      leafletOutput(ns("map"), height = "640px"),
      card_footer(class = "text-body-secondary small",
        "Source: MA DLS Schedule A general-fund expenditures, all 351 municipalities; ",
        "boundaries from MassGIS. Hover a town for detail.")
    )
  )
}

mod_map_server <- function(id, snap) {
  moduleServer(id, function(input, output, session) {
    geo <- reactive({
      path <- "inst/extdata/ma_towns.geojson"
      shiny::validate(shiny::need(file.exists(path), "Boundary file not found."))
      g <- sf::st_read(path, quiet = TRUE)
      g$key <- toupper(trimws(g$TOWN))
      g$key[g$key == "MANCHESTER-BY-THE-SEA"] <- "MANCHESTER"   # DLS name alias
      g
    })

    output$map <- renderLeaflet({
      m <- snap()$munis
      shiny::validate(shiny::need(!is.null(m) && nrow(as.data.table(m)) > 0,
                    "Municipal spending data not available in this snapshot."))
      m <- as.data.table(m)[, key := toupper(trimws(muni))]
      g <- merge(geo(), m[, .(key, muni, growth_pct, gap_pts)], by = "key", all.x = TRUE)

      rng <- max(abs(g$gap_pts), na.rm = TRUE)
      pal <- colorNumeric("RdBu", domain = c(-rng, rng), reverse = TRUE, na.color = "#eeeeee")
      labels <- sprintf(
        "<b>%s</b><br>Spending growth: %s<br>Gap vs MCI: %s pts",
        ifelse(is.na(g$muni), as.character(g$TOWN), g$muni),
        ifelse(is.na(g$growth_pct), "n/a", sprintf("%+.0f%%", g$growth_pct)),
        ifelse(is.na(g$gap_pts), "n/a", sprintf("%+.1f", g$gap_pts)))

      leaflet(g) |>
        addProviderTiles(providers$CartoDB.Positron) |>
        setView(lng = -71.8, lat = 42.1, zoom = 8) |>
        addPolygons(
          fillColor = pal(g$gap_pts), weight = 0.5, color = "white", fillOpacity = 0.82,
          label = lapply(labels, htmltools::HTML),
          highlightOptions = highlightOptions(weight = 2, color = "#333", bringToFront = TRUE)) |>
        addLegend("bottomright", pal = pal, values = g$gap_pts,
                  title = "Spending vs MCI (pts)", opacity = 0.9)
    })
  })
}
