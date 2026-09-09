## to explore abalone dataset
library(ggplot2)
library(dplyr)
library(rpart)
library(rpart.plot)

# sep 3
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

# gonna permutate the dataset before train/test splitting (so we'll be fair here)
permutation_abalone <- abalone[sample(x=dim(abalone)[1], size=dim(abalone)[1],replace=FALSE),]
train_set <- permutation_abalone[1:round(0.75*dim(abalone)[1]),]
test_set <- permutation_abalone[(round(0.75*dim(abalone)[1])+1):dim(abalone)[1],]

# check dim of new sets
dim(train_set)
dim(test_set)
dim(abalone) # original one

# cart classification 
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


