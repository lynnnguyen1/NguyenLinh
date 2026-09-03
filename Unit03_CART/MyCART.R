## to explore abalone dataset
library(ggplot2)
library(dplyr)

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
