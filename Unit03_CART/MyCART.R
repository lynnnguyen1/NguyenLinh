#CLAUDE>> Lines tagged "#CLAUDE>>" were written by Claude (an AI); lines tagged
#CLAUDE>> "#DAN>>" were written by Dan. These are learning suggestions only.
## to explore abalone dataset
library(ggplot2)
library(dplyr)
library(rpart)
library(rpart.plot)
# install.packages("randomForest")
library(randomForest)
# install.packages("ipred")
library(ipred)
# install.packages("adabag")
library(adabag) # boosting package
# install.packages("xgboost")
library(xgboost)

# DAN>> Reading all these in now means functions from earlier packages can be
# DAN>> masked by functions from later packages. Use the :: opreator to prevent that.

abalone <- read.csv("abalone_data.csv")

# add colnames for it
colnames(abalone) <- c("sex","length","diameter","height","whole_weight","shucked_weight","viscera_weight","shell_weight","rings")
head(abalone)
dim(abalone)

# check NA
sum(is.na(abalone$sex)) # = 0
# check all columns
colSums(is.na(abalone)) # also = 0

# to me all 9 columns are informative though so no column was removed.

# quick histogram plot
abalone_length_plt <- ggplot(abalone,aes(x = length, fill = sex)) +
    geom_histogram(position = "identity",alpha = 0.5,bins = 40) +
    scale_fill_manual(values=c("#3185ed","#d45e0a","#90a291"))+
    theme_bw()
ggsave("abalone_length_plt.png",abalone_length_plt,dpi=300,width=6,height=4)

# remove sex column to check corr of other columns
abalone_nosex <- abalone %>% select(-sex)


# check correlation, pairwise
abalone_corr_pairwise <- cor(abalone_nosex, method = "pearson", use = "pairwise.complete.obs")
round(abalone_corr_pairwise, 2)

# quick heatmap to see
# reshape
abalone_corr_longshape <- as.data.frame(as.table(abalone_corr_pairwise))
colnames(abalone_corr_longshape) <- c("Var1", "Var2", "Correlation")

# DAN>> Very good idea to examine your data first!

# draw
pairwise_heatmap_abalone <- ggplot(abalone_corr_longshape, aes(x = Var1, y = Var2, fill = Correlation)) +
  geom_tile() +
  scale_fill_gradient2(low = "#f5d800", high = "#540ad4", mid = "white",midpoint = 0, name = "Correlation") +
  theme_bw()
ggsave("pairwise_heatmap_abalone.png",pairwise_heatmap_abalone,dpi=300,height=5,width=10)

## day 2 
# split data into test (25%) and validation (75%) sets 
# set the seeds first
set.seed(123)

table(abalone$sex)
#    F    I    M 
# 1307 1342 1527 

# also make it as factor, just in case
abalone$sex <- as.factor(abalone$sex)

# gonna permutate the dataset before train/test splitting (so we'll be fair here)
permutation_abalone <- abalone[sample(x=dim(abalone)[1], size=dim(abalone)[1],replace=FALSE),]
train_set <- permutation_abalone[1:round(0.75*dim(abalone)[1]),]
test_set <- permutation_abalone[(round(0.75*dim(abalone)[1])+1):dim(abalone)[1],]

# just in case
train_set$sex <- factor(train_set$sex, levels = c("F", "I", "M"))
test_set$sex <- factor(test_set$sex, levels = c("F", "I", "M"))

# check dim of new sets
dim(train_set)
dim(test_set)
dim(abalone) # original one

# table(train_set$sex)

#    F    I    M 
#  985 1004 1143

# cart classification  - auto prune
cart_model_sep8 <- rpart(sex~.,data=train_set,method="class")

# plot cart_model_sep8
png("cart_model_sep8_treeviz.png")
rpart.plot(cart_model_sep8,extra=104)
dev.off()

# prediction
cart_model_sep8_predict <- predict(cart_model_sep8,type="class")
table(cart_model_sep8_predict,train_set$sex)

# output
# cart_model_sep8_predict   F   I   M
#                       F 168   4 107
#                       I 205 809 278
#                       M 612 191 758

