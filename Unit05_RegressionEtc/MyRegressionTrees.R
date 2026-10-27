# predict log10_2C_genome.size

library(dplyr)
library(ggplot2)
library(tidyr)

# ML packages 
library(rpart)
library(rpart.plot)
library(randomForest)
library(ipred)
# library(adabag) 
# library(xgboost)

# setwd("Unit05_RegressionEtc")

# preprocess the data in preprocessing_data.R
df <- read.csv("Bures24_genome_cleaned.csv") 

nrow(df) # might have to randomize to lower observation number

# main goal: predict log10_2C_genome.size based on other traits / distribution records
# Start our ML training 
# predict the genome size - log10_2C_genome.size
# colnames(df)

# there is a chance that log10_2C_genome.size and log10_mean_chromosome_size colinear, so perhaps remove one
df <- df %>%
  select(-log10_mean_chromosome_size)

# randomize so we have 4500 entries 
set.seed(123)
df <- df[sample(x=dim(df)[1], size=4500,replace=FALSE),]

# save a copy 
# write.csv(df,"data_day1.csv",row.names=FALSE)

# in case we need updated version 
df <- read.csv("data_day1.csv")

# just in case have NA there after numeric 
df <- na.omit(df) 
# > dim(df)
# [1] 4500   21


# 2.1 Split validation and test sets
# The validation set is used to fit and cross-validate the models below.
# The test set is held out and is not used in this exercise.
set.seed(123)

permutation_plant <- df[sample(x=dim(df)[1], size=dim(df)[1],replace=FALSE),]
train_set <- permutation_plant[1:round(0.75*dim(df)[1]),]
test_set <- permutation_plant[(round(0.75*dim(df)[1])+1):dim(df)[1],]

# Check the validation and original dataset sizes without examining test_set.
dim(train_set)
dim(test_set)
dim(df)
# > dim(train_set)
# [1] 3375   21
# > dim(test_set)
# [1] 1125   21
# > dim(df)
# [1] 4500   21

### Regression tree with default algorithmic parameters

# fit rpart with anova for regression w default parameters
m_default <- rpart(log10_2C_genome.size ~ ., data=train_set,method="anova")
m_default

# our tree
pdf(file="regression_tree_default.pdf", width=10, height=8)
rpart.plot(m_default)
dev.off()

# get prediction in oob (based on training set )
default_prediction <- predict(m_default, newdata=train_set)

# RMSE of default model 
default_rmse <- sqrt(mean((default_prediction -train_set$log10_2C_genome.size)^2))
# r squared too 
default_r2 <- 1 - sum((default_prediction -
                       train_set$log10_2C_genome.size)^2) /
  sum((train_set$log10_2C_genome.size -
       mean(train_set$log10_2C_genome.size))^2)

default_rmse
default_r2

# > default_rmse
# [1] 0.4399302 - moderate rmse 
# > default_r2
# [1] 0.2861137 

# Plot predicted against observed values also get the 45 degree line
check_default <- data.frame(observed=train_set$log10_2C_genome.size, # our observed
             predicted=default_prediction) # our predict genome size
validation_plot <- ggplot(check_default,aes(x=observed, y=predicted)) +
  geom_point(alpha=0.6) +
  geom_abline(slope=1, intercept=0, color="red", linetype="dashed")+
  labs(x="Observed genome size (log10)", y="Predicted genome size") +
  theme_bw()
ggsave("validation_plot.png", validation_plot,dpi=300, width=7, height=6)

### Full regression tree
m_full <- rpart(
  log10_2C_genome.size ~ ., data=train_set, method="anova",
  control=rpart.control(cp=0, minsplit=1))

# predict and rmse 
full_prediction <- predict(m_full, newdata=train_set)
full_rmse <- sqrt(mean((full_prediction -
                        train_set$log10_2C_genome.size)^2))
full_rmse
# > full_rmse
# [1] 0.520678
# not as good as the default setting 

