library(caret)
library(dplyr)
library(ggplot2)
library(tidyr)
library(e1071)
library(mboost)
library(KRLS)

library(randomForest)
library(rpart)
library(ipred)

# actually it took me a while to find and understand the Bures data on genome size
# so I'm gonna reuse it for day 2 and 3
# also use different seed to and predict different thing, too

# Predict log10_range_size using ecological, life-history, and distribution
# predictors.
df <- read.csv("Bures24_genome_cleaned.csv") 

# df <- read.csv("data_day2.csv")

nrow(df) # might have to randomize to lower observation number

# Inspect the available variables before selecting the response and predictors.
colnames(df)

# randomize so we have 4700 entries 
set.seed(1098) # diff seeds for randomization
df <- df[sample(x=dim(df)[1], size=4700,replace=FALSE),]

# just in case have NA 
df <- na.omit(df) 
# Make factor levels safe for caret model formulas (some Growth_form labels
# contain spaces, which can break the gamboost formula construction).
df$Growth_form <- factor(make.names(as.character(df$Growth_form)))

# save a copy 
write.csv(df,"data_day2.csv",row.names=FALSE)
# > dim(df)
# [1] 4700   22

### split test and train 
set.seed(423)

permutation_plant <- df[sample(x=dim(df)[1], size=dim(df)[1],replace=FALSE),]
train_set <- permutation_plant[1:round(0.75*dim(df)[1]),]
test_set <- permutation_plant[(round(0.75*dim(df)[1])+1):dim(df)[1],]

# Check the validation and original dataset sizes without examining test_set.
dim(train_set)
dim(test_set)
dim(df)

# > dim(train_set)
# [1] 3525   22
# > dim(test_set)
# [1] 1175   22
# > dim(df)
# [1] 4700   22

## function for cross validation 
cv_rmse <- function(data, fit_model, num_folds=10, seed=123) {
  # data = train_set
  # fit_model = get the main model here, and it will be a function 
  # set seed each time, so we can make sure
  set.seed(seed)

  # split group
  fold_rmse <- rep(NA_real_, num_folds)
  gp <- sample(rep(1:num_folds, length.out=dim(data)[1])) # assign groups

  for (currentgroup in 1:num_folds) {
    model <- fit_model(data[gp != currentgroup, ])
    prediction <- predict(model, newdata=data[gp == currentgroup, ])
    observed <- data[["log10_range_size"]][gp == currentgroup] 

    fold_rmse[currentgroup] <- sqrt(mean((prediction - observed)^2))
  }

  # get rmse 
  print(mean(fold_rmse))
}

## Old models
# gonna fitting on random forest and bagging

# random forest
rf_mod <-randomForest::randomForest(log10_range_size~.,data=train_set,ntree=1000,importance=TRUE)
rf_mod

pred_rf <- predict(rf_mod,newdata=train_set)
rmse_rf <- sqrt(mean((pred_rf - train_set$log10_range_size)^2))
r2_rf <- 1 - sum((pred_rf - train_set$log10_range_size)^2) / sum(
  (train_set$log10_range_size -mean(train_set$log10_range_size))^2)

rmse_rf
r2_rf

# > rmse_rf
# [1] 0.08898216
# > r2_rf
# [1] 0.9771248

# bagging
bagging_mod <- ipred::bagging(log10_range_size~.,data=train_set,nbagg=500,coob=TRUE,
  control=rpart.control(cp=0,minsplit=1,xval=0))

# out of bag evaluation for misclassificatin 
print(bagging_mod) # err = 0.5885

# prediction 
b_pred<-predict(bagging_mod) 
rmse_bag <- sqrt(mean((b_pred - train_set$log10_range_size)^2))
r2_bag <- 1 - sum((b_pred - train_set$log10_range_size)^2) / sum(
  (train_set$log10_range_size -mean(train_set$log10_range_size))^2)

rmse_bag
r2_bag

# > rmse_bag
# [1] 0.5884951
# > r2_bag
# [1] -0.0005644457

# Linh's note: random forest out-performed bagging based on RMSE
# just wondering why the R^2 can be negative hmmm 

