# fct_fetch_real.R — REAL, key-free data fetchers + snapshot builder.
# Every component maps to a verified public series:
#   - QCEW (BLS)  : actual MA local-government wages           (no key)
#   - CPI / PPI    : BLS public API                            (no key)
#   - NHCCI        : FHWA via Socrata                          (no key)
# Three components use clearly-labelled PROXIES until better statewide price
# series are wired (pensions, SPED tuition, transportation — see PLAN.md / DESE).
#
# Network calls shell out to curl + parse with jsonlite (no extra R deps); CSVs
# use data.table::fread. This runs in the targets pipeline / GitHub Action, never
# in a Shiny session — the app reads the cached snapshot it produces.
library(data.table)

# ---- component -> real source spec ------------------------------------------
# type: qcew | bls (single series) | blsmix (avg of several, each indexed) | nhcci
.real_basket <- function() {
  # weight basis: "Measured (…)" = anchored to real statewide data; else documented estimate.
  list(
    list(component = "Wages & salaries",                    weight = 0.40, type = "qcew",
         source = "BLS QCEW — MA local-government avg weekly wage",
         wbasis = "Measured — US Census (salaries 39.8%)"),
    list(component = "Health & insurance benefits",         weight = 0.12, type = "bls",   id = "CUUR0000SAM",
         source = "BLS CPI — medical care",
         wbasis = "Measured — DLS Fixed Costs (net of pension)"),
    list(component = "Retirement / pensions",               weight = 0.06, type = "qcew",  proxy = TRUE,
         source = "PROXY: tracks local-gov wages (pension cost scales with payroll)",
         wbasis = "Measured — US Census (pension trust 6%)"),
    list(component = "Special education (out-of-district)", weight = 0.05, type = "dese",  which = "sped",
         fallback_id = "CUUR0000SEEB",
         source = "DESE — statewide special-ed expenditure per pupil",
         source_proxy = "PROXY: BLS CPI tuition (DESE file not found)",
         wbasis = "Estimate (overlaps wages*)"),
    list(component = "Student transportation",              weight = 0.03, type = "dese",  which = "transp",
         fallback_id = "CUUR0000SETB01",
         source = "DESE — special-ed in/out-of-district transportation per pupil",
         source_proxy = "PROXY: BLS CPI motor fuel (DESE file not found)",
         wbasis = "Estimate (overlaps wages*)"),
    list(component = "Utilities & energy",                  weight = 0.06, type = "blsmix", ids = c("CUUR0000SEHF01","CUUR0000SEHF02"),
         source = "BLS CPI — electricity + utility (piped) gas",
         wbasis = "Estimate (budget norms)"),
    list(component = "Roads & highway",                     weight = 0.06, type = "nhcci",
         source = "FHWA National Highway Construction Cost Index",
         wbasis = "Estimate (budget norms)"),
    list(component = "Facilities construction",             weight = 0.06, type = "bls",   id = "WPUIP2300001",
         source = "BLS PPI — inputs to new nonresidential construction",
         wbasis = "Estimate (budget norms)"),
    list(component = "Vehicles & equipment",                weight = 0.03, type = "bls",   id = "CUUR0000SETA01",
         source = "BLS CPI — new vehicles",
         wbasis = "Estimate (budget norms)"),
    list(component = "Supplies & materials",                weight = 0.04, type = "bls",   id = "CUUR0000SAC",
         source = "BLS CPI — commodities",
         wbasis = "Estimate (budget norms)"),
    list(component = "Contracted services",                 weight = 0.09, type = "bls",   id = "CUUR0000SAS",
         source = "BLS CPI — services",
         wbasis = "Estimate (budget norms)")
  )
}

# ---- low-level fetchers ------------------------------------------------------