# error train_set
sum(cart_model_sep8_predict!=train_set$sex)/dim(train_set)[1] 
# output: [1] 0.4460409 ==> accuracy = 44.6%

# full CART
cart_model_sep8_full <- rpart(sex~.,data=train_set,method="class", 
    control=rpart.control(cp=0, minsplit=1))
length(cart_model_sep8_full)

# plot cart_model_sep8 full one
# actually too many branches so it cant be plotted properly
png("cart_model_sep8_treeviz_full.png")
rpart.plot(cart_model_sep8_full,extra=104) 
dev.off()

# check 
cart_model_sep8_full_predict <- predict(cart_model_sep8_full,type="class")
table(cart_model_sep8_full_predict,train_set$sex)

# output       
# cart_model_sep8_full_predict    F    I    M
#                            F  985    0    0
#                            I    0 1004    0
#                            M    0    0 1143

# so this shows that we have the 100% accuracy rate with the full tree 

# we calculated within-sample error rate in day 2

#### sep 10 - cross validation

# now for day 3, we'll do cross validation and check the out-of-sample error rate 

numgp <-10 #number of folds in k-fold cross validation
gp<-rep(1:numgp,length.out=dim(train_set)[1]) # assign groups

err_fullmod<-NA
err_prunemod<- NA

for (currentgroup in 1:numgp)
{
  # full model - train on 9 groups, left 1 group out
  fullmod <-rpart(sex~.,data=train_set[gp!=currentgroup,],method="class",control=rpart.control(cp=0,minsplit=1))
  
  # sort of pruning from rpart
  prunemod <-rpart(sex~.,data=train_set[gp!=currentgroup,],method="class")
  
  #get predictions for the left out group and get error rates
  pred_fullmod <-predict(fullmod,train_set[gp==currentgroup,],type="class")
  pred_prunemod <-predict(prunemod,train_set[gp==currentgroup,],type="class")

  # err rate
  err_fullmod[currentgroup]<-sum(pred_fullmod!=train_set$sex[gp==currentgroup])/sum(gp==currentgroup)
  err_prunemod[currentgroup]<-sum(pred_prunemod!=train_set$sex[gp==currentgroup])/sum(gp==currentgroup)
}
mean(err_fullmod)
mean(err_prunemod) 

# > mean(err_fullmod)
# [1] 0.505125
# > mean(err_prunemod) 
# [1] 0.4693616

## comment - 
# pre-pruned model is cart_model_sep8_predict (or prunemod), whereas full model is cart_model_sep8_full (or fullmod)
# we observed that out-of-sample error rate in full model is higher than that in pruned model

# comparing out-of-sample err and within-sampel err of models 
# for full: 
# out: 0.505125
# within: 0 (no error)

# for pruned model:
# out: 0.4693616
# within: 0.4460409

#CLAUDE>> NOTE: precisely, it is the full MODEL that overfits; within-sample error just cannot detect it.
#CLAUDE>> Day 3's fifth question is still open: is this the same pattern as the breast-cancer data in class?
## Linh's comment:
# So prune model performed worse than full one when it was within sample validation (higher err rate)
# Prune model performs better than full tree for out of sample validation
# => likely overfitting in the within sample validation 

# day 4 - sep15 - pruning

## full model checking
# check the cp of full model 
printcp(cart_model_sep8_full)
# plot cp 
png(file="cp_fullmodel.png")
plotcp(cart_model_sep8_full)
dev.off()

# let me check the pruned model 
# printcp(cart_model_sep8)
# plot cp 
png(file="cp_prunemodel.png")
plotcp(cart_model_sep8)
dev.off()

# choose the good optimal point - 
colnames(cart_model_sep8_full$cptable)
# [1] "CP"        "nsplit"    "rel error" "xerror"    "xstd"
#CLAUDE>> THINK: the lowest-xerror row is not the 1-SE choice. Add that row's xstd to its xerror to get the
#CLAUDE>> threshold, then take the row with the FEWEST splits whose xerror is below it. Which row is that?
# we want to check the xerror => column 4, and whatever row with first lowest xerror value so far

