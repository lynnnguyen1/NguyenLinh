# to explore breast cancer dataset
# setwd(Unit03_CART)
library(ggplot2)
library(dplyr)

# working on breast cancer data
cancer <- read.csv("data.csv")

# sep 3
# checking the data
head(cancer) # take a quick look
dim(cancer) # size 
colnames(cancer)

cancer$diagnosis <- as.factor(cancer$diagnosis)

# check missing values in one column
sum(is.na(cancer$perimeter_mean)) # = 0
# check all columns
colSums(is.na(cancer)) # actually only column "X" has 569 missing values

# histogram plots of some columns 
perimeter_mean_plt <- ggplot(cancer,aes(x = perimeter_mean, fill = diagnosis)) +
    geom_histogram(position = "identity",alpha = 0.5,bins = 30) +
    scale_fill_manual(values=c("#2da22d","#dd378a"))+
    theme_bw()
ggsave("perimeter_mean_plt.png",perimeter_mean_plt,dpi=300,width=6,height=4)

# remove the “id” column, as well as all the standard error columns (columns end with se) and the “worst” columns (end with worst)
cancer2 <- cancer %>%
    select(-id, -X,
    -ends_with("_se"),
    -ends_with("_worst"))

# write that new csv out
write.csv(cancer2,"data_clean.csv",row.names=FALSE)