#' BLS public API (no key). Returns data.table(seriesID, year, value=annual mean).
#' Chunks the year span into <=10-year windows (unregistered limit).
.bls_fetch <- function(ids, startyear, endyear) {
  windows <- split(startyear:endyear, ceiling(seq_along(startyear:endyear) / 10))
  out <- list()
  for (w in windows) {
    payload <- list(seriesid = as.list(ids),
                    startyear = as.character(min(w)),
                    endyear   = as.character(max(w)))
    # Optional free BLS key (Sys.getenv) raises the daily cap 25 -> 500; key-free works too.
    if (nzchar(Sys.getenv("BLS_KEY"))) payload$registrationkey <- Sys.getenv("BLS_KEY")
    body <- jsonlite::toJSON(payload, auto_unbox = TRUE)
    bf <- tempfile(fileext = ".json"); writeLines(body, bf)
    tf <- tempfile(fileext = ".json")
    # system2 runs via /bin/sh, so shQuote args containing spaces/JSON
    st <- system2("curl", shQuote(c("-s", "--max-time", "90", "-X", "POST",
                            "https://api.bls.gov/publicAPI/v2/timeseries/data/",
                            "-H", "Content-Type: application/json",
                            "--data-binary", paste0("@", bf), "-o", tf)))
    d <- jsonlite::fromJSON(tf, simplifyVector = FALSE)
    if (!identical(d$status, "REQUEST_SUCCEEDED"))
      stop("BLS request failed: ", paste(unlist(d$message), collapse = "; "))
    for (s in d$Results$series) {
      if (!length(s$data)) next
      dd <- rbindlist(lapply(s$data, function(r)
        data.table(year = as.integer(r$year), period = r$period,
                   value = suppressWarnings(as.numeric(r$value)))))
      dd <- dd[grepl("^M", period) & !is.na(value)]           # monthly obs
      ann <- dd[, .(value = mean(value)), by = year]
      out[[length(out) + 1L]] <- ann[, seriesID := s$seriesID]
    }
  }
  rbindlist(out)
}

#' One BLS series -> long (component, year, level).
.fetch_bls_one <- function(id, label, startyear, endyear) {
  d <- .bls_fetch(id, startyear, endyear)
  d[seriesID == id, .(component = label, year, level = value)][order(year)]
}

#' Average of several BLS series, each indexed to its first common year = 100.
.fetch_bls_mix <- function(ids, label, startyear, endyear) {
  d <- .bls_fetch(ids, startyear, endyear)
  base_y <- d[, .(y = min(year)), by = seriesID][, max(y)]    # first common year
  d <- merge(d, d[year == base_y, .(seriesID, b = value)], by = "seriesID")
  d[, idx := 100 * value / b]
  d[, .(level = mean(idx)), by = year][, component := label][order(year), .(component, year, level)]
}

#' QCEW MA statewide local-government avg weekly wage (own=3, ind=10, agglvl=51).
.fetch_qcew_wage <- function(label, startyear, endyear) {
  rb <- lapply(startyear:endyear, function(y) {
    url <- sprintf("https://data.bls.gov/cew/data/api/%d/a/area/25000.csv", y)
    dt <- tryCatch(fread(url, showProgress = FALSE), error = function(e) NULL)
    if (is.null(dt) || !nrow(dt)) return(NULL)
    r <- dt[own_code == 3 & industry_code == 10 & agglvl_code == 51]
    if (!nrow(r)) return(NULL)
    data.table(component = label, year = y,
               level = as.numeric(r$annual_avg_wkly_wage[1]))
  })
  rbindlist(rb)
}

#' DESE school cost series from the locally-supplied RADAR + per-pupil files
#' (data-raw/). Returns statewide per-pupil SPED and special-ed transportation
#' by fiscal year, or NULL if the files are absent. Files update ~annually and
#' are committed to the repo (the schools-side of the basket).
.dese_school_series <- function() {
  f <- "data-raw/direct-expenditure-trends.xlsx"
  if (!file.exists(f) || !requireNamespace("readxl", quietly = TRUE)) return(NULL)
  num <- function(x) as.numeric(gsub("[$, ]", "", as.character(x)))
  d <- as.data.table(readxl::read_excel(f, sheet = "data", skip = 5))
  setnames(d, make.unique(names(d)))
  fy   <- names(d)[4]
  comb <- grep("Combined Special Ed", names(d), value = TRUE)[1]
  intr <- grep("In-District Transportation", names(d), value = TRUE)[1]
  outr <- grep("Out-of-District Transportation", names(d), value = TRUE)[1]
  d[, FY := suppressWarnings(as.integer(get(fy)))]
  agg <- d[!is.na(FY), .(sped   = sum(num(get(comb)), na.rm = TRUE),
                         transp = sum(num(get(intr)), na.rm = TRUE) +
                                  sum(num(get(outr)), na.rm = TRUE)), by = FY]
  ppfiles <- list.files("data-raw", pattern = "PerPupilExpenditures-[0-9]+\\.xlsx", full.names = TRUE)
  fte <- rbindlist(lapply(ppfiles, function(ff) {
    y <- as.integer(sub(".*-([0-9]+)\\.xlsx", "\\1", ff))
    x <- as.data.table(readxl::read_excel(ff, skip = 1, .name_repair = "minimal"))
    tot <- x[grepl("State Total", x[[1]], ignore.case = TRUE)]
    if (!nrow(tot)) return(NULL)
    data.table(FY = y, fte = num(tot[[7]][1]))
  }))
  if (!nrow(fte)) return(NULL)
  m <- merge(agg, fte, by = "FY")
  m[, .(FY, sped_pp = sped / fte, transp_pp = transp / fte)][order(FY)]
}

