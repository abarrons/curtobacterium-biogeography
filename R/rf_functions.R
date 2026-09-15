# =============================================================================
# Random Forest helper functions for diversity analysis
# =============================================================================

#' Bootstrapped Confidence Intervals for PDPs with re-fitted models
#'
#' @param data         Data frame containing predictors and response.
#' @param response_var Name of the response variable (character).
#' @param feature_name Name of the predictor to compute PDP for (character).
#' @param n_bootstrap  Number of bootstrap replicates (default 100).
#' @param model_fn     Model-fitting function (default \code{randomForest}).
#'                     Must accept \code{formula} and \code{data} as its first
#'                     two arguments.
#' @param model_args   Named list of additional arguments passed to
#'                     \code{model_fn} (default \code{list(ntree = 1000)}).
#' @param grid.size    Number of evaluation points on the feature grid (default 20).
#' @return A list with \code{summary} (mean + 95% CI per grid point) and
#'         \code{raw} (all bootstrap replicates).
bootstrap_pdp_ci <- function(data,
                             response_var,
                             feature_name,
                             n_bootstrap = 100,
                             model_fn    = randomForest,
                             model_args  = list(ntree = 1000),
                             grid.size   = 20) {

  # Build fixed grid for this feature
  vals <- data[[feature_name]]
  if (is.numeric(vals)) {
    seq_vals <- seq(min(vals, na.rm = TRUE), max(vals, na.rm = TRUE), length.out = grid.size)
  } else {
    seq_vals <- sort(unique(vals))
  }
  grid_points <- setNames(data.frame(seq_vals), feature_name)

  pdp_boot_list <- list()
  pb <- txtProgressBar(min = 0, max = n_bootstrap, style = 3)

  for (i in 1:n_bootstrap) {
    setTxtProgressBar(pb, i)
    data_boot      <- data[sample(1:nrow(data), replace = TRUE), ]
    model_boot     <- do.call(model_fn, c(
      list(formula = as.formula(paste(response_var, "~ .")), data = data_boot),
      model_args
    ))
    X_boot         <- data_boot[, setdiff(names(data_boot), response_var)]
    predictor_boot <- Predictor$new(model_boot, data = X_boot, y = data_boot[[response_var]])
    pdp_boot       <- FeatureEffect$new(predictor_boot,
                                        feature     = feature_name,
                                        method      = "pdp",
                                        grid.points = grid_points)
    pdp_boot_data           <- pdp_boot$results
    pdp_boot_data$replicate <- i
    pdp_boot_list[[i]]      <- pdp_boot_data
  }
  close(pb)

  pdp_all <- bind_rows(pdp_boot_list)

  pdp_summary <- pdp_all %>%
    group_by(!!sym(feature_name)) %>%
    reframe(
      mean_pred = mean(.value),
      ci_lower  = quantile(.value, 0.025),
      ci_upper  = quantile(.value, 0.975)
    )

  return(list(summary = pdp_summary, raw = pdp_all))
}