# DAN>> What Claude describes is the convention, and what I taught, so you should try 
# DAN>> to do it, but it is only a convention. One could argue to take the lowest 
# DAN>> CV as well. 

cart_model_sep8_full$cptable[4,4] # note 4
# cart_model_sep8$cptable[3,4] # best one is at node number 3 (so row 3) 

# output
# cart_model_sep8_full$cptable[4,1] 
# [1] 0.005530417
# > cart_model_sep8$cptable[2,1]
# [1] 0.01022289

# Linh's interpretation
# turns out the xerror at the first lowest xerror of full model is smaller than that of the prune model
# => go with full model at node 4,4
# DAN>> I like how you are inserting these interpretations. 

# new full model, with that split at 4,4
cart_model_sep8_full <- rpart(sex~.,data=train_set,method="class", 
    control=rpart.control(cp=0, minsplit=1))

cart_model_sep17_full<-rpart(sex~.,data=train_set,method="class", 
        control=rpart.control(cp=0.005530417,minsplit=1))

# viz the new model after all effort in checking splits
png("cart_model_sep1_full_treeviz.png")
rpart.plot(cart_model_sep17_full, extra = 104)
dev.off()

## then let's check the error rate on the new model manually 
err_newmod<- NA
for (currentgroup in 1:numgp)
{
  # full model - train on 9 groups, left 1 group out
  cart_model_sep17_full_checkerr <-rpart(sex~.,data=train_set[gp!=currentgroup,],method="class",control=rpart.control(cp=0.005530417,minsplit=1))
  
  #get predictions for the left out group and get error rates
  pred_cart_model_sep17_full_checkerr <-predict(cart_model_sep17_full_checkerr,train_set[gp==currentgroup,],type="class")
  # err rate
  err_newmod[currentgroup]<-sum(pred_cart_model_sep17_full_checkerr!=train_set$sex[gp==currentgroup])/sum(gp==currentgroup)
}
mean(err_newmod) 
# 0.4623461

# so we got this output - 
# so our new model with specific cp works better than pruned (and obviously full)
# difference between pruned and new model is 0.4664842 - 0.4447783 = 0.0217059

##### day 5 - bagging
# baggin model to classify sex with out of the bag evaluaiton and bootstrapping 500 bags 
bagging_mod <- ipred::bagging(sex~.,data=train_set,nbagg=500,coob=TRUE,method="class",
  control=rpart.control(cp=0,minsplit=1,xval=0))
# DAN>> Correct use of full trees as the base learners here

# out of bag evaluation for misclassificatin 
print(bagging_mod) # err = 0.4639208

# prediction 
b_pred<-predict(bagging_mod,type="class") 
sum(b_pred!=train_set$sex)/dim(train_set)[1] # 0.4594508

#CLAUDE>> NOTE: good observation. There is no set.seed() before bagging(), so the bootstrap samples (and the
#CLAUDE>> OOB error) change each run. predict(bagging_mod) with no newdata returns the OOB predictions.
## Linh's comment: 
# actually oob and prediction are slightly different 
# also I ran several times and sum b_pred also changed a little bit after each trial 
# DAN>> There are theorems saying the oob and x-val errors are supposed to be the same
# DAN>> in some kind of limit of large amounts of data, and under ideal conditions. 
# DAN>> In practical scenarios, they can differ, as you have observed. When comparing
# DAN>> methods head to head, you should always use the same method for all of them
# DAN>> to assess accuracy, that's why we keep re-doing the x-val.

# cross validation as before
err_bagging<- NA
# also with 10 groups as before 
for (currentgroup in 1:numgp)
{
  # full model - train on 9 groups, left 1 group out
  sub_bag <- ipred::bagging(sex~.,data=train_set[gp!=currentgroup,],nbagg=500,coob=TRUE,method="class",
    control=rpart.control(cp=0,minsplit=1,xval=0))

  #get predictions for the left out group and get error rates
  pred_subbag <- predict(sub_bag,newdata=train_set[gp==currentgroup,],type="class")
  # err rate
  err_bagging[currentgroup]<-sum(pred_subbag!=train_set$sex[gp==currentgroup])/sum(gp==currentgroup)
}
mean(err_bagging) 

