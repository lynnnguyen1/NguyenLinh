library(caret)
library(dplyr)
library(ggplot2)
library(tidyr)

library(randomForest)
library(rpart)
library(ipred)

# directory of results
res_loc <- "./results/"

# data to examine
df <- read.csv("data/data_day1.csv")

# examine data 
set.seed(1098)
permutation_plant <- df[sample(x=dim(df)[1], size=dim(df)[1],replace=FALSE),]
train_set <- permutation_plant[1:round(0.75*dim(df)[1]),]
test_set <- permutation_plant[(round(0.75*dim(df)[1])+1):dim(df)[1],]

# run lars2 model to predict genome size from other variables 

set.seed(123)

# tc 
tc<-trainControl(method="cv",number=5) # cross validation 5 fold

# fit 
result_lars2 <- train(
    log10_2C_genome.size ~.,
    data = train_set,
    method = "lars2",
    trControl = tc,
    tuneLength = 5, # tuning 5 times
    metric = "RMSE" # RMSE for validation
    )

# get the dataframe report the result
restab <- data.frame(model="lars2", RMSE=NA_real_, RMSESD=NA_real_,
                     Rsquared=NA_real_)
bestrow <- which.min(result_lars2$results$RMSE)
restab[2:4] <- result_lars2$results[bestrow, c("RMSE", "RMSESD", "Rsquared")]
print("training lars2")
restab
# save RDS 
saveRDS(restab,file=paste0(res_loc,"RMSE_lars2_train"))
# save the macro of the RMSE and R-square 

# write restab to a table and put it in result table
write.csv(restab, file.path(res_loc, "lars2_train.csv"), row.names = FALSE)

## tuning the lars2
# pass the tuning grid 
lars2_grid <- expand.grid(step = 1:25) # 25 steps in tuning grid
# the goal of using step in this lars2 tuning is 
# we reach one step with the lowest RMSE and the next one has increased RMSE 

set.seed(103)
lars2_expanded <- train(
  log10_2C_genome.size ~ .,
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

# save RDS 
saveRDS(expanded_best,file=paste0(res_loc,"RMSE_lars2_tuning"))
# write restab to a table and put it in result table
write.csv(expanded_best, file.path(res_loc, "lars2_tuning_results.csv"), row.names = FALSE)


# also get the plot to check if the lowest RMSE is actually lowest
checkrmse <- ggplot(lars2_expanded$results, aes(x = step, y = RMSE)) +
  geom_line(color = "steelblue", linewidth = 0.8) +
  geom_point(color = "black", alpha = 0.6) +
  labs(x = "Step",y = "RMSE") +
  theme_bw()
ggsave(file.path(res_loc, "RMSE_dist_lars2.pdf"),checkrmse, dpi= 300, width= 8, height=5)

# tuning did not improve the results so let us 
# use the initial lars2 model to predict the test set (result_lars2)
testpred_lars2 <- predict(result_lars2, newdata=test_set)
test_rmse_lars2 <- sqrt(mean((testpred_lars2 - test_set$log10_2C_genome.size)^2))
test_r2_lars2 <- 1 - sum((testpred_lars2 - test_set$log10_2C_genome.size)^2) / sum(
  (test_set$log10_2C_genome.size -mean(test_set$log10_2C_genome.size))^2)

print("print out rmse and R2")
test_rmse_lars2
test_r2_lars2

saveRDS(test_rmse_lars2, file=paste0(res_loc, "test_rmse_lars2.Rds"))
saveRDS(test_r2_lars2, file=paste0(res_loc, "test_r2_lars2.Rds"))