#' Master Random Forest analysis function
#'
#' Fits a Random Forest, runs A3 permutation-CV test, rfPermute variable
#' importance p-values, bootstrapped PDPs with CIs, and RMSE-based importances.
#'
#' @param df           Data frame.
#' @param response_var Name of the response variable.
#' @param predictors   Character vector of predictor names (NULL = all others).
#' @param ntree        Number of trees (default 1000).
#' @param cv_folds     Number of CV folds for A3 (default 10).
#' @param nperm_oob    Unused placeholder kept for API compatibility.
#' @param nrep_vi      Number of permutation reps for rfPermute and iml (default 500).
#' @param n_boot       Bootstrap replicates for PDPs (default 100).
#' @param grid.size    PDP grid resolution (default 20).
#' @return A named list with model objects, metrics, PDPs, importances, and a
#'         summary table.
run_rf_analysis <- function(df, response_var,
                            predictors = NULL,
                            ntree      = 1000,
                            cv_folds   = 10,
                            nperm_oob  = 500,
                            nrep_vi    = 500,
                            n_boot     = 100,
                            grid.size  = 20) {

  message("[1/7] Subsetting data & removing NAs")
  if (is.null(predictors)) {
    predictors <- setdiff(names(df), response_var)
  }
  dat <- df %>% dplyr::select(all_of(c(response_var, predictors))) %>% na.omit()

  message("[2/7] Fitting RF and computing OOB error")
  set.seed(711)
  rf_full   <- randomForest(as.formula(paste(response_var, "~ .")),
                            data = dat, ntree = ntree, na.action = na.exclude)
  oob_error <- mean(rf_full$mse)
  oob_r2    <- rf_full$rsq[ntree]

  cat("OOB error:", oob_error, "\n")
  cat("R^2:", oob_r2, "\n")

  message("[3/7] Running A3 permutation-CV test")
  fml <- as.formula(paste0(response_var, " ~ . + 0"))
  set.seed(711)
  a3_res <- A3::a3(
    formula    = fml,
    data       = dat,
    model.fn   = randomForest,
    model.args = list(ntree = ntree, na.action = na.exclude),
    n.folds    = cv_folds,
    p.acc      = 0.05
  )

  pval_cv   <- a3_res$model.p
  cv_r2     <- a3_res$model.R2
  feature_p <- a3_res$feature.p
  sig_vars  <- names(feature_p)[feature_p < 0.05]

  cat("Permuted CV p-value:", format.pval(pval_cv, digits = 2), "\n")
  cat("10-fold CV R²:", round(cv_r2, 3), "\n")
  cat("Significant vars (p<0.05):", paste(sig_vars, collapse = ", "), "\n")

  message("[4/7] Running rfPermute (", nrep_vi, " reps)")
  set.seed(711)
  rf_perm       <- rfPermute(as.formula(paste(response_var, "~ .")),
                             data = dat, ntree = ntree, nrep = nrep_vi)
  pmat          <- rf_perm$pval[,, "scaled"]
  sig_vars_rfp  <- rownames(pmat)[pmat[, "%IncMSE"] < 0.05]
  pmat
  cat("Significant variables (p < 0.05):", sig_vars_rfp, "\n")

  message("[5/7] Bootstrapping PDP+CI for all features")
  features_all <- predictors

  pdp_ci_df <- map_dfr(features_all, function(feat) {
    message("  -> PDP for '", feat, "'")
    out <- bootstrap_pdp_ci(dat, response_var, feat,
                            n_bootstrap = n_boot,
                            model_fn    = randomForest,
                            model_args  = list(ntree = ntree),
                            grid.size   = grid.size)$summary
    out %>%
      rename_with(~ "value", .cols = all_of(feat)) %>%
      mutate(feature     = feat,
             significant = feat %in% sig_vars_rfp) %>%
      dplyr::select(feature, significant, value, mean_pred, ci_lower, ci_upper)
  })

  message("[6/7] Performing variable importance on the full model")
  set.seed(711)
  X_full <- dat[, setdiff(names(dat), response_var), drop = FALSE]
  predictor_rf_full <- Predictor$new(
    model = rf_full,
    data  = X_full,
    y     = dat[[response_var]]
  )
  imp_rf_full <- FeatureImp$new(
    predictor_rf_full,
    loss          = "rmse",
    n.repetitions = nrep_vi,
    compare       = "difference"
  )
  imp_results_rf <- imp_rf_full$results
  rug <- X_full

  message("[7/7] Writing summary table")
  summary_table <- tibble::tibble(
    Metric = c(
      "OOB MSE",
      "OOB pseudo-R²",
      paste0(cv_folds, "-fold CV R²"),
      "Permuted CV p-value"
    ),
    Value = c(
      round(oob_error, 6),
      round(oob_r2, 3),
      round(cv_r2, 3),
      format.pval(pval_cv, digits = 2, eps = 1e-3)
    )
  )

  message("Done!")
  return(list(
    rf_full        = rf_full,
    oob_error      = oob_error,
    A3_res         = a3_res,
    rf_perm        = rf_perm,
    sig_vars       = sig_vars,
    sig_vars_rfp   = sig_vars_rfp,
    CV_r2          = cv_r2,
    pval_cv        = pval_cv,
    perm_feat_cv   = feature_p,
    pdp_ci_df      = pdp_ci_df,
    imp_results_rf = imp_results_rf,
    rug            = rug,
    summary_table  = summary_table
  ))
}


