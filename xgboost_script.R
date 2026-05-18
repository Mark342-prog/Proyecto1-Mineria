#!/usr/bin/env Rscript
# XGBoost modeling script with 3 variants
# - Model 1: sin balancear (default)
# - Model 2: con class weights (scale_pos_weight)
# - Model 3: con class weights + learning rate más bajo

## Config
seed <- 123
set.seed(seed)

## Packages
pkgs <- c("xgboost","caret","pROC","Matrix","data.table","ROSE","haven","methods")
missing <- pkgs[!(pkgs %in% installed.packages()[,"Package"]) ]
if(length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
lapply(pkgs, require, character.only = TRUE)

## Helper: try loading data from multiple locations
load_data_file <- function(name){
  candidates <- c(name,
                  file.path("Datos", name),
                  file.path("data", name))
  for(f in candidates){
    if(file.exists(f)){
      if(grepl("\\.rds$", f, ignore.case = TRUE)) return(readRDS(f))
      if(grepl("\\.sav$", f, ignore.case = TRUE)) return(haven::read_sav(f))
      if(grepl("\\.csv$", f, ignore.case = TRUE)) return(data.table::fread(f))
    }
  }
  stop(sprintf("No se encontró %s en las ubicaciones esperadas.", name))
}

## Load train/test
train <- load_data_file("train_data.rds")
test  <- load_data_file("test_data.rds")

## Ensure data.frames
train <- as.data.frame(train)
test  <- as.data.frame(test)

## Detect target column: prefer 'target' or last column
detect_target <- function(df){
  if("target" %in% names(df)) return("target")
  if("y" %in% names(df)) return("y")
  return(names(df)[ncol(df)])
}

target_col <- detect_target(train)
if(!target_col %in% names(test)) stop("La columna objetivo no está presente en test")

## Convert target to numeric labels
is_factor_target <- is.factor(train[[target_col]]) || is.character(train[[target_col]])
if(is_factor_target){
  y_levels <- unique(as.character(train[[target_col]]))
  train_y <- as.numeric(factor(as.character(train[[target_col]]), levels = y_levels)) - 1
  test_y <- as.numeric(factor(as.character(test[[target_col]]), levels = y_levels)) - 1
  if(any(is.na(test_y))) stop("La columna objetivo en test contiene niveles no presentes en train")
} else {
  train_y <- as.numeric(train[[target_col]])
  test_y <- as.numeric(test[[target_col]])
}

num_class <- length(unique(train_y))
is_multiclass <- num_class > 2
if(is_multiclass){
  cat(sprintf("Objetivo multiclasificación detectado con %d clases.\n", num_class))
}

## Feature matrix: remove target and create sparse matrix
make_matrix <- function(df){
  df2 <- df[ , !(names(df) %in% target_col), drop=FALSE]
  for(n in names(df2)){
    if(is.character(df2[[n]])) df2[[n]] <- as.factor(df2[[n]])
  }
  mm <- model.matrix(~ . -1, data = df2)
  return(Matrix::Matrix(mm, sparse = TRUE))
}

train_x <- make_matrix(train)
test_x  <- make_matrix(test)

if(ncol(train_x) != ncol(test_x)){
  cols <- union(colnames(train_x), colnames(test_x))
  add_cols <- function(mat, cols){
    missing <- setdiff(cols, colnames(mat))
    if(length(missing)){
      m2 <- Matrix::Matrix(0, nrow=nrow(mat), ncol=length(missing))
      colnames(m2) <- missing
      mat <- cbind(mat, m2)
    }
    mat <- mat[, cols, drop = FALSE]
    return(mat)
  }
  train_x <- add_cols(train_x, cols)
  test_x  <- add_cols(test_x, cols)
}

make_dtrain <- function(weights = NULL){
  if(is.null(weights)){
    return(xgb.DMatrix(data = train_x, label = train_y))
  }
  return(xgb.DMatrix(data = train_x, label = train_y, weight = weights))
}

dtest <- xgb.DMatrix(data = test_x, label = test_y)

common_params <- list(
  objective = if(is_multiclass) "multi:softprob" else "binary:logistic",
  eval_metric = if(is_multiclass) "mlogloss" else "auc",
  num_class = if(is_multiclass) num_class else NULL,
  max_depth = 6,
  nthread = max(1, parallel::detectCores()-1)
)
common_params <- common_params[!sapply(common_params, is.null)]

results <- list()

compute_metrics <- function(actual, pred_prob, class_names){
  if(is_multiclass){
    pred_prob <- matrix(pred_prob, ncol = num_class, byrow = TRUE)
    pred_lab <- max.col(pred_prob) - 1
    actual_fac <- factor(actual, levels = 0:(num_class-1), labels = class_names)
    pred_fac <- factor(pred_lab, levels = 0:(num_class-1), labels = class_names)
    cm <- table(actual_fac, pred_fac)

    precision <- recall <- f1_per_class <- numeric(num_class)
    for(i in seq_len(num_class)){
      tp <- cm[i,i]
      fp <- sum(cm[-i, i])
      fn <- sum(cm[i, -i])
      precision[i] <- if((tp+fp)==0) 0 else tp/(tp+fp)
      recall[i] <- if((tp+fn)==0) 0 else tp/(tp+fn)
      f1_per_class[i] <- if((precision[i]+recall[i])==0) 0 else 2*precision[i]*recall[i]/(precision[i]+recall[i])
    }
    auc <- tryCatch({
      pROC::multiclass.auc(actual_fac, pred_prob)
    }, error = function(e) NA)
    return(list(cm = cm,
                auc = as.numeric(auc),
                precision = mean(precision, na.rm = TRUE),
                recall = mean(recall, na.rm = TRUE),
                f1 = mean(f1_per_class, na.rm = TRUE),
                pred_lab = pred_lab,
                pred_prob = pred_prob))
  }
  pred_lab <- ifelse(pred_prob >= 0.5, 1, 0)
  cm <- table(factor(actual, levels=c(0,1)), factor(pred_lab, levels=c(0,1)))
  tp <- sum(pred_lab==1 & actual==1)
  fp <- sum(pred_lab==1 & actual==0)
  fn <- sum(pred_lab==0 & actual==1)
  precision <- if((tp+fp)==0) 0 else tp/(tp+fp)
  recall <- if((tp+fn)==0) 0 else tp/(tp+fn)
  f1 <- if((precision+recall)==0) 0 else 2*precision*recall/(precision+recall)
  auc <- tryCatch({
    rocobj <- pROC::roc(actual, pred_prob, quiet = TRUE)
    as.numeric(rocobj$auc)
  }, error = function(e) NA)
  return(list(cm = cm, auc = auc, precision = precision, recall = recall, f1 = f1, pred_lab = pred_lab, pred_prob = pred_prob))
}

train_and_eval <- function(params, nrounds = 100, model_name = "model", weights = NULL){
  cat(sprintf("Training %s with params: %s\n", model_name, paste(names(params), params, sep='=', collapse=",")))
  dtrain <- if(is.null(weights)) xgb.DMatrix(data = train_x, label = train_y) else xgb.DMatrix(data = train_x, label = train_y, weight = weights)
  bst <- xgb.train(params = params,
                   data = dtrain,
                   nrounds = nrounds,
                   evals = list(train = dtrain, eval = dtest),
                   verbose = 0,
                   early_stopping_rounds = 20)
  pred_prob <- predict(bst, dtest)
  metrics <- compute_metrics(test_y, pred_prob, y_levels)
  metrics$model <- bst
  return(metrics)
}

## MODEL 1: default
params1 <- common_params
res1 <- train_and_eval(params1, nrounds = 100, model_name = "Model 1 - default")
results[["Model1"]] <- res1

## MODEL 2: con class weights
class_counts <- table(train_y)
weight_per_class <- as.numeric(sum(class_counts) / (num_class * class_counts))
names(weight_per_class) <- names(class_counts)
weights <- as.numeric(weight_per_class[as.character(train_y)])
params2 <- common_params
res2 <- train_and_eval(params2, nrounds = 100, model_name = "Model 2 - class weights", weights = weights)
results[["Model2"]] <- res2

## MODEL 3: class weights + lower learning rate
params3 <- modifyList(common_params, list(eta = 0.05))
res3 <- train_and_eval(params3, nrounds = 200, model_name = "Model 3 - class weights + low eta", weights = weights)
results[["Model3"]] <- res3

## Summarize results
summary_df <- data.frame(
  model = c("Model1","Model2","Model3"),
  auc = c(res1$auc, res2$auc, res3$auc),
  f1  = c(res1$f1, res2$f1, res3$f1),
  precision = c(res1$precision, res2$precision, res3$precision),
  recall = c(res1$recall, res2$recall, res3$recall),
  stringsAsFactors = FALSE
)

print(summary_df)

## Save confusion matrices and models
out_dir <- "xgboost_results"
if(!dir.exists(out_dir)) dir.create(out_dir)
write.csv(summary_df, file = file.path(out_dir, "metrics_summary.csv"), row.names = FALSE)

saveRDS(res1$model, file = file.path(out_dir, "model1_xgboost.rds"))
saveRDS(res2$model, file = file.path(out_dir, "model2_xgboost.rds"))
saveRDS(res3$model, file = file.path(out_dir, "model3_xgboost.rds"))

saveRDS(list(cm = res1$cm, auc = res1$auc, f1 = res1$f1), file = file.path(out_dir, "model1_metrics.rds"))
saveRDS(list(cm = res2$cm, auc = res2$auc, f1 = res2$f1), file = file.path(out_dir, "model2_metrics.rds"))
saveRDS(list(cm = res3$cm, auc = res3$auc, f1 = res3$f1), file = file.path(out_dir, "model3_metrics.rds"))

cat(sprintf("Resultados guardados en %s\n", out_dir))

## Report best model by F1
best_idx <- which.max(summary_df$f1)
cat(sprintf("Mejor modelo por F1: %s (F1=%.4f, AUC=%.4f)\n", summary_df$model[best_idx], summary_df$f1[best_idx], summary_df$auc[best_idx]))

## Save summary RDS
saveRDS(list(summary = summary_df, results = results), file = file.path(out_dir, "all_results.rds"))

## End
