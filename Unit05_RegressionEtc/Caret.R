library(caret)
library(dplyr)
library(ggplot2)
library(tidyr)
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
# but to me it's worse than I expected. Is bagging that bad for this type of cross validation, or I did something wrong here

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
# actually I didnt properly check the code of day 3 so gonna update this
# update: chose icr, pcaNNet and lars2

# let us make a loop
set.seed(678)

# Models to compare
# model_names <- c("pcaNNet","icr","lars2")
# give krlsPoly a try again 
# krlsPoly take a lot of cpus and run time 
model_names <- c("krlsPoly","pcaNNet","lars2")
# tried gamboost but it keeps having problem so switch to glmnet

# tuning parameters
# lars2 - tuning with step
# krlsPoly - lambda, degree
# pcaNNet


# Different tuning effort for each model - go with 5 so it wont take long
tune_lengths <- c(
  # icr = 5,
  krlsPoly=2, # tuning twice for krlsPoly only
  lars2  = 5,
  pcaNNet   = 5 
)

# Store fitted models
model_results <- list()

# tuning control
tc<-trainControl(method="cv",number=5) # cross validation 5 fold

for (model_name in model_names) {
  set.seed(103)

  cat("\nFitting model:", model_name, "\n")
  model_results[[model_name]] <- train(
    log10_range_size ~.,
    data = train_set,
    method = model_name,
    trControl = tc,
    tuneLength = tune_lengths[model_name],
    # preprocess=c("center", "scale"), # preprocess make icr fail - skip it
    metric = "RMSE" # go with RMSE for validation
  )

  print(model_results[[model_name]])
}
# stopCluster(cl)
# registerDoSEQ()


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

# update oct 25
# > restab[order(restab$RMSE),]
#      model      RMSE      RMSESD  Rsquared
# 3    lars2 0.3376186 0.010093306 0.6705192
# 2  pcaNNet 0.3977564 0.005188752 0.6742124
# 1 krlsPoly 0.5388771 0.009460121 0.5580677


# plot report the distribution too 
rs <- resamples(model_results)
summary(rs)$statistics$RMSE
png(file="RangeSizeModelComparison.png")
print(dotplot(rs, metric="RMSE"))
dev.off()

# lars2 is our best model with lowest RMSE (0.34)
# implemental and the part of thoughts on lars2 will be discussed in the writeup


## Tune lars2 with a larger grid and compare it with the original search
set.seed(103)

modelLookup("lars2") 
#  model parameter  label forReg forClass probModel
# 1 lars2      step #Steps   TRUE    FALSE     FALSE

# gonna tune it with step
# pass the tuning grid 
lars2_grid <- expand.grid(step = 1:25) # 25 steps in tuning grid
# the goal of using step in this lars2 tuning is 
# we reach one step with the lowest RMSE and the next one has increased RMSE 


set.seed(103)
lars2_expanded <- train(
  log10_range_size ~ .,
  data = train_set,
  method = "lars2",
  trControl = tc,
  tuneGrid = lars2_grid,
  metric = "RMSE"
)

expanded_best <- lars2_expanded$results[
  which.min(lars2_expanded$results$RMSE),
]
expanded_best
#    step      RMSE  Rsquared       MAE      RMSESD RsquaredSD       MAESD
# 23   23 0.3376186 0.6705192 0.2595465 0.01009331 0.02518374 0.008817409

# also get the plot to check if the lowest RMSE is actually lowest
checkrmse <- ggplot(lars2_expanded$results, aes(x = step, y = RMSE)) +
  geom_line(color = "steelblue", linewidth = 0.8) +
  geom_point(color = "black", alpha = 0.6) +
  labs(x = "Step",y = "RMSE") +
  theme_bw()

ggsave("RMSE_dist_lars2.png",checkrmse, dpi= 300, width= 8, height=5)

# so RMSE are
# before tuning: 0.3376186 +- 0.010
# after tuning: 0.3376186 +- 0.01009331

# hmm so after tuning we have the best RMSE is the same as before tuning, which I did not expect though
# sd also did not improve or anything
# so step 23 is the best scenario we can detect in both before and after tuning
# so for this case, maybe it won't be necessary to put in extra effort 


## Final evaluation on the held-out test set
testpred_lars2 <- predict(lars2_expanded, newdata=test_set)
test_rmse_lars2 <- sqrt(mean((testpred_lars2 - test_set$log10_range_size)^2))
test_r2_lars2 <- 1 - sum((testpred_lars2 - test_set$log10_range_size)^2) / sum(
  (test_set$log10_range_size -mean(test_set$log10_range_size))^2)

test_rmse_lars2
test_r2_lars2

# > test_rmse_lars2
# [1] 0.3430481
# > test_r2_lars2
# [1] 0.6609855

# slightly worse / higher RMSE in test set vs train set 
# We expect such, and happily that RMSE does not get that worse

# Plot predicted against observed values also get the 45 degree line
check_test <- data.frame(observed=test_set$log10_range_size, # our observed
             predicted=testpred_lars2) # our predict range size
test_plot <- ggplot(check_test,aes(x=observed, y=predicted)) +
  geom_point(alpha=0.6) +
  geom_abline(slope=1, intercept=0, color="red", linetype="dashed")+
  labs(x="Observed range size (log10)", y="Predicted range size") +
  theme_bw()
ggsave("test_lars2_plot.png", test_plot,dpi=300, width=6, height=6)