#' Master GLM analysis function
#'
#' Fits a GLM, runs k-fold CV, extracts coefficient p-values for significance,
#' bootstraps PDPs with CIs, and computes RMSE-based importances via iml.
#' Returns a list with the same structure as \code{run_rf_analysis} so that
#' \code{generate_plots()} can be used unchanged with either model type.
#'
#' @param df           Data frame.
#' @param response_var Name of the response variable.
#' @param predictors   Character vector of predictor names (NULL = all others).
#' @param family       GLM family object (default \code{gaussian()}).
#' @param cv_folds     Number of CV folds (default 10).
#' @param nrep_vi      Number of permutation reps for iml FeatureImp (default 500).
#' @param n_boot       Bootstrap replicates for PDPs (default 100).
#' @param grid.size    PDP grid resolution (default 20).
#' @return A named list matching \code{run_rf_analysis} output structure.
run_glm_analysis <- function(df, response_var,
                              predictors = NULL,
                              family     = gaussian(),
                              cv_folds   = 10,
                              nrep_vi    = 500,
                              n_boot     = 100,
                              grid.size  = 20) {

  message("[1/6] Subsetting data & removing NAs")
  if (is.null(predictors)) {
    predictors <- setdiff(names(df), response_var)
  }
  dat <- df %>% dplyr::select(all_of(c(response_var, predictors))) %>% na.omit()
  fml <- as.formula(paste(response_var, "~ ."))

  message("[2/6] Fitting GLM")
  set.seed(711)
  glm_full <- glm(fml, data = dat, family = family)
  null_mod <- glm(as.formula(paste(response_var, "~ 1")), data = dat, family = family)

  # Deviance-based pseudo-R² (equivalent to variance explained for gaussian)
  glm_r2  <- 1 - (glm_full$deviance / null_mod$deviance)
  glm_aic <- AIC(glm_full)

  # Overall model significance: F-test for gaussian, LRT otherwise
  if (family$family == "gaussian") {
    ftest    <- anova(null_mod, glm_full, test = "F")
    pval_mod <- ftest$`Pr(>F)`[2]
  } else {
    ftest    <- anova(null_mod, glm_full, test = "Chisq")
    pval_mod <- ftest$`Pr(>Chi)`[2]
  }

  cat("Deviance-based R²:", round(glm_r2, 3), "\n")
  cat("AIC:", round(glm_aic, 2), "\n")
  cat("Overall model p-value:", format.pval(pval_mod, digits = 2), "\n")

  message("[3/6] Running ", cv_folds, "-fold cross-validation")
  set.seed(711)
  folds    <- cut(sample(seq_len(nrow(dat))), breaks = cv_folds, labels = FALSE)
  cv_preds <- numeric(nrow(dat))
  for (k in seq_len(cv_folds)) {
    mod_k              <- glm(fml, data = dat[folds != k, ], family = family)
    cv_preds[folds == k] <- predict(mod_k, newdata = dat[folds == k, ], type = "response")
  }
  ss_res <- sum((dat[[response_var]] - cv_preds)^2)
  ss_tot <- sum((dat[[response_var]] - mean(dat[[response_var]]))^2)
  cv_r2  <- 1 - ss_res / ss_tot

  cat(cv_folds, "-fold CV R²:", round(cv_r2, 3), "\n")

  message("[4/6] Extracting variable significance (coefficient p-values)")
  coef_tab     <- summary(glm_full)$coefficients
  coef_pvals   <- coef_tab[-1, "Pr(>|t|)"]   # drop intercept row
  sig_vars_glm <- names(coef_pvals)[coef_pvals < 0.05]
  cat("Significant vars (p < 0.05):", paste(sig_vars_glm, collapse = ", "), "\n")

  message("[5/6] Bootstrapping PDP+CI for all features")
  pdp_ci_df <- map_dfr(predictors, function(feat) {
    message("  -> PDP for '", feat, "'")
    out <- bootstrap_pdp_ci(dat, response_var, feat,
                            n_bootstrap = n_boot,
                            model_fn    = glm,
                            model_args  = list(family = family),
                            grid.size   = grid.size)$summary
    out %>%
      rename_with(~ "value", .cols = all_of(feat)) %>%
      mutate(feature     = feat,
             significant = feat %in% sig_vars_glm) %>%
      dplyr::select(feature, significant, value, mean_pred, ci_lower, ci_upper)
  })

  message("[6/6] Computing variable importance (iml RMSE)")
  set.seed(711)
  X_full             <- dat[, setdiff(names(dat), response_var), drop = FALSE]
  predictor_glm_full <- Predictor$new(glm_full, data = X_full, y = dat[[response_var]])
  imp_glm_full       <- FeatureImp$new(predictor_glm_full,
                                       loss          = "rmse",
                                       n.repetitions = nrep_vi,
                                       compare       = "difference")

  summary_table <- tibble::tibble(
    Metric = c(
      "Deviance-based R²",
      "AIC",
      paste0(cv_folds, "-fold CV R²"),
      "Overall model p-value (F-test)"
    ),
    Value = c(
      round(glm_r2, 3),
      round(glm_aic, 2),
      round(cv_r2, 3),
      format.pval(pval_mod, digits = 2, eps = 1e-3)
    )
  )

  message("Done!")
  return(list(
    glm_full       = glm_full,
    glm_r2         = glm_r2,
    glm_aic        = glm_aic,
    sig_vars       = sig_vars_glm,
    sig_vars_rfp   = sig_vars_glm,   # alias: expected by generate_plots()
    CV_r2          = cv_r2,
    pval_cv        = pval_mod,
    pdp_ci_df      = pdp_ci_df,
    imp_results_rf = imp_glm_full$results,  # named for generate_plots() compatibility
    rug            = X_full,
    summary_table  = summary_table
  ))
}