# ok let us cross validation - 10 fold 

##### ---- ### 
### Linh's note: I wanna try out the function thing so comment this out 
## let's see how that turns out 

# set.seed(123)
# numgp <- 10 # number of folds in k-fold cross-validation
# gp <- sample(rep(1:numgp, length.out=dim(train_set)[1])) # assign groups

# err_fullmod <- rep(NA_real_, numgp)
# err_defaultmod <- rep(NA_real_, numgp)
# err_lm <- rep(NA_real_, numgp)

# gonna test out default and full models together cuz they will be in same loop either way
# for (currentgroup in 1:numgp) {
#   # default 
#   # Fit each model using the other nine groups.
#   default_fold_model <- rpart(
#     log10_2C_genome.size ~ ., data=train_set[gp != currentgroup,],
#     method="anova"
#   )
#   full_fold_model <- rpart(
#     log10_2C_genome.size ~ ., data=train_set[gp != currentgroup,],
#     method="anova",
#     control=rpart.control(cp=0, minsplit=1)
#   )

#   # Predict the held-out group and calculate its RMSE for each model.
#   pred_defaultmod <- predict(
#     default_fold_model, newdata=train_set[gp == currentgroup,]
#   )
#   pred_fullmod <- predict(
#     full_fold_model, newdata=train_set[gp == currentgroup,]
#   )
#   observed <- train_set$log10_2C_genome.size[gp == currentgroup]

#   err_defaultmod[currentgroup] <- sqrt(mean((pred_defaultmod - observed)^2))
#   err_fullmod[currentgroup] <- sqrt(mean((pred_fullmod - observed)^2))
# }

# Average the held-out-fold RMSEs to compare models.
# cv_rmse_default <- mean(err_defaultmod)
# cv_rmse_full <- mean(err_fullmod)
# cv_rmse_full
# cv_rmse_default
##### ---- ### 

# actually let me try to put cv test into a function 
cv_rmse <- function(data, fit_model, num_folds=10, seed=123) {
  # data = train_set
  # fit_model = get the main model here, and it will be a function 
  set.seed(seed)
  fold_rmse <- rep(NA_real_, num_folds)
  gp <- sample(rep(1:num_folds, length.out=dim(data)[1])) # assign groups

  for (currentgroup in 1:num_folds) {
    model <- fit_model(data[gp != currentgroup, ])
    prediction <- predict(model, newdata=data[gp == currentgroup, ])
    observed <- data[["log10_2C_genome.size"]][gp == currentgroup] 

    fold_rmse[currentgroup] <- sqrt(mean((prediction - observed)^2))
  }

  # get rmse 
  print(mean(fold_rmse))
}

cv_rmse_default <- cv_rmse(
  train_set,
  fit_model=function(d) rpart(log10_2C_genome.size ~ ., data=d, method="anova")
)
# [1] 0.450298 # a little bit higher than just on train set

cv_rmse_full <- cv_rmse(
  train_set,
  fit_model=function(d) {
    rpart(
      log10_2C_genome.size ~ ., data=d, method="anova",
      control=rpart.control(cp=0, minsplit=1)
    )
  }
)
# [1] 0.5206942 # still higher than default model 

## actually this function way looks ok to me 
# gonna continue using this

## improve on single tree
# gonna try random forest with 1000 trees 
rf_mod <-randomForest::randomForest(log10_2C_genome.size~.,data=train_set,ntree=1000,importance=TRUE)

# let's get our oob err 
rf_mod

# Call:
#  randomForest(formula = log10_2C_genome.size ~ ., data = train_set,      ntree = 1000, importance = TRUE) 
#                Type of random forest: regression
#                      Number of trees: 1000
# No. of variables tried at each split: 6

#           Mean of squared residuals: 0.1781325
#                     % Var explained: 34.29

