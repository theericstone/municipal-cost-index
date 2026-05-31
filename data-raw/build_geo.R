# build_geo.R — one-time: fetch MassGIS municipal boundaries, simplify for web,
# and save as a bundled GeoJSON the map module joins to. Re-run only if boundaries
# change. Run from package root: Rscript data-raw/build_geo.R
suppressMessages({library(sf); library(data.table)})
sf::sf_use_s2(FALSE)   # planar ops avoid s2 topology errors during simplify

url <- paste0("https://services.arcgis.com/2gdL2gxYNFY2TOUb/ArcGIS/rest/services/",
              "Massachusetts_Municipalities_(Feature_Layer)/FeatureServer/0/query",
              "?where=1=1&outFields=TOWN&outSR=4326&f=geojson&resultRecordCount=400")
tf <- tempfile(fileext = ".geojson")
download.file(url, tf, quiet = TRUE, mode = "wb")

g <- st_read(tf, quiet = TRUE)
g <- st_make_valid(g)
g <- st_simplify(g, dTolerance = 0.0004, preserveTopology = TRUE)  # ~45m, web-friendly
g <- g[, "TOWN"]
dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
st_write(g, "inst/extdata/ma_towns.geojson", delete_dsn = TRUE, quiet = TRUE)
cat(sprintf("Wrote inst/extdata/ma_towns.geojson — %d municipalities\n", nrow(g)))