#' Generate variable importance and PDP plots from run_rf_analysis output
#'
#' @param imp_results_rf  Importance results data frame from run_rf_analysis.
#' @param pdp_ci_df       PDP+CI data frame from run_rf_analysis.
#' @param rug             Predictor data frame used as rug data.
#' @param clim_vars_PC    Character vector of climate PC predictor names.
#' @param litter_vars     Character vector of litter chemistry predictor names.
#' @param allvars_pallete Named color vector for all variables.
#' @param apatheme        ggplot2 theme object.
#' @param cv_r2           10-fold CV R² value.
#' @param pval_cv         Permuted CV p-value.
#' @param response_label  Label for the y-axis of the PDP plot.
#' @param sig_vars        Character vector of significant variable names.
#' @param clim_vars       Optional extra climate variable names for rug.
#' @param litter_vars_PC  Optional litter PC variable names for rug.
#' @return A list with \code{imp_plot_pdp_rf} and \code{pdp_plot_rf}.
generate_plots <- function(imp_results_rf,
                           pdp_ci_df,
                           rug,
                           clim_vars_PC,
                           litter_vars,
                           allvars_pallete,
                           apatheme,
                           cv_r2,
                           pval_cv,
                           response_label,
                           sig_vars,
                           clim_vars     = NULL,
                           litter_vars_PC = NULL) {

  feature_order <- c("PC1", "PC2", "lignin", "cellulose", "hemicellulose", "crude protein", "pH")

  message("[1/3] Plotting variable importances (RMSE)")
  imp_plot_pdp_rf <- imp_results_rf %>%
    dplyr::filter(feature %in% sig_vars) %>%
    mutate(
      var_type = case_when(
        feature %in% clim_vars_PC  ~ "Climate",
        feature %in% litter_vars   ~ "Litter chemistry",
        TRUE                        ~ "All"
      ),
      feature = dplyr::recode(feature, PC1.clim = "PC1", PC2.clim = "PC2")
    ) %>%
    mutate(feature = gsub("_", " ", feature)) %>%
    mutate(feature = factor(feature, levels = rev(feature_order))) %>%
    ggplot(aes(x = importance, y = feature, color = feature)) +
    scale_color_manual(values = allvars_pallete) +
    facet_grid(var_type ~ ., scales = "free_y", space = "fixed") +
    geom_point(position = position_dodge(width = 0.4), size = 3) +
    geom_errorbarh(aes(xmin = importance.05, xmax = importance.95),
                   position = position_dodge(width = 0.4),
                   height = 0, linewidth = 1.5) +
    scale_x_continuous(labels = percent_format(scale = 100)) +
    labs(x = "Importance (RMSE)",
         tag = bquote(
           atop("10-fold CV " ~ italic(R)^2 == .(round(cv_r2, 3)),
                italic(P) == .(format.pval(pval_cv, 2, eps = 1e-3))))) +
    guides(color = "none") +
    apatheme +
    theme(
      strip.background    = element_rect(fill = NA, colour = "black"),
      strip.text          = element_text(size = 10),
      panel.grid.major.x  = element_line(colour = "grey90"),
      axis.title.y        = element_blank(),
      text                = element_text(size = 10),
      plot.tag            = element_text(face = "italic", size = 10, hjust = 1, vjust = 1),
      plot.tag.position   = c(0.85, 0.98)
    )

  print(imp_plot_pdp_rf)

  message("[2/3] Preparing rug data")
  rug_all_CIs <- reshape2::melt(rug) %>%
    dplyr::rename(feature = variable) %>%
    mutate(
      var_type = case_when(
        feature %in% c(clim_vars_PC, if (!is.null(clim_vars)) clim_vars else character()) ~ "Climate",
        feature %in% c(litter_vars,  if (!is.null(litter_vars_PC)) litter_vars_PC else character()) ~ "Litter chemistry",
        TRUE ~ NA
      ),
      feature = dplyr::recode(feature, PC1.clim = "PC1", PC2.clim = "PC2")
    ) %>%
    mutate(feature = gsub("_", " ", feature)) %>%
    mutate(feature = factor(feature, levels = feature_order))

  message("[3/3] Plotting PDPs + CIs")
  pdp_plot_ci <- pdp_ci_df %>%
    mutate(
      var_type = case_when(
        feature %in% clim_vars_PC ~ "Climate",
        feature %in% litter_vars  ~ "Litter chemistry",
        TRUE                       ~ NA_character_
      ),
      feature = dplyr::recode(feature, PC1.clim = "PC1", PC2.clim = "PC2")
    ) %>%
    mutate(feature = gsub("_", " ", feature)) %>%
    mutate(feature = factor(feature, levels = feature_order)) %>%
    ggplot(aes(x = value, y = mean_pred, color = feature, linetype = significant)) +
    geom_line(size = 1) +
    scale_y_continuous(labels = percent_format(scale = 100)) +
    scale_color_manual(values = allvars_pallete) +
    scale_linetype_manual(
      name   = NULL,
      values = c("TRUE" = "solid", "FALSE" = "longdash"),
      labels = c(expression(P > 0.05), expression(P < 0.05))
    ) +
    geom_rug(data = rug_all_CIs, aes(x = value), sides = "b", inherit.aes = FALSE) +
    ggh4x::facet_nested(~ var_type + feature, scales = "free_x") +
    labs(x = "Variable value", y = paste("Predicted", response_label)) +
    guides(
      color    = "none",
      fill     = "none",
      linetype = guide_legend(order = 1, override.aes = list(size = 1))
    ) +
    apatheme +
    theme(
      axis.title.y      = element_text(size = 10, margin = ggplot2::margin(r = 10)),
      axis.text.y       = element_text(size = 10),
      strip.background  = element_rect(fill = NA, colour = "black"),
      strip.text        = element_text(size = 10),
      panel.grid.major.y = element_line(colour = "grey90"),
      text              = element_text(size = 10),
      legend.position      = c(0.02, 0.98),
      legend.justification = c(0, 1),
      legend.background    = element_rect(fill = alpha("white", 0.7), colour = "black"),
      legend.key.size      = unit(0.3, "cm"),
      legend.text          = element_text(size = 6),
      legend.key.width     = unit(1, "cm"),
      legend.key.height    = unit(0.5, "cm"),
      legend.title         = element_text(size = 8)
    )

  list(
    imp_plot_pdp_rf = imp_plot_pdp_rf,
    pdp_plot_rf     = pdp_plot_ci
  )
}