## cross validation bagging and rf
# bagging
cv_rmse_bagging <- cv_rmse(
  train_set,
  fit_model=function(d) ipred::bagging(log10_range_size~.,data=d,nbagg=500,coob=TRUE,
  control=rpart.control(cp=0,minsplit=1,xval=0))
)
cv_rmse_bagging
# [1] 2.709853 
# ok it's so bad, we kinda expect out of sample will be worse than within sample
# to me it's worse than I expected. Is bagging that bad for this type of cross validation, or I did something wrong here

# rf
cv_rmse_rf <- cv_rmse(
  train_set,
  # 500 trees to save in time
  fit_model=function(d) randomForest::randomForest(log10_range_size~.,data=d,ntree=500,importance=TRUE)
)
cv_rmse_rf 
# [1] 2.778801 - hmmm yeah worse than the within sample but also worse than bagging
# is it possible that random forest have overfitting issue

## New model 
# chose svmLinear2, glmnet, krlsPoly

# # 1. svmLinear2 Linear support vector machine
# fit_svm <- caret::train(
#   log10_range_size ~ .,
#   data = df_model,
#   method = "svmLinear2",
#   trControl = tc,
#   tuneLength = 5,
#   preProcess = c("center", "scale"),
#   metric = "RMSE"
# )

# # 2. glmnet 
# fit_glmnet <- caret::train(
#   log10_range_size ~ .,
#   data = df_model,
#   method = "glmnet",
#   trControl = tc,
#   tuneLength = 5,
#   metric = "RMSE"
# )

# # 3. krlsPoly Polynomial-kernel regularized least squares
# fit_krls <- caret::train(
#   log10_range_size ~ .,
#   data = df_model,
#   method = "krlsPoly",
#   trControl = tc,
#   tuneLength = 2,
#   metric = "RMSE"
# )

# let us make a loop
set.seed(678)

# Models to compare
model_names <- c("pcaNNet","glmnet","svmLinear2")
# tried gamboost but it keeps having problem so switch to glmnet

# tuning parameters
# glmnet - tuning with alpha, lambda
# krlsPoly - lambda, degree
# svmLinear2 - cost
# pcaNNet


# Different tuning effort for each model - go with 5 so it wont take long
tune_lengths <- c(
  svmLinear2 = 5,
  glmnet  = 5,
  pcaNNet   = 5 # will take a long time so just 2
)

# Store fitted models
model_results <- list()

# tuning control
tc<-trainControl(method="cv",number=5) # cross validation 5 fold

# I tried the parallel with 8 cpus 
# and my laptop gets overheating so we just do as usual 

# let us fit - parallel too 
# cat("\n*** parallel\n")
# library(doParallel)
# detectCores()
# cl<-makePSOCKcluster(4)
# registerDoParallel(cl)
# set.seed(103)
for (model_name in model_names) {
  set.seed(103)

  cat("\nFitting model:", model_name, "\n")
  model_results[[model_name]] <- train(
    log10_range_size ~.,
    data = train_set,
    method = model_name,
    trControl = tc,
    tuneLength = tune_lengths[model_name],
    metric = "RMSE" # go with RMSE for validation
  )

  print(model_results[[model_name]])
}
# stopCluster(cl)
# registerDoSEQ()

# Neural Networks with Feature Extraction 

# 3525 samples
#   21 predictor

# No pre-processing
# Resampling: Cross-Validated (5 fold) 
# Summary of sample sizes: 2820, 2819, 2820, 2820, 2821 
# Resampling results across tuning parameters:

#   size  decay  RMSE       Rsquared   MAE      
#   1     0e+00  0.6029590        NaN  0.5131823
#   1     1e-04  0.5673138  0.3167463  0.4781173
#   1     1e-03  0.4350963  0.5582736  0.3498731
#   1     1e-02  0.4184414  0.6089957  0.3367776
#   1     1e-01  0.4206026  0.6039859  0.3398969
#   3     0e+00  0.6029590        NaN  0.5131823
#   3     1e-04  0.4454778  0.5476368  0.3550008
#   3     1e-03  0.4354438  0.5519322  0.3475363
#   3     1e-02  0.4080000  0.6367272  0.3170851
#   3     1e-01  0.4079446  0.6429975  0.3192729
#   5     0e+00  0.6029590        NaN  0.5131823
#   5     1e-04  0.4157603  0.6027446  0.3267345
#   5     1e-03  0.4097543  0.6232330  0.3175138
#   5     1e-02  0.4054061  0.6460943  0.3139199
#   5     1e-01  0.4027596  0.6578957  0.3102641
#   7     0e+00  0.6029590        NaN  0.5131823
#   7     1e-04  0.4455283  0.5492193  0.3536995
#   7     1e-03  0.4209720  0.5973402  0.3291338
#   7     1e-02  0.4014004  0.6488773  0.3079046
#   7     1e-01  0.4010023  0.6615598  0.3090165
#   9     0e+00  0.5635959  0.6191436  0.4740664
#   9     1e-04  0.4621280  0.5054900  0.3661821
#   9     1e-03  0.4172574  0.5908808  0.3241628
#   9     1e-02  0.4028331  0.6465535  0.3101041
#   9     1e-01  0.3977564  0.6742124  0.3053638

