# =============================================================================
# Caching utility
# =============================================================================

#' Cache an expensive expression to an .rds file
#'
#' On the first run the expression is evaluated and the result is written to
#' \code{path}. On subsequent runs the saved file is loaded instead.
#' To force recomputation, delete the \code{.rds} file.
#'
#' Uses non-standard evaluation so the expression is only evaluated when
#' the cache file is absent.
#'
#' @param path  Path to the \code{.rds} file.
#' @param expr  Expression or \code{\{...\}} block to evaluate and cache.
#' @return The cached or freshly computed result.
#'
#' @examples
#' result <- cached("cache/my_model.rds", {
#'   run_rf_analysis(df = mydata, response_var = "y", predictors = c("x1","x2"))
#' })
cached <- function(path, expr) {
  if (file.exists(path)) {
    message("  [cache] Loading: ", path)
    return(readRDS(path))
  }
  message("  [cache] Computing: ", path)
  result <- eval(substitute(expr), envir = parent.frame())
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  saveRDS(result, path)
  message("  [cache] Saved: ", path)
  result
}
