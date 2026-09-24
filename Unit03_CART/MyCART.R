## to explore abalone dataset
library(ggplot2)
library(dplyr)
library(rpart)
library(rpart.plot)
# install.packages("randomForest")
library(randomForest)
# install.packages("ipred")
library(ipred)
library(adabag) # boosting packagge

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
# [1] 0.5153304
# > mean(err_prunemod) 
# [1] 0.4664842

## comment - 
# pre-pruned model is cart_model_sep8_predict (or prunemod), whereas full model is cart_model_sep8_full (or fullmod)
# we observed that out-of-sample error rate in full model is higher than that in pruned model

# comparing out-of-sample err and within-sampel err of models 
# for full: 
# out: 0.5153304
# within: 0 (no error)

# for pruned model:
# out: 0.4664842
# within: 0.4460409

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
printcp(cart_model_sep8)
# plot cp 
png(file="cp_prunemodel.png")
plotcp(cart_model_sep8)
dev.off()

# choose the good optimal point - 
colnames(cart_model_sep8_full$cptable)
# [1] "CP"        "nsplit"    "rel error" "xerror"    "xstd"
# we want to check the xerror => column 4, and whatever row with first lowest xerror value so far

cart_model_sep8_full$cptable[4,4] # note 4
cart_model_sep8$cptable[3,4] # best one is at node number 3 (so row 3) 

# output
# cart_model_sep8_full$cptable[4,1] 
# [1] 0.005530417
# > cart_model_sep8$cptable[2,1]
# [1] 0.01022289

# Linh's interpretation
# turns out the xerror at the first lowest xerror of full model is smaller than that of the prune model
# => go with full model at node 4,4

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

# so we got this output - 
# mean(err_newmod) 
# [1] 0.4447783
# err of full model err, out sample= 0.5153304
# err of pruned model, out sample=0.4664842
# so our new model with specific cp works better than pruned (and obviously full)
# difference between pruned and new model is 0.4664842 - 0.4447783 = 0.0217059

##### day 5 - bagging
# baggin model to classify sex with out of the bag evaluaiton and bootstrapping 500 bags 
bagging_mod <- ipred::bagging(sex~.,data=train_set,nbagg=500,coob=TRUE,method="class",
  control=rpart.control(cp=0,minsplit=1,xval=0))

# out of bag evaluation for misclassificatin 
print(bagging_mod) # err = 0.4585

# prediction 
b_pred<-predict(bagging_mod,type="class") 
sum(b_pred!=train_set$sex)/dim(train_set)[1] # 0.4594508

## Linh's comment: 
# actually oob and prediction are slightly different 
# also I ran several times and sum b_pred also changed a little bit after each trial 

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
# [1] 0.4629658

### Linh's comment
## compare w previous results
# err of full model err, out sample= 0.5153304
# err of pruned model, out sample=0.4664842
# err of new model, out sample = 0.4447783
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

#         OOB estimate of  error rate: 44.7%
# Confusion matrix:
#     F   I   M class.error
# F 403 119 463   0.5908629
# I  90 766 148   0.2370518
# M 376 204 563   0.5074366

## plot that out 
png("rf_model_plt.png")
plot(rf_mod) 
dev.off()