# RMSE was used to select the optimal model using the smallest value.
# The final values used for the model were size = 9 and decay = 0.1.

# Fitting model: glmnet 
# glmnet 

# 3525 samples
#   21 predictor

# No pre-processing
# Resampling: Cross-Validated (5 fold) 
# Summary of sample sizes: 2820, 2819, 2820, 2820, 2821 
# Resampling results across tuning parameters:

#   alpha  lambda        RMSE       Rsquared   MAE      
#   0.100  0.0003905022  0.3374897  0.6707763  0.2593084
#   0.100  0.0018125508  0.3375473  0.6706536  0.2594931
#   0.100  0.0084131153  0.3381448  0.6695896  0.2604947
#   0.100  0.0390502222  0.3423258  0.6631807  0.2659409
#   0.100  0.1812550753  0.3618160  0.6462346  0.2888252
#   0.325  0.0003905022  0.3375187  0.6707312  0.2593807
#   0.325  0.0018125508  0.3376508  0.6704597  0.2596260
#   0.325  0.0084131153  0.3393650  0.6673331  0.2616294
#   0.325  0.0390502222  0.3479907  0.6532736  0.2706451
#   0.325  0.1812550753  0.3786900  0.6321570  0.3049831
#   0.550  0.0003905022  0.3374579  0.6708281  0.2593268
#   0.550  0.0018125508  0.3377368  0.6703009  0.2597224
#   0.550  0.0084131153  0.3409840  0.6642836  0.2630482
#   0.550  0.0390502222  0.3517739  0.6472358  0.2737317
#   0.550  0.1812550753  0.3940501  0.6222401  0.3209107
#   0.775  0.0003905022  0.3375569  0.6706554  0.2594555
#   0.775  0.0018125508  0.3378828  0.6700298  0.2598758
#   0.775  0.0084131153  0.3425719  0.6612922  0.2644048
#   0.775  0.0390502222  0.3546272  0.6432497  0.2764941
#   0.775  0.1812550753  0.4113554  0.6091772  0.3389974
#   1.000  0.0003905022  0.3375633  0.6706400  0.2594672
#   1.000  0.0018125508  0.3380861  0.6696491  0.2600813
#   1.000  0.0084131153  0.3441392  0.6583418  0.2657031
#   1.000  0.0390502222  0.3578008  0.6385999  0.2796501
#   1.000  0.1812550753  0.4319493  0.5834954  0.3600227

# RMSE was used to select the optimal model using the smallest value.
# The final values used for the model were alpha = 0.55 and lambda = 0.0003905022.

# Fitting model: svmLinear2 
# Support Vector Machines with Linear Kernel 

# 3525 samples
#   21 predictor

# No pre-processing
# Resampling: Cross-Validated (5 fold) 
# Summary of sample sizes: 2820, 2819, 2820, 2820, 2821 
# Resampling results across tuning parameters:

#   cost  RMSE       Rsquared   MAE      
#   0.25  0.3439801  0.6682049  0.2537624
#   0.50  0.3439794  0.6684044  0.2537580
#   1.00  0.3441298  0.6682976  0.2537875
#   2.00  0.3442296  0.6682653  0.2537976
#   4.00  0.3442226  0.6683187  0.2537305

# RMSE was used to select the optimal model using the smallest value.
# The final value used for the model was cost = 0.5.

# so switch to pcaNNet
# final  value 556.064231 
# stopped after 100 iterations
# Neural Networks with Feature Extraction 