#' One DESE component (per-pupil $) -> long (component, year, level).
.fetch_dese <- function(which, label) {
  s <- .dese_school_series()
  if (is.null(s)) return(NULL)
  col <- if (which == "sped") "sped_pp" else "transp_pp"
  s[, .(component = label, year = FY, level = get(col))][order(year)]
}

#' Statewide Proposition 2½ override votes by year (locally-supplied DLS file),
#' split passed/failed. Returns NULL if the file is absent.
.fetch_overrides <- function(min_year = 2015, max_year = 2027) {
  f <- "data-raw/OverrideUnderrideVotes.xlsx"
  if (!file.exists(f) || !requireNamespace("readxl", quietly = TRUE)) return(NULL)
  d <- as.data.table(readxl::read_excel(f))
  setnames(d, make.names(names(d)))
  d <- d[grepl("Override", Vote.Type, ignore.case = TRUE)]
  d[, year := suppressWarnings(as.integer(Fiscal.Year))]
  d <- d[!is.na(year) & year >= min_year & year <= max_year]
  agg <- d[, .(passed = sum(grepl("WIN",  Win...Loss, ignore.case = TRUE)),
               failed = sum(grepl("LOSS", Win...Loss, ignore.case = TRUE))), by = year]
  agg[, total := passed + failed]
  agg[order(year)]
}

#' DLS Schedule A general-fund total expenditures for one fiscal year, all 351
#' municipalities. Lives on dls-gw.dor.state.ma.us (a 302 -> session download),
#' so: browser UA + follow redirects + cookie jar.
.dls_schedule_a <- function(year) {
  if (!requireNamespace("readxl", quietly = TRUE)) return(NULL)
  url <- sprintf(paste0("https://dls-gw.dor.state.ma.us/reports/rdPage.aspx?",
                        "rdReport=ScheduleA.GeneralFund&islAmountType=Expenditures&islYear=%d",
                        "&rdReportFormat=NativeExcel&rdExportTableID=xtGenFund&rdExcelOutputFormat=Excel2007"),
                 year)
  jar <- tempfile(); tf <- tempfile(fileext = ".xlsx")
  ua <- "Mozilla/5.0 AppleWebKit/537.36 Chrome/124 Safari/537.36"
  system2("curl", shQuote(c("-s", "--max-time", "120", "-L", "-c", jar, "-b", jar,
                            "-A", ua, "-o", tf, url)))
  d <- tryCatch(as.data.table(readxl::read_excel(tf)), error = function(e) NULL)
  if (is.null(d) || !nrow(d) || !"Total Expenditures" %in% names(d)) return(NULL)
  d[, .(dor = `DOR Code`, muni = Municipality, total = `Total Expenditures`)]
}

#' Per-municipality operating-spending growth between two fiscal years (all 351).
.fetch_dls_growth <- function(base_year, latest_year) {
  a <- .dls_schedule_a(base_year); b <- .dls_schedule_a(latest_year)
  if (is.null(a) || is.null(b)) return(NULL)
  m <- merge(a[, .(dor, muni, t0 = as.numeric(total))],
             b[, .(dor, t1 = as.numeric(total))], by = "dor")
  m <- m[!is.na(t0) & t0 > 0 & !is.na(t1)]
  m[, .(dor, muni, growth = t1 / t0 - 1)]
}

#' FHWA NHCCI (Socrata, no key) -> annual road construction cost level.
.fetch_nhcci <- function(label) {
  url <- "https://data.transportation.gov/resource/r94d-n4f9.json?$limit=50000"
  d <- as.data.table(jsonlite::fromJSON(url))
  d[, year := as.integer(substr(quarter, 1, 4))]
  d[, .(level = mean(as.numeric(nhcci), na.rm = TRUE)), by = year][
    , component := label][order(year), .(component, year, level)]
}