#' Calculate average richness and Shannon diversity via repeated rarefaction
#'
#' @param otu_table      Matrix or data.frame of counts (rows = samples, cols = OTUs).
#' @param n_iterations   Number of rarefaction iterations (default 100).
#' @param sequence_depth Rarefaction depth (default 1900).
#' @param set_seed       Optional integer seed (default NULL).
#' @return Data frame with columns \code{Richness} and \code{Shannon}.
calc_alpha_diversity <- function(otu_table,
                                 n_iterations   = 100,
                                 sequence_depth = 1900,
                                 set_seed       = NULL) {
  if (!requireNamespace("vegan", quietly = TRUE)) {
    stop("Package 'vegan' is required but not installed.")
  }
  if (!is.null(set_seed)) set.seed(set_seed)

  otu_mat    <- as.matrix(otu_table)
  alpha_list <- vector("list", n_iterations)
  S_list     <- vector("list", n_iterations)

  for (i in seq_len(n_iterations)) {
    cat("Iteration", i, "of", n_iterations, "\n")
    rarified        <- vegan::rrarefy(otu_mat, sample = sequence_depth)
    alpha_list[[i]] <- vegan::diversity(rarified, index = "shannon")
    S_list[[i]]     <- vegan::specnumber(rarified)
    rm(rarified)
  }

  alpha_matrix <- do.call(cbind, alpha_list)
  S_matrix     <- do.call(cbind, S_list)

  data.frame(
    Richness = round(rowMeans(S_matrix)),
    Shannon  = rowMeans(alpha_matrix),
    row.names = rownames(otu_mat)
  )
}