# mean(err_bagging) 
# [1] 0.4626615

### Linh's comment
## compare w previous results
# turns out bagging did better than full and pruned but not as well as the hand-selected model (new model)

## random forest

# random forest with 1000 trees
rf_mod <-randomForest::randomForest(sex~.,data=train_set,ntree=1000)

# let's get our oob err 
rf_mod

# here's output of random forest model 
# randomForest(formula = sex ~ ., data = train_set, ntree = 1000) 
#                Type of random forest: classification
#                      Number of trees: 1000
# No. of variables tried at each split: 2

#   OOB estimate of  error rate: 46.1%
# Confusion matrix:
#     F   I   M class.error
# F 378 115 492   0.6162437
# I  88 755 144   0.2350557
# M 413 192 555   0.5215517

## plot that out 
png("rf_model_plt.png")
plot(rf_mod) 
dev.off()

# cross validation as before
err_rf <- NA
# also with 10 groups as before 
for (currentgroup in 1:numgp)
{
  # full model - train on 9 groups, left 1 group out
  sub_rf <- randomForest::randomForest(sex~.,data=train_set[gp!=currentgroup,],ntree=1000)

  #get predictions for the left out group and get error rates
  pred_rf <- predict(sub_rf,newdata=train_set[gp==currentgroup,],type="class")
  # err rate
  err_rf[currentgroup]<-sum(pred_rf!=train_set$sex[gp==currentgroup])/sum(gp==currentgroup)
}
mean(err_rf) 

# > mean(err_rf) 
# [1] 0.4502096

### Linh's comment
## compare w previous results
# turns out random forest did better than bagging but not as well as the hand-selected model (new model)

# give ada boost a try
library(adabag)
#CLAUDE>> THINK: Day 6 asks you to try a few settings and let CV decide, e.g. maxdepth = 1 or 3 here,
#CLAUDE>> or max_depth and learning_rate for xgboost below.
ada_mod <- adabag::boosting(sex~.,data=train_set,control=rpart.control(maxdepth=2))
ada_pred<-predict(ada_mod,train_set[,2:dim(train_set)[2]])$class #note the prediction output gives 
#more detail, including information on certainty
sum(ada_pred!=train_set$sex)/dim(train_set)[1]

# sum(ada_pred!=train_set$sex)/dim(train_set)[1]
# [1] 0.4610473

ada_mod$importance #gives the relative importance of the different variables to only get them for the final model 

#       diameter         height         length          rings   shell_weight 
#      0.0000000      0.1838576      0.0000000      8.2190912      0.0310227 
# shucked_weight viscera_weight   whole_weight 
#      0.1024934     55.9324384     35.5310967

## cross validation on adaptive 
err_ada <- NA
# also with 10 groups as before 
for (currentgroup in 1:numgp)
{
  # full model - train on 9 groups, left 1 group out
  sub_ada <- adabag::boosting(sex~.,data=train_set[gp!=currentgroup,],control=rpart.control(maxdepth=2))

  #get predictions for the left out group and get error rates
  pred_ada <- predict(sub_ada,newdata=train_set[gp==currentgroup,],type="class")$class
  # err rate
  err_ada[currentgroup]<-sum(pred_ada!=train_set$sex[gp==currentgroup])/sum(gp==currentgroup)
}
mean(err_ada) 

#mean(err_ada) 
# [1] 0.4741529

# print("all results so far")
# mean(err_fullmod)
# mean(err_prunemod) 
# mean(err_newmod)
# mean(err_bagging) 
# mean(err_rf) 
# mean(err_ada)

# [1] "all results so far"
# [1] 0.505125
# [1] 0.4693616
# [1] 0.4623461
# [1] 0.4626615
# [1] 0.4502096
# [1] 0.4677622

## Linh's interpretation: so it looks like random forest still out perform adaptive model
## so far it's random forest that the best model 
# last model of the assignment - gradient boosting

# wrap into matrix of xgboost
x_matrix<-as.matrix(train_set[,2:(dim(train_set)[2])])
y_matrix<-as.integer(train_set[,1])-1
dtrain<-xgb.DMatrix(data=x_matrix,label=y_matrix)

