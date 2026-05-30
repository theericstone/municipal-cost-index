# utils_ui.R — small reusable UI helpers (no tidyverse).

#' A muted, plain-language explainer block. Used to thread MCI context through
#' every tab rather than confining it to the Methodology tab.
mci_note <- function(...) {
  div(class = "text-body-secondary small lh-sm", ...)
}

#' A compact "What you're looking at" intro card placed at the top of a tab.
mci_intro <- function(title, ...) {
  div(class = "card border-0 bg-body-tertiary mb-2",
      div(class = "card-body py-2 px-3",
          div(class = "fw-semibold small mb-1", title),
          mci_note(...)))
}

#' Compact KPI box: fixed height, no icon, optional caption line under the value
#' (e.g. the base-year reference). `icon` is accepted but ignored (kept for a
#' stable call signature).
mci_kpi <- function(id_out, title, icon = NULL, theme = "secondary", caption_out = NULL) {
  value_box(
    title = title,
    value = textOutput(id_out),
    if (!is.null(caption_out))
      div(class = "small opacity-75", textOutput(caption_out, inline = TRUE)),
    theme = theme, fill = FALSE, max_height = "118px"
  )
}