# ---- assembler --------------------------------------------------------------

#' Build the REAL snapshot the Shiny app consumes (same schema as the sample).
#' @param startyear,endyear fetch window. Series are aligned to their COMMON years.
build_real_snapshot <- function(startyear = 2015, endyear = 2024) {
  basket <- .real_basket()

  # ONE batched BLS request for every BLS-backed series (singles, mixes, and
  # DESE fallbacks) — keeps the whole run to a single BLS call.
  bls_ids <- unique(unlist(lapply(basket, function(b) c(b$id, b$ids, b$fallback_id))))
  bls_ids <- c(bls_ids, "CUUR0000SA0")                 # + headline CPI for the reference line
  bls_ids <- bls_ids[!is.na(bls_ids) & nzchar(bls_ids)]
  bls_all <- if (length(bls_ids)) .bls_fetch(bls_ids, startyear, endyear) else data.table()
  bls_one <- function(id, label) bls_all[seriesID == id, .(component = label, year, level = value)][order(year)]
  bls_mix <- function(ids, label) {
    d <- bls_all[seriesID %in% ids]
    base_y <- d[, .(y = min(year)), by = seriesID][, max(y)]
    d <- merge(d, d[year == base_y, .(seriesID, b = value)], by = "seriesID")
    d[, idx := 100 * value / b]
    d[, .(level = mean(idx)), by = year][, component := label][order(year), .(component, year, level)]
  }

  prices <- list(); srcs <- list()
  for (b in basket) {
    px <- switch(b$type,
      qcew   = .fetch_qcew_wage(b$component, startyear, endyear),
      bls    = bls_one(b$id, b$component),
      blsmix = bls_mix(b$ids, b$component),
      nhcci  = .fetch_nhcci(b$component),
      dese   = .fetch_dese(b$which, b$component))
    used_source <- b$source; used_proxy <- isTRUE(b$proxy)
    # DESE components fall back to a CPI proxy if the supplied files are missing
    if ((is.null(px) || !nrow(px)) && !is.null(b$fallback_id)) {
      px <- bls_one(b$fallback_id, b$component)
      used_source <- b$source_proxy; used_proxy <- TRUE
    }
    if (is.null(px) || !nrow(px)) stop("No data returned for: ", b$component)
    prices[[length(prices) + 1L]] <- px
    srcs[[length(srcs) + 1L]] <- data.table(component = b$component,
                                            source = used_source, proxy = used_proxy,
                                            wbasis = if (is.null(b$wbasis)) "Estimate (budget norms)" else b$wbasis)
  }
  prices <- rbindlist(prices)

  # align to common years across ALL components, then restrict
  common <- Reduce(intersect, split(prices$year, prices$component))
  common <- sort(common)
  prices <- prices[year %in% common]
  base_year <- min(common)

  weights <- rbindlist(lapply(basket, function(b)
    data.table(component = b$component, weight = b$weight)))
  sources <- rbindlist(srcs)

  mci <- compute_mci(prices, weights, base_year)

  # headline CPI (raw level) for the comparison line; re-anchored to the chosen base in the UI
  reference <- bls_all[seriesID == "CUUR0000SA0" & year %in% common, .(year, cpi = value)][order(year)]

  # per-municipality spending growth vs the index growth, full period (for the map)
  latest_y <- max(common)
  mci_growth <- mci[year == latest_y, mci] / 100 - 1
  dls <- .fetch_dls_growth(base_year, latest_y)
  munis <- if (!is.null(dls)) dls[, .(dor, muni,
                                      growth_pct = 100 * growth,
                                      gap_pts = 100 * (growth - mci_growth))] else NULL

  list(
    base_year  = base_year,
    prices     = prices,
    weights    = weights,
    sources    = sources,
    mci        = mci,
    components = mci_components(prices, weights, base_year),
    reference  = reference,
    overrides  = .fetch_overrides(),
    munis      = munis,
    mci_growth_pct = 100 * mci_growth,
    provenance = list(
      kind = paste0("Public price data: BLS QCEW/CPI/PPI, FHWA NHCCI, MA DESE (",
                    min(common), "–", max(common), ")"),
      note = paste0("Basket weights reflect typical Massachusetts municipal budget ",
                    "shares. Pensions use a wage-based proxy series."),
      generated_for = "Massachusetts Municipal Cost Index"
    )
  )
}