# Fitting model: gamboost 
# Something is wrong; all the RMSE metric values are missing:
#       RMSE        Rsquared        MAE     
#  Min.   : NA   Min.   : NA   Min.   : NA  
#  1st Qu.: NA   1st Qu.: NA   1st Qu.: NA  
#  Median : NA   Median : NA   Median : NA  
#  Mean   :NaN   Mean   :NaN   Mean   :NaN  
#  3rd Qu.: NA   3rd Qu.: NA   3rd Qu.: NA  
#  Max.   : NA   Max.   : NA   Max.   : NA  
#  NAs    :5     NAs    :5     NAs    :5    
# Error: Stopping
# In addition: There were 11 warnings (use warnings() to see them)


restab <- data.frame(model=model_names, RMSE=NA_real_, RMSESD=NA_real_,
                     Rsquared=NA_real_)
for (counter in seq_along(model_names)) {
  thismod <- model_results[[model_names[counter]]]
  bestrow <- which.min(thismod$results$RMSE)
  restab[counter, 2:4] <- thismod$results[
    bestrow, c("RMSE", "RMSESD", "Rsquared")
  ]
}
restab[order(restab$RMSE),]

# plot report the distribution too 

rs <- resamples(model_results)
summary(rs)$statistics$RMSE
pdf(file="RangeSizeModelComparison.pdf", width=6, height=4)
print(dotplot(rs, metric="RMSE"))
dev.off()

# glmnet is our best model with lowest RMSE (0.33)
# actually I'd say it kinda marginally outperformed other models
# implemental and the part of thoughts on glmnet will be discussed in the writeup


## Tune glmnet with a larger grid and compare it with the original search
set.seed(103)
glmnet_folds <- createFolds(
  train_set$log10_range_size,
  k = 5,
  returnTrain = TRUE
)
glmnet_tc <- trainControl(
  method = "cv",
  number = 10 # increase number 
)

# pass the tuning grid 
# play around and add different varaibles for alpha and lambda for tuning
glmnet_grid <- expand.grid(
  alpha = seq(0, 1, by = 0.1),
  lambda = 10^seq(-6, log10(0.2), length.out = 31)
)

set.seed(103)
glmnet_expanded <- train(
  log10_range_size ~ .,
  data = train_set,
  method = "glmnet",
  trControl = glmnet_tc,
  tuneGrid = glmnet_grid,
  metric = "RMSE"
)

expanded_best <- glmnet_expanded$results[
  which.min(glmnet_expanded$results$RMSE),
]
expanded_best
# alpha       lambda      RMSE  Rsquared      MAE     RMSESD RsquaredSD
# 232   0.7 0.0002977241 0.3374582 0.6708279 0.259319 0.01028241 0.02552469
#           MAESD
# 232 0.008968129

# so RMSE are
# before tuning: 0.3374579 +- 0.01
# after tuning: 0.3374582 +- 0.01

# hmm so after tuning we have slightly higher RMSE, which I did not expect though
# sd also did not improve or anything
# so for this case, maybe it won't be necessary to put in extra effort 


## Final evaluation on the held-out test set
# The random forest 
testpred_glmnet <- predict(glmnet_expanded, newdata=test_set)
test_rmse_glmnet <- sqrt(mean((testpred_glmnet - test_set$log10_range_size)^2))
test_r2_glmnet <- 1 - sum((testpred_glmnet - test_set$log10_range_size)^2) / sum(
  (test_set$log10_range_size -mean(test_set$log10_range_size))^2)

test_rmse_glmnet
test_r2_glmnet
# > test_rmse_glmnet
# [1] 0.3430839
# > test_r2_glmnet
# [1] 0.6609148

# Plot predicted against observed values also get the 45 degree line
check_test <- data.frame(observed=train_set$log10_range_size, # our observed
             predicted=testpred_glmnet) # our predict genome size
test_plot <- ggplot(check_test,aes(x=observed, y=predicted)) +
  geom_point(alpha=0.6) +
  geom_abline(slope=1, intercept=0, color="red", linetype="dashed")+
  labs(x="Observed range size (log10)", y="Predicted range size") +
  theme_bw()
ggsave("test_glmnet_plot.png", test_plot,dpi=300, width=7, height=6)