# Linh's obs: actually pretty nice tho with low rmse and more variance explained
pred_rf <- predict(rf_mod,newdata=train_set)
rmse_rf <- sqrt(mean((pred_rf - train_set$log10_2C_genome.size)^2))
r2_rf <- 1 - sum((pred_rf - train_set$log10_2C_genome.size)^2) / sum(
  (train_set$log10_2C_genome.size -mean(train_set$log10_2C_genome.size))^2)

rmse_rf
r2_rf

# 0.1941216
# 0.8610017

# rmse = 0.1941216 which is the best so far for within sample

# cross validation too 
cv_rmse_rf <- cv_rmse(
  train_set,
  # 500 trees to save time
  fit_model=function(d) randomForest::randomForest(log10_range_size~.,data=d,ntree=500,importance=TRUE)
)
cv_rmse_rf 

# worse than the within sample, but not that bad

## plot that out 
png("rf_model_plt.png")
plot(rf_mod) 
dev.off()

# quick observation - might not need that much tree since around 200 trees, we see the very low error rate already

# get the parameter that is the most important in rf_mod
rf_importance <- randomForest::importance(rf_mod, type =1)
rf_importance

#                    %IncMSE
# num_chr2n           90.88943
# log10_range_size    43.49854
# Latitude            35.31224
# Growth_form        134.35461
# log10_occurence     38.07500
# Latitude.x          35.03904
# Longitude           36.35406
# Mean.aridity.index  30.24161
# Mean.BIO1           26.09878
# Mean.BIO3           32.44978
# Mean.BIO7           32.37639
# Mean.BIO12          30.46901
# Mean.BIO15          26.38123
# Mean.BIO19          34.82988
# Mean.GSL            32.53871
# Mean.GST            28.55382
# Mean.NGD5           25.52575
# Mean.UVB1           27.11393
# Mean.UVB3           32.46426
# Mean.UVB5           32.16012

# no surprise with number of chromosome can explain well 
# but actually ddint expect growth form tho


### Multiple linear regression baseline

# Fit the ordinary least-squares baseline on exactly the same training rows
# used for the regression trees.
m_lm <- lm(log10_2C_genome.size ~ ., data=train_set)
lm_prediction <- predict(m_lm, newdata=train_set)
lm_rmse <- sqrt(mean((lm_prediction -
                      train_set$log10_2C_genome.size)^2))
lm_rmse
# [1] 0.4484641 

# CV it
cv_rmse_lm <- cv_rmse(
  train_set,
  fit_model=function(d) lm(log10_2C_genome.size ~ ., data=d)
)
# 0.451169

# a little bit higher RMSE than default, but lower than full tree
# random forest still work best

# my reasoning if linear model works better than fitting other regression is, perhaps parameters have linear relationship already?
# that was also the motivation to remove mean chromosome size when I want to predict genome size too 


## Final evaluation on the held-out test set
# The random forest 
testpred_rf <- predict(rf_mod, newdata=test_set)
test_rmse_rf <- sqrt(mean((testpred_rf - test_set$log10_2C_genome.size)^2))
test_r2_rf <- 1 - sum((testpred_rf - test_set$log10_2C_genome.size)^2) / sum(
  (test_set$log10_2C_genome.size -mean(test_set$log10_2C_genome.size))^2)

test_rmse_rf
test_r2_rf

# > test_rmse_rf
# [1] 0.4399746
# > test_r2_rf
# [1] 0.3270953


# Plot predicted against observed values also get the 45 degree line
check_test <- data.frame(observed=train_set$log10_2C_genome.size, # our observed
             predicted=default_prediction) # our predict genome size
test_plot <- ggplot(check_test,aes(x=observed, y=predicted)) +
  geom_point(alpha=0.6) +
  geom_abline(slope=1, intercept=0, color="red", linetype="dashed")+
  labs(x="Observed genome size (log10)", y="Predicted genome size") +
  theme_bw()
ggsave("test_rf_plot.png", test_plot,dpi=300, width=7, height=6)


### rmse is higher than in the train set, which kinda expected
# but also have kinda good amount of r squared