m_xgb<-xgb.train(data=dtrain,
           nrounds=500,
           params=list(objective="multi:softprob", # cuz i have 3 classes
                       max_depth=2,
                       eval_metric = "mlogloss",
                       num_class=3, 
                       learning_rate=.05,
                       nthread=2),
           verbose=0)
           
#get error rate on the validation data
pred_xgb<-predict(m_xgb,x_matrix)

cv_predictions <- rep(NA, nrow(x_matrix)) # save a confusion matrix too
err_xgb <- rep(NA, numgp)
for (currentgroup in 1:numgp) {  
  #fit the models on all of the data excluding one group
  dtrain_subset<-xgb.DMatrix(data=x_matrix[gp!=currentgroup,],label=y_matrix[gp!=currentgroup])
  
  # copied the previous one
  m_xgb_s <-xgb.train(data=dtrain_subset,
           nrounds=500,
           params=list(objective="multi:softprob", # cuz i have 3 classes
                       max_depth=2,
                       eval_metric = "mlogloss",
                       num_class=3, 
                       learning_rate=.05,
                       nthread=2),
           verbose=0)
  #get predictions for the left out group and get error rates
  pred_xgb_s<-predict(m_xgb_s,x_matrix[gp==currentgroup,])
  # 3 column matrix to check prob / performance - cant be 0.5 cuz not sure about the balance of variables in the train / test set
  #CLAUDE>> ISSUE: a CV error of 0.660 is chance for 3 classes, and your confusion matrix below is nearly
  #CLAUDE>> uniform. Recent xgboost already returns an n x 3 matrix from predict(), so this reshape scrambles
  #CLAUDE>> it. I may be wrong about your version, but try max.col() on the predict() output directly.
  pred_xgb_s <- matrix(pred_xgb_s, ncol = 3,byrow = TRUE)
  # Select class with highest probability
  predictions_s <- max.col(pred_xgb_s) - 1
  cv_predictions[gp == currentgroup] <- predictions_s
  # err rate
  err_xgb[currentgroup] <- mean(predictions_s != y_matrix[gp == currentgroup])
  }

mean(err_xgb)

# confusion matrix
table(
  Actual = y_matrix,
  Predicted = cv_predictions
)

#         Predicted
# Actual   0   1   2
#      0 328 308 349
#      1 298 336 370
#      2 396 347 400

# get the variable importance of xgboost
importance_matrix<-xgb.importance(model=m_xgb)
importance_matrix

#  Feature            Gain      Cover  Frequency
#            <char>      <num>      <num>      <num>
# 1: viscera_weight 0.38572997 0.17182468 0.15074456
# 2:   whole_weight 0.18149562 0.13150661 0.12439863
# 3:          rings 0.12590225 0.06637282 0.09026346
# 4:         length 0.08210057 0.16566778 0.17273769
# 5:   shell_weight 0.08139277 0.11086795 0.12050401
# 6:         height 0.05831721 0.09971474 0.10011455
# 7: shucked_weight 0.05238929 0.16518519 0.13906071
# 8:       diameter 0.03267232 0.08886023 0.10217640

## okay come back to our all 7 models

print("-----")
print("all err rates of 7 models")
mean(err_fullmod)
mean(err_prunemod) 
mean(err_newmod)
mean(err_bagging) 
mean(err_rf) 
mean(err_ada)
mean(err_xgb)

# [1] "all results so far"
# [1] 0.505125
# [1] 0.4693616
# [1] 0.4623461
# [1] 0.4626615
# [1] 0.4502096
# [1] 0.4677622
# [1] 0.6596508

# so the best model is random forest with lowest err rate

# use random forest on test set 
print("random forest on test set")
#CLAUDE>> GOOD: one model (lowest CV error), fit on all of train_set, scored on the test set once.
#CLAUDE>> That is the Day-7 procedure.
testpred_rf<-predict(rf_mod,test_set[,2:9],type="class")
sum(testpred_rf!=test_set$sex)/dim(test_set)[1]

# reached the error rate of of 0.4281609
